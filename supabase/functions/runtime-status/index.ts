import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type RuntimeStatusPayload = {
  window_hours?: number;
};

type ReviewerPrincipal = {
  reviewerRef: string;
  role: "reviewer" | "admin";
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const REVIEWER_API_KEY = Deno.env.get("REVIEWER_API_KEY");

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function resolvePrincipal(req: Request): Promise<ReviewerPrincipal | null> {
  const rawKey = req.headers.get("x-reviewer-key")?.trim();
  if (!rawKey) return null;

  const keyHash = await sha256Hex(rawKey);
  const { data, error } = await supabase
    .from("reviewer_api_keys")
    .select("reviewer_ref, role, is_active, expires_at")
    .eq("key_hash", keyHash)
    .eq("is_active", true)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (data) {
    const expiresAt = data.expires_at
      ? new Date(String(data.expires_at)).getTime()
      : 0;
    if (!expiresAt || expiresAt > Date.now()) {
      return {
        reviewerRef: String(data.reviewer_ref),
        role: String(data.role) === "admin" ? "admin" : "reviewer",
      };
    }
  }

  if (REVIEWER_API_KEY && rawKey === REVIEWER_API_KEY) {
    return { reviewerRef: "legacy-shared-reviewer-key", role: "admin" };
  }
  return null;
}

function normalizedRuntimeHealth(status: string | null): "healthy" | "degraded" | "down" {
  const lower = (status ?? "").trim().toLowerCase();
  if (lower === "ok") return "healthy";
  if (lower === "warn") return "degraded";
  return "down";
}

function pickFailureReason(args: {
  heartbeatStatus: string | null;
  heartbeatDetails: Record<string, unknown>;
  latestErrorEvent: { reason: string | null } | null;
}): string {
  const heartbeatStatus = (args.heartbeatStatus ?? "").toLowerCase();
  const heartbeatReason = String(args.heartbeatDetails["reason"] ?? "").trim();
  const heartbeatError = String(args.heartbeatDetails["error"] ?? "").trim();
  const eventReason = (args.latestErrorEvent?.reason ?? "").trim();

  if (heartbeatStatus === "error" && heartbeatError.length > 0) {
    return heartbeatError;
  }
  if ((heartbeatStatus === "warn" || heartbeatStatus === "error") &&
      heartbeatReason.length > 0) {
    return heartbeatReason;
  }
  if (eventReason.length > 0) {
    return eventReason;
  }
  if (heartbeatStatus === "ok") {
    return "none";
  }
  return "No runtime heartbeat yet";
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return json({ ok: false, error: "Use POST." }, 405);
    }
    const principal = await resolvePrincipal(req);
    if (!principal) {
      return json({ ok: false, error: "Reviewer authorization failed." }, 401);
    }

    const payload = (await req.json()) as RuntimeStatusPayload;
    const windowHours = Math.max(1, Math.min(Number(payload.window_hours ?? 24), 168));
    const sinceIso = new Date(Date.now() - windowHours * 60 * 60 * 1000)
      .toISOString();

    const { data: heartbeat, error: heartbeatError } = await supabase
      .from("system_heartbeats")
      .select("source, status, details, created_at")
      .eq("source", "dispatch-trigger")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (heartbeatError) throw new Error(heartbeatError.message);

    const { data: events, error: eventsError } = await supabase
      .from("trigger_dispatch_events")
      .select("status, stage, mode, reason, created_at")
      .gte("created_at", sinceIso)
      .order("created_at", { ascending: false })
      .limit(500);
    if (eventsError) throw new Error(eventsError.message);

    const eventRows = (events ?? []) as Array<{
      status: string;
      stage: string;
      mode: string;
      reason: string | null;
      created_at: string;
    }>;
    const latestErrorEvent = eventRows.find(
      (event) => String(event.status).toLowerCase() === "error",
    );
    const byStatus = { pending: 0, sent: 0, skipped: 0, error: 0 };
    const byStage = {
      reminder_14d: 0,
      reminder_7d: 0,
      reminder_1d: 0,
      final_release: 0,
    };
    for (const row of eventRows) {
      const status = String(row.status).toLowerCase();
      const stage = String(row.stage).toLowerCase();
      if (status in byStatus) {
        byStatus[status as keyof typeof byStatus] += 1;
      }
      if (stage in byStage) {
        byStage[stage as keyof typeof byStage] += 1;
      }
    }

    const heartbeatDetails = (heartbeat?.details ?? {}) as Record<string, unknown>;
    const heartbeatStatus = (heartbeat?.status as string | null) ?? null;

    return json({
      ok: true,
      generated_at: new Date().toISOString(),
      dispatch_health: normalizedRuntimeHealth(heartbeatStatus),
      heartbeat_status: heartbeatStatus ?? "unknown",
      last_run_at: (heartbeat?.created_at as string | null) ?? null,
      fail_reason: pickFailureReason({
        heartbeatStatus,
        heartbeatDetails,
        latestErrorEvent: latestErrorEvent
          ? { reason: latestErrorEvent.reason }
          : null,
      }),
      stats: {
        window_hours: windowHours,
        total_events: eventRows.length,
        by_status: byStatus,
        by_stage: byStage,
      },
      recent_events: eventRows.slice(0, 8),
      reviewer_ref: principal.reviewerRef,
      reviewer_role: principal.role,
    });
  } catch (error) {
    return json({ ok: false, error: String(error) }, 400);
  }
});
