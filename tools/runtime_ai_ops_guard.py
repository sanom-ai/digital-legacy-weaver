from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from urllib import error, parse, request


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_DIR = ROOT / "ops" / "reports"


def _require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing environment variable: {name}")
    return value


def _build_rest_headers(service_role_key: str) -> dict[str, str]:
    headers = {"Content-Type": "application/json", "apikey": service_role_key}
    # Legacy JWT keys require bearer auth. New sb_secret keys do not.
    if service_role_key.startswith("eyJ"):
        headers["Authorization"] = f"Bearer {service_role_key}"
    return headers


def _http_json(
    method: str,
    url: str,
    headers: dict[str, str],
    body: dict[str, Any] | None = None,
    timeout: int = 30,
) -> tuple[int, Any]:
    payload: bytes | None = None
    if body is not None:
        payload = json.dumps(body).encode("utf-8")
    req = request.Request(url=url, method=method, data=payload, headers=headers)
    with request.urlopen(req, timeout=timeout) as resp:
        status_code = resp.getcode()
        raw = resp.read().decode("utf-8", errors="replace").strip()
        if not raw:
            return status_code, {}
        return status_code, json.loads(raw)


def _rest_get_list(
    base_url: str,
    service_role_key: str,
    path_and_query: str,
    degrade_state: dict[str, str | None],
) -> list[dict[str, Any]]:
    url = f"{base_url.rstrip('/')}/rest/v1/{path_and_query}"
    headers = _build_rest_headers(service_role_key)
    try:
        _, payload = _http_json("GET", url, headers=headers)
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        body_lower = body.lower()
        if exc.code in (401, 403) or "forbidden use of secret api key in browser" in body_lower:
            if not degrade_state.get("reason"):
                degrade_state["reason"] = (
                    "Supabase rejected Data API access for security triage. "
                    "AI Ops guard is running in degraded mode."
                )
            return []
        raise RuntimeError(f"GET {url} failed ({exc.code}): {body}") from exc
    except error.URLError as exc:
        raise RuntimeError(f"GET {url} failed: {exc}") from exc

    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        return [payload]
    return []


def _invoke_dispatch_trigger(base_url: str, anon_key: str, timeout: int) -> dict[str, Any]:
    url = f"{base_url.rstrip('/')}/functions/v1/dispatch-trigger"
    headers = {
        "Content-Type": "application/json",
        "apikey": anon_key,
        "Authorization": f"Bearer {anon_key}",
    }
    try:
        status_code, payload = _http_json("POST", url, headers=headers, body={}, timeout=timeout)
        return {"ok": status_code == 200, "status_code": status_code, "payload": payload}
    except error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        parsed: Any
        try:
            parsed = json.loads(body) if body else {}
        except json.JSONDecodeError:
            parsed = {"raw": body}
        return {"ok": False, "status_code": exc.code, "payload": parsed}
    except Exception as exc:  # noqa: BLE001
        return {"ok": False, "status_code": 0, "payload": {"error": str(exc)}}


def _parse_utc(iso_text: str) -> datetime | None:
    if not iso_text:
        return None
    normalized = iso_text.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _compute_metrics(
    events: list[dict[str, Any]],
    heartbeats: list[dict[str, Any]],
    active_blocks: list[dict[str, Any]],
    now_utc: datetime,
    stale_hours: int,
    warn_threshold: int,
    degrade_reason: str | None,
    dispatch_result: dict[str, Any] | None,
) -> tuple[str, list[str], dict[str, Any]]:
    warn_or_critical = [
        event
        for event in events
        if str(event.get("severity", "")).lower() in {"warn", "critical"}
    ]
    critical_events = [
        event for event in events if str(event.get("severity", "")).lower() == "critical"
    ]
    latest_heartbeat = heartbeats[0] if heartbeats else None

    heartbeat_stale = True
    heartbeat_unhealthy = False
    latest_hb_time = None
    if latest_heartbeat:
        latest_hb_time = _parse_utc(str(latest_heartbeat.get("created_at", "")))
        if latest_hb_time:
            heartbeat_stale = (now_utc - latest_hb_time) > timedelta(hours=stale_hours)
        heartbeat_unhealthy = str(latest_heartbeat.get("status", "")).lower() != "ok"

    reasons: list[str] = []
    risk_level = "ok"

    if not latest_heartbeat:
        risk_level = "critical"
        reasons.append("Missing dispatch heartbeat.")
    if heartbeat_stale:
        risk_level = "critical"
        reasons.append(f"Dispatch heartbeat is stale (> {stale_hours}h).")
    if heartbeat_unhealthy:
        risk_level = "critical"
        reasons.append("Latest dispatch heartbeat status is not ok.")
    if critical_events:
        risk_level = "critical"
        reasons.append(f"Critical security events detected: {len(critical_events)}")
    if dispatch_result is not None and not dispatch_result.get("ok", False):
        risk_level = "critical"
        reasons.append(
            "dispatch-trigger invocation failed "
            f"(status={dispatch_result.get('status_code')})."
        )

    if risk_level != "critical":
        if len(warn_or_critical) >= warn_threshold:
            risk_level = "warning"
            reasons.append(
                "Warn/Critical security event volume exceeded threshold "
                f"({len(warn_or_critical)} >= {warn_threshold})."
            )
        if degrade_reason:
            risk_level = "warning"
            reasons.append("Data API degraded mode is active.")

    event_type_counts = dict(Counter(str(event.get("event_type", "unknown")) for event in events))
    severity_counts = dict(Counter(str(event.get("severity", "unknown")) for event in events))
    block_scope_counts = dict(Counter(str(block.get("scope", "unknown")) for block in active_blocks))

    stats = {
        "event_count": len(events),
        "warn_or_critical_count": len(warn_or_critical),
        "critical_count": len(critical_events),
        "active_blocks_count": len(active_blocks),
        "heartbeat_stale": heartbeat_stale,
        "heartbeat_unhealthy": heartbeat_unhealthy,
        "latest_heartbeat": latest_heartbeat,
        "latest_heartbeat_time_utc": latest_hb_time.isoformat() if latest_hb_time else None,
        "event_type_counts": event_type_counts,
        "severity_counts": severity_counts,
        "block_scope_counts": block_scope_counts,
    }
    return risk_level, reasons, stats


def _fallback_ai_summary(risk_level: str, reasons: list[str], stats: dict[str, Any]) -> str:
    lines = [
        f"Risk overview: **{risk_level.upper()}**",
        f"- security events: {stats['event_count']}",
        f"- warn/critical events: {stats['warn_or_critical_count']}",
        f"- active rate-limit blocks: {stats['active_blocks_count']}",
    ]
    if reasons:
        lines.append("- Key reasons:")
        for reason in reasons:
            lines.append(f"  - {reason}")
    lines.append("- Recommendation: verify heartbeat/scheduler first, then inspect latest critical events.")
    return "\n".join(lines)


def _extract_output_text(payload: dict[str, Any]) -> str | None:
    output_text = payload.get("output_text")
    if isinstance(output_text, str) and output_text.strip():
        return output_text.strip()

    chunks: list[str] = []
    for item in payload.get("output", []):
        if not isinstance(item, dict):
            continue
        for content in item.get("content", []):
            if not isinstance(content, dict):
                continue
            text = content.get("text")
            if isinstance(text, str) and text.strip():
                chunks.append(text.strip())
    if chunks:
        return "\n\n".join(chunks)
    return None


def _ai_summary(
    openai_api_key: str | None,
    model: str,
    risk_level: str,
    reasons: list[str],
    stats: dict[str, Any],
    dispatch_result: dict[str, Any] | None,
) -> str:
    if not openai_api_key:
        return _fallback_ai_summary(risk_level, reasons, stats)

    prompt_payload = {
        "risk_level": risk_level,
        "reasons": reasons,
        "stats": stats,
        "dispatch_result": dispatch_result,
    }
    body = {
        "model": model,
        "input": [
            {
                "role": "system",
                "content": [
                    {
                        "type": "text",
                        "text": (
                            "You are an SRE copilot for a private-first digital legacy app. "
                            "Return concise output with three sections: "
                            "1) Current state, 2) Risks, 3) Immediate actions (numbered)."
                        ),
                    }
                ],
            },
            {
                "role": "user",
                "content": [{"type": "text", "text": json.dumps(prompt_payload, ensure_ascii=False)}],
            },
        ],
        "temperature": 0.2,
        "max_output_tokens": 500,
    }
    req = request.Request(
        "https://api.openai.com/v1/responses",
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {openai_api_key}",
        },
        method="POST",
    )
    try:
        with request.urlopen(req, timeout=45) as resp:
            raw = resp.read().decode("utf-8", errors="replace").strip()
            payload = json.loads(raw) if raw else {}
            extracted = _extract_output_text(payload)
            if extracted:
                return extracted
    except Exception as exc:  # noqa: BLE001
        return (
            _fallback_ai_summary(risk_level, reasons, stats)
            + f"\n\nNote: AI API fallback because request failed ({exc})."
        )

    return _fallback_ai_summary(risk_level, reasons, stats)


def _render_report(
    report_time: datetime,
    window_hours: int,
    risk_level: str,
    reasons: list[str],
    stats: dict[str, Any],
    ai_summary: str,
    degrade_reason: str | None,
    dispatch_result: dict[str, Any] | None,
) -> str:
    lines: list[str] = []
    lines.append("# AI Ops Runtime Guard Report")
    lines.append("")
    lines.append(f"- Generated (UTC): {report_time.isoformat()}")
    lines.append(f"- Window: last {window_hours} hour(s)")
    lines.append(f"- Risk level: **{risk_level.upper()}**")
    lines.append(f"- Security events: {stats['event_count']}")
    lines.append(f"- Warn/Critical events: {stats['warn_or_critical_count']}")
    lines.append(f"- Critical events: {stats['critical_count']}")
    lines.append(f"- Active blocks: {stats['active_blocks_count']}")
    lines.append(f"- Heartbeat stale: {stats['heartbeat_stale']}")
    lines.append(f"- Heartbeat unhealthy: {stats['heartbeat_unhealthy']}")
    lines.append("")

    if dispatch_result is not None:
        lines.append("## Dispatch Invocation")
        lines.append(f"- Invoked this run: true")
        lines.append(f"- Status code: {dispatch_result.get('status_code')}")
        lines.append(f"- Success: {dispatch_result.get('ok')}")
        payload = dispatch_result.get("payload", {})
        lines.append(f"- Response: `{json.dumps(payload, ensure_ascii=False)[:500]}`")
        lines.append("")

    if degrade_reason:
        lines.append("## Degraded Mode")
        lines.append(f"- {degrade_reason}")
        lines.append("")

    lines.append("## AI Summary")
    lines.append(ai_summary)
    lines.append("")

    if reasons:
        lines.append("## Triggered Reasons")
        for reason in reasons:
            lines.append(f"- {reason}")
        lines.append("")

    lines.append("## Event Type Counts")
    if stats["event_type_counts"]:
        for event_type, count in sorted(stats["event_type_counts"].items(), key=lambda x: x[1], reverse=True):
            lines.append(f"- {event_type}: {count}")
    else:
        lines.append("- none")
    lines.append("")

    lines.append("## Severity Counts")
    if stats["severity_counts"]:
        for severity, count in sorted(stats["severity_counts"].items(), key=lambda x: x[1], reverse=True):
            lines.append(f"- {severity}: {count}")
    else:
        lines.append("- none")
    lines.append("")

    lines.append("## Block Scope Counts")
    if stats["block_scope_counts"]:
        for scope, count in sorted(stats["block_scope_counts"].items(), key=lambda x: x[1], reverse=True):
            lines.append(f"- {scope}: {count}")
    else:
        lines.append("- none")
    lines.append("")

    lines.append("## Next Actions")
    lines.append("1. If risk is CRITICAL, verify scheduler/dispatch first and pause final release flow if needed.")
    lines.append("2. Review latest critical/warn events and map to incident-response runbook.")
    lines.append("3. Re-check heartbeat freshness after mitigation.")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Runtime AI Ops guard: invoke dispatch trigger, inspect runtime signals, and generate an AI summary report."
    )
    parser.add_argument("--hours", type=int, default=24, help="Lookback window for events.")
    parser.add_argument("--stale-hours", type=int, default=26, help="Heartbeat stale threshold in hours.")
    parser.add_argument(
        "--warn-threshold",
        type=int,
        default=50,
        help="Warn/Critical event threshold for warning risk level.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(DEFAULT_OUTPUT_DIR),
        help="Directory for markdown report output.",
    )
    parser.add_argument("--invoke-dispatch", action="store_true", help="Invoke dispatch-trigger before analysis.")
    parser.add_argument("--dispatch-timeout", type=int, default=30, help="HTTP timeout for dispatch invocation.")
    parser.add_argument("--fail-on-critical", action="store_true", help="Exit non-zero when risk is critical.")
    parser.add_argument("--model", default=os.environ.get("AI_OPS_MODEL", "gpt-4o-mini"))
    args = parser.parse_args()

    base_url = _require_env("SUPABASE_URL")
    service_role_key = _require_env("SUPABASE_SERVICE_ROLE_KEY")
    openai_api_key = os.environ.get("OPENAI_API_KEY", "").strip() or None
    dispatch_result: dict[str, Any] | None = None

    if args.invoke_dispatch:
        anon_key = _require_env("SUPABASE_ANON_KEY")
        dispatch_result = _invoke_dispatch_trigger(
            base_url=base_url,
            anon_key=anon_key,
            timeout=args.dispatch_timeout,
        )

    now_utc = datetime.now(timezone.utc)
    since_iso = (now_utc - timedelta(hours=args.hours)).strftime("%Y-%m-%dT%H:%M:%SZ")
    since_token = parse.quote(since_iso, safe=":-TZ")

    degrade_state: dict[str, str | None] = {"reason": None}
    events = _rest_get_list(
        base_url=base_url,
        service_role_key=service_role_key,
        path_and_query=(
            "security_events?"
            "select=event_type,severity,mode,created_at,details&"
            f"created_at=gte.{since_token}&"
            "order=created_at.desc&limit=1000"
        ),
        degrade_state=degrade_state,
    )
    heartbeats = _rest_get_list(
        base_url=base_url,
        service_role_key=service_role_key,
        path_and_query=(
            "system_heartbeats?"
            "select=source,status,created_at,details&"
            "source=eq.dispatch-trigger&"
            "order=created_at.desc&limit=5"
        ),
        degrade_state=degrade_state,
    )
    active_blocks = _rest_get_list(
        base_url=base_url,
        service_role_key=service_role_key,
        path_and_query=(
            "delivery_access_rate_limits?"
            "select=scope,attempt_count,blocked_until,last_attempt_at&"
            f"blocked_until=gt.{since_token}&"
            "order=blocked_until.desc&limit=200"
        ),
        degrade_state=degrade_state,
    )

    risk_level, reasons, stats = _compute_metrics(
        events=events,
        heartbeats=heartbeats,
        active_blocks=active_blocks,
        now_utc=now_utc,
        stale_hours=args.stale_hours,
        warn_threshold=args.warn_threshold,
        degrade_reason=degrade_state.get("reason"),
        dispatch_result=dispatch_result,
    )

    ai_summary = _ai_summary(
        openai_api_key=openai_api_key,
        model=args.model,
        risk_level=risk_level,
        reasons=reasons,
        stats=stats,
        dispatch_result=dispatch_result,
    )
    report = _render_report(
        report_time=now_utc,
        window_hours=args.hours,
        risk_level=risk_level,
        reasons=reasons,
        stats=stats,
        ai_summary=ai_summary,
        degrade_reason=degrade_state.get("reason"),
        dispatch_result=dispatch_result,
    )

    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = ROOT / output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"ai-ops-runtime-{now_utc.strftime('%Y%m%d-%H%M%S')}.md"
    output_path.write_text(report, encoding="utf-8")

    print(f"[INFO] Risk level: {risk_level.upper()}")
    print(f"[INFO] Report: {output_path}")
    print(f"REPORT_PATH={output_path}")

    if args.fail_on_critical and risk_level == "critical":
        print("[FAIL] Critical runtime risk detected.")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
