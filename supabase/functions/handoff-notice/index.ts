import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type HandoffMode = "legacy" | "self_recovery";

type HandoffRequest = {
  case_id: string;
  owner_ref: string;
  beneficiary_ref?: string | null;
  mode: HandoffMode;
  trigger_timestamp: string;
  handoff_disclaimer: string;
  audit_reference?: string | null;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const HANDOFF_INTERNAL_KEY = Deno.env.get("HANDOFF_INTERNAL_KEY");
const HANDOFF_PROVIDER_WEBHOOK_URL = Deno.env.get("HANDOFF_PROVIDER_WEBHOOK_URL");
const HANDOFF_SIGNING_SECRET = Deno.env.get("HANDOFF_SIGNING_SECRET");

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function json(status: number, payload: Record<string, unknown>) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

async function hmacSha256Hex(secret: string, data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(data));
  return [...new Uint8Array(signature)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function requireInternalAuth(req: Request): boolean {
  if (!HANDOFF_INTERNAL_KEY) return true;
  const provided = req.headers.get("x-handoff-internal-key")?.trim();
  return Boolean(provided && provided === HANDOFF_INTERNAL_KEY);
}

function validate(payload: Partial<HandoffRequest>): string | null {
  if (!payload.case_id || payload.case_id.trim().length < 8) return "Invalid case_id.";
  if (!payload.owner_ref || !isUuid(payload.owner_ref)) return "Invalid owner_ref.";
  if (!payload.mode || !["legacy", "self_recovery"].includes(payload.mode)) return "Invalid mode.";
  if (!payload.trigger_timestamp || Number.isNaN(Date.parse(payload.trigger_timestamp))) return "Invalid trigger_timestamp.";
  if (!payload.handoff_disclaimer || payload.handoff_disclaimer.trim().length < 10) {
    return "Invalid handoff_disclaimer.";
  }
  return null;
}

async function insertAuditRow(payload: HandoffRequest, deliveryStatus: "queued" | "sent" | "failed" | "skipped", details: {
  httpStatus?: number | null;
  providerRequestId?: string | null;
  responseText?: string | null;
}) {
  const { error } = await supabase.from("partner_handoff_notices").upsert({
    case_id: payload.case_id,
    owner_id: payload.owner_ref,
    beneficiary_ref: payload.beneficiary_ref ?? null,
    mode: payload.mode,
    trigger_timestamp: payload.trigger_timestamp,
    handoff_disclaimer: payload.handoff_disclaimer,
    audit_reference: payload.audit_reference ?? null,
    delivery_status: deliveryStatus,
    delivery_http_status: details.httpStatus ?? null,
    provider_request_id: details.providerRequestId ?? null,
    delivery_response: details.responseText ?? null,
  }, { onConflict: "owner_id,case_id" });
  if (error) throw new Error(`handoff audit upsert failed: ${error.message}`);
}

async function insertTriggerLog(payload: HandoffRequest, status: "sent" | "skipped" | "error", reason: string, metadata: Record<string, unknown>) {
  const { error } = await supabase.from("trigger_logs").insert({
    owner_id: payload.owner_ref,
    mode: payload.mode,
    action: "submit_partner_handoff_notice",
    status,
    reason,
    metadata,
    processed_at: new Date().toISOString(),
  });
  if (error) {
    console.error("trigger_logs insert failed:", error.message);
  }
}

async function notifyProvider(payload: HandoffRequest): Promise<{
  deliveryStatus: "sent" | "failed" | "skipped";
  httpStatus?: number;
  providerRequestId?: string | null;
  responseText?: string;
}> {
  if (!HANDOFF_PROVIDER_WEBHOOK_URL) {
    return { deliveryStatus: "skipped", responseText: "HANDOFF_PROVIDER_WEBHOOK_URL not configured" };
  }

  const body = JSON.stringify(payload);
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (HANDOFF_SIGNING_SECRET) {
    headers["x-handoff-signature-sha256"] = await hmacSha256Hex(HANDOFF_SIGNING_SECRET, body);
  }

  const response = await fetch(HANDOFF_PROVIDER_WEBHOOK_URL, {
    method: "POST",
    headers,
    body,
  });
  const responseText = await response.text();
  const providerRequestId = response.headers.get("x-request-id");
  if (!response.ok) {
    return {
      deliveryStatus: "failed",
      httpStatus: response.status,
      providerRequestId,
      responseText,
    };
  }
  return {
    deliveryStatus: "sent",
    httpStatus: response.status,
    providerRequestId,
    responseText,
  };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") return json(405, { ok: false, error: "Use POST." });
    if (!requireInternalAuth(req)) return json(401, { ok: false, error: "Handoff authorization failed." });

    const payload = await req.json() as Partial<HandoffRequest>;
    const validation = validate(payload);
    if (validation) return json(400, { ok: false, error: validation });
    const accepted = payload as HandoffRequest;

    await insertAuditRow(accepted, "queued", {});
    const result = await notifyProvider(accepted);
    await insertAuditRow(accepted, result.deliveryStatus, {
      httpStatus: result.httpStatus ?? null,
      providerRequestId: result.providerRequestId ?? null,
      responseText: result.responseText ?? null,
    });

    if (result.deliveryStatus === "sent") {
      await insertTriggerLog(accepted, "sent", "partner handoff notice delivered", {
        deliveryStatus: result.deliveryStatus,
        deliveryHttpStatus: result.httpStatus ?? null,
      });
      return json(200, {
        ok: true,
        case_id: accepted.case_id,
        accepted_at: new Date().toISOString(),
        delivery_status: result.deliveryStatus,
      });
    }

    if (result.deliveryStatus === "skipped") {
      await insertTriggerLog(accepted, "skipped", "partner handoff webhook not configured", {
        deliveryStatus: result.deliveryStatus,
      });
      return json(200, {
        ok: true,
        case_id: accepted.case_id,
        accepted_at: new Date().toISOString(),
        delivery_status: result.deliveryStatus,
      });
    }

    await insertTriggerLog(accepted, "error", "partner handoff delivery failed", {
      deliveryStatus: result.deliveryStatus,
      deliveryHttpStatus: result.httpStatus ?? null,
      responseText: result.responseText ?? "",
    });
    return json(502, {
      ok: false,
      case_id: accepted.case_id,
      error: "Partner handoff delivery failed.",
      delivery_status: result.deliveryStatus,
      delivery_http_status: result.httpStatus ?? null,
    });
  } catch (error) {
    return json(400, { ok: false, error: String(error) });
  }
});
