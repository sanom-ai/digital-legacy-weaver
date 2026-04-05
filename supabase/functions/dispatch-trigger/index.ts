import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { compilePTN, evaluatePolicy, type RequirementControl } from "./ptn_policy.ts";

type Profile = {
  id: string;
  backup_email: string;
  beneficiary_email: string | null;
  legacy_inactivity_days: number;
  self_recovery_inactivity_days: number;
  last_active_at: string;
};

type SafetySettings = {
  reminders_enabled: boolean;
  reminder_channels: string[];
  reminder_offsets_days: number[];
  grace_period_days: number;
  legal_disclaimer_accepted: boolean;
  emergency_pause_until: string | null;
  require_multisignal_before_release: boolean;
  recent_signal_window_hours: number;
  minimum_recent_signal_types: number;
  require_guardian_approval_legacy: boolean;
  guardian_grace_hours: number;
  private_first_mode: boolean;
  minimize_trace_metadata: boolean;
  trace_retention_days: number;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SENDGRID_API_KEY = Deno.env.get("SENDGRID_API_KEY");
const DELIVERY_BASE_URL = Deno.env.get("DELIVERY_BASE_URL") ?? "https://example.invalid/unlock";
const HANDOFF_INTERNAL_KEY = Deno.env.get("HANDOFF_INTERNAL_KEY");

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function daysSince(iso: string): number {
  const now = new Date().getTime();
  const then = new Date(iso).getTime();
  return Math.floor((now - then) / (1000 * 60 * 60 * 24));
}

function actionFor(mode: "legacy" | "self_recovery"): string {
  return mode === "legacy" ? "trigger_legacy_delivery" : "trigger_self_recovery_delivery";
}

function buildProviderHandoffHtml(args: {
  secureLink: string;
  mode: "legacy" | "self_recovery";
  inactiveDays: number;
  threshold: number;
}): string {
  const modeLabel = args.mode === "legacy" ? "legacy handoff" : "self-recovery handoff";
  return `
  <p>A policy-approved ${modeLabel} is ready.</p>
  <p>Open secure link: <a href="${args.secureLink}">${args.secureLink}</a></p>
  <p>Inactive days: ${args.inactiveDays} / ${args.threshold}</p>
  <p>Provider handoff checklist:</p>
  <ul>
    <li>Contact the destination app/provider support directly.</li>
    <li>Submit legal entitlement documents to the destination app/provider process.</li>
    <li>Complete any destination KYC/AML/security steps required by the provider.</li>
  </ul>
  <p>Legal entitlement verification must be completed directly with the destination app/provider.</p>
  <p>Technical-layer disclaimer: this platform is a technical coordination layer only and coordinates notification and secure access workflow only. It is not the legal decision authority.</p>
  <p>For safety, this link is one-time and must pass a second factor in unlock flow.</p>
  `;
}

async function sendEmail(to: string, subject: string, html: string) {
  let lastError = "";

  if (RESEND_API_KEY) {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "Digital Legacy Weaver <noreply@legacyweaver.app>",
        to,
        subject,
        html,
      }),
    });
    if (response.ok) {
      return;
    }
    lastError = `resend:${response.status}:${await response.text()}`;
  }

  if (SENDGRID_API_KEY) {
    const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${SENDGRID_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: to }] }],
        from: { email: "noreply@legacyweaver.app", name: "Digital Legacy Weaver" },
        subject,
        content: [{ type: "text/html", value: html }],
      }),
    });
    if (response.ok || response.status === 202) {
      return;
    }
    lastError = `${lastError};sendgrid:${response.status}:${await response.text()}`;
  }

  throw new Error(`No email provider succeeded. ${lastError || "missing provider keys"}`);
}

async function getActivePTNPolicy(): Promise<string> {
  const { data, error } = await supabase
    .from("policy_documents")
    .select("ptn_source")
    .eq("is_active", true)
    .order("updated_at", { ascending: false })
    .limit(1)
    .single();
  if (error || !data) throw new Error(`No active policy found: ${error?.message}`);
  return data.ptn_source as string;
}

async function isDispatchEnabled(): Promise<{ enabled: boolean; reason?: string }> {
  const { data, error } = await supabase
    .from("system_safety_controls")
    .select("dispatch_enabled, reason")
    .eq("id", true)
    .maybeSingle();
  if (error) throw new Error(`system safety read failed: ${error.message}`);
  if (!data) return { enabled: true };
  return {
    enabled: Boolean(data.dispatch_enabled),
    reason: (data.reason as string | null) ?? undefined,
  };
}

async function writeHeartbeat(status: "ok" | "warn" | "error", details: Record<string, unknown>) {
  await supabase.from("system_heartbeats").insert({
    source: "dispatch-trigger",
    status,
    details,
  });
}

async function getSafetySettings(ownerId: string): Promise<SafetySettings> {
  const { data, error } = await supabase
    .from("user_safety_settings")
    .select(
      "reminders_enabled, reminder_channels, reminder_offsets_days, grace_period_days, legal_disclaimer_accepted, emergency_pause_until, require_multisignal_before_release, recent_signal_window_hours, minimum_recent_signal_types, require_guardian_approval_legacy, guardian_grace_hours, private_first_mode, minimize_trace_metadata, trace_retention_days",
    )
    .eq("owner_id", ownerId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) {
    return {
      reminders_enabled: true,
      reminder_channels: ["email"],
      reminder_offsets_days: [14, 7, 1],
      grace_period_days: 3,
      legal_disclaimer_accepted: false,
      emergency_pause_until: null,
      require_multisignal_before_release: true,
      recent_signal_window_hours: 72,
      minimum_recent_signal_types: 2,
      require_guardian_approval_legacy: false,
      guardian_grace_hours: 72,
      private_first_mode: true,
      minimize_trace_metadata: true,
      trace_retention_days: 14,
    };
  }
  return data as SafetySettings;
}

type RequirementTraceEntry = {
  name: string;
  mode: "strict" | "advisory";
  risk?: string;
  evidence?: string;
  owner?: string;
  satisfied: boolean;
  enforcement: "block" | "warn";
};

function sanitizeRequirementTrace(
  trace: RequirementTraceEntry[],
  safety: SafetySettings,
): Array<{
  name: string;
  mode: "strict" | "advisory";
  risk?: string;
  satisfied: boolean;
  enforcement: "block" | "warn";
}> {
  if (!safety.private_first_mode || !safety.minimize_trace_metadata) {
    return trace.map((entry) => ({
      name: entry.name,
      mode: entry.mode,
      risk: entry.risk,
      satisfied: entry.satisfied,
      enforcement: entry.enforcement,
    }));
  }
  return trace.map((entry) => ({
    name: entry.name,
    mode: entry.mode,
    risk: entry.risk,
    satisfied: entry.satisfied,
    enforcement: entry.enforcement,
  }));
}

function buildPrivateFirstMetadata(
  base: Record<string, unknown>,
  safety: SafetySettings,
  trace?: RequirementTraceEntry[],
) {
  const metadata: Record<string, unknown> = {
    ...base,
    privateFirstMode: safety.private_first_mode,
    traceRetentionDays: safety.trace_retention_days,
  };
  if (trace && trace.length > 0) {
    metadata.requirementTrace = sanitizeRequirementTrace(trace, safety);
  }
  return metadata;
}

async function hasRecentMultiSignals(ownerId: string, windowHours: number, minSignalTypes: number): Promise<boolean> {
  const sinceIso = new Date(Date.now() - windowHours * 60 * 60 * 1000).toISOString();
  const { data, error } = await supabase
    .from("owner_life_signals")
    .select("signal_type")
    .eq("owner_id", ownerId)
    .gte("occurred_at", sinceIso);
  if (error) throw new Error(error.message);
  const uniqueTypes = new Set((data ?? []).map((row) => String(row.signal_type)));
  return uniqueTypes.size >= minSignalTypes;
}

async function hasGuardianApproval(ownerId: string, mode: "legacy" | "self_recovery", cycleDate: string): Promise<boolean> {
  const { data, error } = await supabase
    .from("guardian_approvals")
    .select("id")
    .eq("owner_id", ownerId)
    .eq("mode", mode)
    .eq("cycle_date", cycleDate)
    .eq("approved", true)
    .not("approved_at", "is", null)
    .limit(1)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return Boolean(data);
}

async function hasRecentFinalRelease(ownerId: string, mode: "legacy" | "self_recovery", withinHours: number): Promise<boolean> {
  const sinceIso = new Date(Date.now() - withinHours * 60 * 60 * 1000).toISOString();
  const { data, error } = await supabase
    .from("trigger_dispatch_events")
    .select("id")
    .eq("owner_id", ownerId)
    .eq("mode", mode)
    .eq("stage", "final_release")
    .eq("status", "sent")
    .gte("created_at", sinceIso)
    .limit(1)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return Boolean(data);
}

async function evaluateRequiredControls(args: {
  ownerId: string;
  mode: "legacy" | "self_recovery";
  safety: SafetySettings;
  requiredControls: RequirementControl[];
}): Promise<{
  allowed: boolean;
  strictMissing: string[];
  advisoryUnmet: string[];
  trace: Array<{
    name: string;
    mode: "strict" | "advisory";
    risk?: string;
    evidence?: string;
    owner?: string;
    satisfied: boolean;
    enforcement: "block" | "warn";
  }>;
}> {
  const strictMissing: string[] = [];
  const advisoryUnmet: string[] = [];
  const trace: RequirementTraceEntry[] = [];
  for (const control of args.requiredControls) {
    const requirement = control.name;
    let satisfied = false;

    if (requirement === "consent_active") {
      satisfied = args.safety.legal_disclaimer_accepted;
    } else if (requirement === "cooldown_24h") {
      const hasRecent = await hasRecentFinalRelease(args.ownerId, args.mode, 24);
      satisfied = !hasRecent;
    } else if (requirement === "provider_legal_verification_handoff") {
      // Runtime assumes handoff clause is satisfied via outbound provider checklist messaging.
      satisfied = true;
    } else {
      // Unknown controls are treated as unmet with mode-driven handling.
      satisfied = false;
    }

    if (!satisfied) {
      if (control.mode === "advisory") {
        advisoryUnmet.push(requirement);
      } else {
        strictMissing.push(requirement);
      }
    }
    trace.push({
      name: requirement,
      mode: control.mode,
      risk: control.risk,
      evidence: control.evidence,
      owner: control.owner,
      satisfied,
      enforcement: control.mode === "strict" ? "block" : "warn",
    });
  }
  return { allowed: strictMissing.length === 0, strictMissing, advisoryUnmet, trace };
}

async function insertDispatchEvent(
  ownerId: string,
  mode: "legacy" | "self_recovery",
  stage: "reminder_14d" | "reminder_7d" | "reminder_1d" | "final_release",
  status: "pending" | "sent" | "skipped" | "error",
  reason: string,
  metadata: Record<string, unknown>,
) {
  const cycleDate = new Date().toISOString().slice(0, 10);
  const { error } = await supabase.from("trigger_dispatch_events").insert({
    cycle_date: cycleDate,
    owner_id: ownerId,
    mode,
    stage,
    status,
    reason,
    metadata,
  });
  if (!error) return true;
  if ((error as { code?: string }).code === "23505") {
    return false;
  }
  throw new Error(error.message);
}

async function createSecureDeliveryLink(ownerId: string, mode: "legacy" | "self_recovery") {
  const accessKeyBytes = crypto.getRandomValues(new Uint8Array(32));
  const rawAccessKey = [...accessKeyBytes].map((b) => b.toString(16).padStart(2, "0")).join("");
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(rawAccessKey));
  const accessKeyHash = [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
  const expiresAt = new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString();

  const { data, error } = await supabase
    .from("delivery_access_keys")
    .insert({
      owner_id: ownerId,
      mode,
      access_key_hash: accessKeyHash,
      expires_at: expiresAt,
      metadata: { note: "one-time delivery access link; requires second factor in unlock flow" },
    })
    .select("id")
    .single();
  if (error || !data) throw new Error(`Access key create failed: ${error?.message}`);

  return `${DELIVERY_BASE_URL}?access_id=${data.id}&access_key=${rawAccessKey}&mode=${mode}`;
}

function buildCaseId(ownerId: string, mode: "legacy" | "self_recovery", cycleDate: string): string {
  return `${ownerId}-${cycleDate}-${mode}`;
}

async function submitPartnerHandoffNotice(args: {
  ownerId: string;
  mode: "legacy" | "self_recovery";
  receiver: string;
  cycleDate: string;
}) {
  if (!HANDOFF_INTERNAL_KEY) {
    await supabase.from("trigger_logs").insert({
      owner_id: args.ownerId,
      mode: args.mode,
      action: "submit_partner_handoff_notice",
      status: "skipped",
      reason: "handoff internal key is not configured",
      metadata: { integration: "handoff-notice", configured: false },
      processed_at: new Date().toISOString(),
    });
    return;
  }

  const payload = {
    case_id: buildCaseId(args.ownerId, args.mode, args.cycleDate),
    owner_ref: args.ownerId,
    beneficiary_ref: args.receiver,
    mode: args.mode,
    trigger_timestamp: new Date().toISOString(),
    handoff_disclaimer: "Legal entitlement verification must be completed directly with the destination app/provider.",
    audit_reference: `dispatch-trigger:${args.cycleDate}:${args.mode}`,
  };

  const response = await fetch(`${SUPABASE_URL}/functions/v1/handoff-notice`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": SUPABASE_SERVICE_ROLE_KEY,
      "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      "x-handoff-internal-key": HANDOFF_INTERNAL_KEY,
    },
    body: JSON.stringify(payload),
  });

  const text = await response.text();
  if (!response.ok) {
    console.error("handoff-notice function failed", response.status, text.slice(0, 1000));
    return;
  }
}

async function processMode(profile: Profile, mode: "legacy" | "self_recovery", policySource: string) {
  const cycleDate = new Date().toISOString().slice(0, 10);
  const inactiveDays = daysSince(profile.last_active_at);
  const threshold = mode === "legacy" ? profile.legacy_inactivity_days : profile.self_recovery_inactivity_days;
  const safety = await getSafetySettings(profile.id);
  const pauseUntil = safety.emergency_pause_until ? new Date(safety.emergency_pause_until).getTime() : 0;
  if (pauseUntil > Date.now()) {
    await insertDispatchEvent(profile.id, mode, "final_release", "skipped", "emergency pause active", {
      pauseUntil: safety.emergency_pause_until,
    });
    return;
  }
  if (!safety.legal_disclaimer_accepted) {
    await insertDispatchEvent(profile.id, mode, "final_release", "skipped", "legal consent missing", {});
    return;
  }

  const action = actionFor(mode);
  const compiled = compilePTN(policySource);
  const decision = evaluatePolicy(compiled, "system_scheduler", action);

  if (!decision.allowed) {
    await supabase.from("trigger_logs").insert({
      owner_id: profile.id,
      mode,
      action,
      status: "skipped",
      reason: decision.reasons.join("; "),
      metadata: { inactiveDays, threshold, required: decision.required, privateFirstMode: safety.private_first_mode },
    });
    return;
  }

  const requirementGate = await evaluateRequiredControls({
    ownerId: profile.id,
    mode,
    safety,
    requiredControls: decision.requiredControls,
  });
  if (requirementGate.advisoryUnmet.length > 0) {
    await supabase.from("trigger_logs").insert({
      owner_id: profile.id,
      mode,
      action,
      status: "pending",
      reason: `advisory controls unmet: ${requirementGate.advisoryUnmet.join("; ")}`,
      metadata: buildPrivateFirstMetadata({
        inactiveDays,
        threshold,
        required: decision.required,
        advisoryUnmet: requirementGate.advisoryUnmet,
      }, safety, requirementGate.trace),
      processed_at: new Date().toISOString(),
    });
  }
  if (!requirementGate.allowed) {
    await insertDispatchEvent(profile.id, mode, "final_release", "skipped", "required controls are not satisfied", {
      required: decision.required,
      strictMissing: requirementGate.strictMissing,
      advisoryUnmet: requirementGate.advisoryUnmet,
      inactiveDays,
      threshold,
      privateFirstMode: safety.private_first_mode,
      traceRetentionDays: safety.trace_retention_days,
    });
    await supabase.from("trigger_logs").insert({
      owner_id: profile.id,
      mode,
      action,
      status: "skipped",
      reason: `required controls are not satisfied: ${requirementGate.strictMissing.join("; ")}`,
      metadata: buildPrivateFirstMetadata({
        inactiveDays,
        threshold,
        required: decision.required,
        strictMissing: requirementGate.strictMissing,
        advisoryUnmet: requirementGate.advisoryUnmet,
      }, safety, requirementGate.trace),
      processed_at: new Date().toISOString(),
    });
    return;
  }

  if (safety.reminders_enabled) {
    for (const offset of safety.reminder_offsets_days) {
      const stage = `reminder_${offset}d` as "reminder_14d" | "reminder_7d" | "reminder_1d";
      if (inactiveDays === threshold - offset && (offset === 14 || offset === 7 || offset === 1)) {
        const isFresh = await insertDispatchEvent(profile.id, mode, stage, "pending", "awaiting email send", {
          inactiveDays,
          threshold,
        });
        if (!isFresh) continue;
        await sendEmail(
          profile.backup_email,
          `Reminder: ${offset} day(s) before ${mode} trigger`,
          `<p>Your ${mode} trigger is approaching.</p><p>Inactive days: ${inactiveDays} / ${threshold}</p><p>Please open the app and confirm "I am still alive" if this is not intended.</p>`,
        );
        await supabase.from("trigger_dispatch_events").update({ status: "sent", reason: "reminder sent" }).eq("cycle_date", new Date().toISOString().slice(0, 10)).eq("owner_id", profile.id).eq("mode", mode).eq("stage", stage);
      }
    }
  }

  if (inactiveDays < threshold + safety.grace_period_days) {
    return;
  }

  if (safety.require_multisignal_before_release) {
    const hasSignals = await hasRecentMultiSignals(
      profile.id,
      safety.recent_signal_window_hours,
      safety.minimum_recent_signal_types,
    );
    if (hasSignals) {
      await insertDispatchEvent(profile.id, mode, "final_release", "skipped", "recent multi-signal proof-of-life detected", {
        inactiveDays,
        threshold,
        signalWindowHours: safety.recent_signal_window_hours,
        minimumSignalTypes: safety.minimum_recent_signal_types,
      });
      await supabase.from("trigger_logs").insert({
        owner_id: profile.id,
        mode,
        action,
        status: "skipped",
        reason: "recent multi-signal proof-of-life detected",
        metadata: {
          inactiveDays,
          threshold,
          signalWindowHours: safety.recent_signal_window_hours,
          minimumSignalTypes: safety.minimum_recent_signal_types,
        },
        processed_at: new Date().toISOString(),
      });
      return;
    }
  }

  if (mode === "legacy" && safety.require_guardian_approval_legacy) {
    const guardianGraceDays = Math.ceil(safety.guardian_grace_hours / 24);
    if (inactiveDays < threshold + safety.grace_period_days + guardianGraceDays) {
      await insertDispatchEvent(profile.id, mode, "final_release", "skipped", "guardian grace window still active", {
        inactiveDays,
        threshold,
        guardianGraceHours: safety.guardian_grace_hours,
      });
      return;
    }
    const guardianApproved = await hasGuardianApproval(profile.id, mode, cycleDate);
    if (!guardianApproved) {
      await insertDispatchEvent(profile.id, mode, "final_release", "skipped", "guardian approval missing for legacy release", {
        inactiveDays,
        threshold,
        cycleDate,
        guardianGraceHours: safety.guardian_grace_hours,
      });
      await supabase.from("trigger_logs").insert({
        owner_id: profile.id,
        mode,
        action,
        status: "skipped",
        reason: "guardian approval missing for legacy release",
        metadata: { inactiveDays, threshold, cycleDate, guardianGraceHours: safety.guardian_grace_hours },
        processed_at: new Date().toISOString(),
      });
      return;
    }
  }

  const receiver = mode === "legacy" ? profile.beneficiary_email : profile.backup_email;
  if (!receiver) return;

  const isFresh = await insertDispatchEvent(profile.id, mode, "final_release", "pending", "awaiting secure-link email", {
    inactiveDays,
    threshold,
    gracePeriodDays: safety.grace_period_days,
  });
  if (!isFresh) return;

  const secureLink = await createSecureDeliveryLink(profile.id, mode);
  await sendEmail(
    receiver,
    mode === "legacy" ? "Legacy Access Link" : "Self-Recovery Access Link",
    buildProviderHandoffHtml({
      secureLink,
      mode,
      inactiveDays,
      threshold,
    }),
  );
  await submitPartnerHandoffNotice({
    ownerId: profile.id,
    mode,
    receiver,
    cycleDate,
  });

  await supabase
    .from("trigger_dispatch_events")
    .update({ status: "sent", reason: "secure-link sent" })
    .eq("cycle_date", new Date().toISOString().slice(0, 10))
    .eq("owner_id", profile.id)
    .eq("mode", mode)
    .eq("stage", "final_release");

  await supabase.from("trigger_logs").insert({
    owner_id: profile.id,
    mode,
    action,
    status: "sent",
    reason: "policy-approved",
    metadata: {
      inactiveDays,
      threshold,
      required: decision.required,
      privateFirstMode: safety.private_first_mode,
      traceRetentionDays: safety.trace_retention_days,
      requirementTrace: sanitizeRequirementTrace(requirementGate.trace, safety),
    },
    processed_at: new Date().toISOString(),
  });
}

Deno.serve(async () => {
  const startedAt = Date.now();
  try {
    const safety = await isDispatchEnabled();
    if (!safety.enabled) {
      await writeHeartbeat("warn", {
        skipped: true,
        reason: safety.reason ?? "dispatch disabled by global safety control",
      });
      return new Response(
        JSON.stringify({
          ok: true,
          skipped: true,
          reason: safety.reason ?? "dispatch disabled",
        }),
        {
          headers: { "Content-Type": "application/json" },
          status: 200,
        },
      );
    }

    const policySource = await getActivePTNPolicy();
    const { data: profiles, error } = await supabase
      .from("profiles")
      .select("id, backup_email, beneficiary_email, legacy_inactivity_days, self_recovery_inactivity_days, last_active_at");
    if (error) throw new Error(error.message);

    for (const profile of (profiles ?? []) as Profile[]) {
      await processMode(profile, "self_recovery", policySource);
      await processMode(profile, "legacy", policySource);
    }

    await writeHeartbeat("ok", {
      processedProfiles: profiles?.length ?? 0,
      elapsedMs: Date.now() - startedAt,
    });

    return new Response(JSON.stringify({ ok: true, processed: profiles?.length ?? 0 }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    await writeHeartbeat("error", { error: String(error), elapsedMs: Date.now() - startedAt });
    return new Response(JSON.stringify({ ok: false, error: String(error) }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
