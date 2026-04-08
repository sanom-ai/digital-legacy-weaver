from datetime import datetime, timezone
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.runtime_ai_ops_guard import _compute_metrics, _fallback_ai_summary


def test_compute_metrics_marks_critical_when_heartbeat_missing() -> None:
    risk, reasons, stats = _compute_metrics(
        events=[],
        heartbeats=[],
        active_blocks=[],
        now_utc=datetime.now(timezone.utc),
        stale_hours=26,
        warn_threshold=50,
        degrade_reason=None,
        dispatch_result=None,
    )
    assert risk == "critical"
    assert any("Missing dispatch heartbeat" in item for item in reasons)
    assert stats["heartbeat_stale"] is True


def test_compute_metrics_marks_warning_on_warn_volume() -> None:
    now = datetime.now(timezone.utc)
    events = [
        {"severity": "warn", "event_type": "rate_limited"},
        {"severity": "warn", "event_type": "invalid_code"},
    ]
    heartbeats = [
        {
            "source": "dispatch-trigger",
            "status": "ok",
            "created_at": now.isoformat().replace("+00:00", "Z"),
        }
    ]
    risk, reasons, _ = _compute_metrics(
        events=events,
        heartbeats=heartbeats,
        active_blocks=[],
        now_utc=now,
        stale_hours=26,
        warn_threshold=2,
        degrade_reason=None,
        dispatch_result=None,
    )
    assert risk == "warning"
    assert any("exceeded threshold" in item for item in reasons)


def test_fallback_summary_includes_risk_and_counts() -> None:
    text = _fallback_ai_summary(
        risk_level="warning",
        reasons=["Example reason"],
        stats={
            "event_count": 5,
            "warn_or_critical_count": 2,
            "critical_count": 0,
            "active_blocks_count": 1,
        },
    )
    assert "WARNING" in text
    assert "security events: 5" in text
    assert "Example reason" in text
