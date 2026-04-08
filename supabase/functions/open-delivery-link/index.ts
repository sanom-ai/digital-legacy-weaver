import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Action = "request_code" | "request_code_manual" | "unlock" | "report_wrong_recipient";

type RequestPayload = {
  action: Action;
  access_id: string;
  access_key: string;
  verification_code?: string;
  totp_code?: string;
  beneficiary_name?: string;
  verification_phrase?: string;
};

type ReceiptVisibility = "existence_only" | "route_only" | "route_and_instructions";

type DeliveryReceiptItem = {
  id: string;
  kind: string;
  title: string;
  visibility_policy: ReceiptVisibility;
  value_disclosure_mode: "hidden" | "institution_verified_only";
  verification_route: string;
  instruction_summary?: string;
};

type DeliveryContext = {
  owner_reference: string;
  mode: "legacy" | "self_recovery";
  source: "live_runtime";
  trigger_cycle_date: string | null;
  trigger_stage: string | null;
  trigger_status: string | null;
  trigger_reason: string | null;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const SENDGRID_API_KEY = Deno.env.get("SENDGRID_API_KEY");
const BETA_MANUAL_CODE_ENABLED = (Deno.env.get("BETA_MANUAL_CODE_ENABLED") ?? "false").toLowerCase() === "true";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function logSecurityEvent(args: {
  eventType: string;
  severity: "info" | "warn" | "critical";
  actorScope?: string;
  actorRaw?: string;
  accessId?: string;
  ownerId?: string;
  mode?: "legacy" | "self_recovery";
  details?: Record<string, unknown>;
}) {
  const actorHash = args.actorRaw ? await sha256Hex(args.actorRaw) : null;
  const { error } = await supabase.from("security_events").insert({
    event_type: args.eventType,
    severity: args.severity,
    actor_scope: args.actorScope ?? null,
    actor_hash: actorHash,
    access_id: args.accessId ?? null,
    owner_id: args.ownerId ?? null,
    mode: args.mode ?? null,
    details: args.details ?? {},
  });
  if (error) {
    console.error("security_events insert failed:", error.message);
  }
}

async function isUnlockEnabled(): Promise<{ enabled: boolean; reason?: string }> {
  const { data, error } = await supabase
    .from("system_safety_controls")
    .select("unlock_enabled, reason")
    .eq("id", true)
    .maybeSingle();
  if (error) throw new Error(`system safety read failed: ${error.message}`);
  if (!data) return { enabled: true };
  return {
    enabled: Boolean(data.unlock_enabled),
    reason: (data.reason as string | null) ?? undefined,
  };
}

function extractClientIp(req: Request): string {
  const cfIp = req.headers.get("cf-connecting-ip")?.trim();
  if (cfIp) return cfIp;
  const forwarded = req.headers.get("x-forwarded-for")?.trim();
  if (forwarded) {
    return forwarded.split(",")[0].trim();
  }
  return "unknown";
}

function nowIso(): string {
  return new Date().toISOString();
}

function addMinutesIso(minutes: number): string {
  return new Date(Date.now() + minutes * 60 * 1000).toISOString();
}

function routeForKind(kind: string): string {
  const normalized = kind.trim().toLowerCase();
  if (normalized === "self_recovery") {
    return "Verify the recovery path directly with the designated provider or recovery service.";
  }
  if (normalized === "legacy") {
    return "Verify holdings, legal status, or account details directly with the relevant partner, institution, or law office.";
  }
  return "Verify status directly with the relevant partner, institution, or professional advisor.";
}

function parseReleaseInstruction(raw: string | null): string | undefined {
  if (!raw || !raw.trim()) return undefined;
  const trimmed = raw.trim();
  try {
    const parsed = JSON.parse(trimmed) as Record<string, unknown>;
    const instruction = parsed["instruction_summary"] ?? parsed["beneficiary_instruction"];
    if (typeof instruction === "string" && instruction.trim()) {
      return instruction.trim();
    }
  } catch {
    // Non-JSON release notes are treated as plain instruction text.
  }
  return trimmed;
}

function normalizeVisibility(value: string | null | undefined): ReceiptVisibility {
  if (value === "existence_only" || value === "route_only" || value === "route_and_instructions") {
    return value;
  }
  return "route_only";
}

function normalizeValueDisclosure(value: string | null | undefined): "hidden" | "institution_verified_only" {
  if (value === "hidden") {
    return "hidden";
  }
  return "institution_verified_only";
}

function buildReceiptItems(items: Array<Record<string, unknown>>): DeliveryReceiptItem[] {
  return items.map((item) => {
    const kind = String(item.kind ?? "legacy");
    const visibility = normalizeVisibility(item.post_trigger_visibility as string | undefined);
    const instruction = parseReleaseInstruction(item.release_notes as string | null);
    const receiptItem: DeliveryReceiptItem = {
      id: String(item.id ?? ""),
      kind,
      title: String(item.title ?? "Untitled delivery item"),
      visibility_policy: visibility,
      value_disclosure_mode: normalizeValueDisclosure(item.value_disclosure_mode as string | undefined),
      verification_route: routeForKind(kind),
    };

    if (visibility === "route_and_instructions" && instruction) {
      receiptItem.instruction_summary = instruction;
    }

    return receiptItem;
  });
}

async function getDeliveryContext(ownerId: string, mode: "legacy" | "self_recovery"): Promise<DeliveryContext> {
  const { data, error } = await supabase
    .from("trigger_dispatch_events")
    .select("cycle_date, stage, status, reason")
    .eq("owner_id", ownerId)
    .eq("mode", mode)
    .eq("stage", "final_release")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) {
    throw new Error(`Dispatch context read failed: ${error.message}`);
  }
  return {
    owner_reference: ownerId,
    mode,
    source: "live_runtime",
    trigger_cycle_date: (data?.cycle_date as string | undefined) ?? null,
    trigger_stage: (data?.stage as string | undefined) ?? null,
    trigger_status: (data?.status as string | undefined) ?? null,
    trigger_reason: (data?.reason as string | undefined) ?? null,
  };
}

function normalizeIdentityText(value: string): string {
  return value.trim().replace(/\s+/g, " ").toLowerCase();
}

function metadataRecord(input: unknown): Record<string, unknown> {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    return {};
  }
  return input as Record<string, unknown>;
}

function readTemporaryLockUntil(metadata: unknown): string | null {
  const value = metadataRecord(metadata)["temporary_lock_until"];
  return typeof value === "string" && value.trim().length > 0 ? value : null;
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
    if (response.ok) return;
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
    if (response.ok || response.status === 202) return;
    lastError = `${lastError};sendgrid:${response.status}:${await response.text()}`;
  }

  throw new Error(`No email provider succeeded. ${lastError || "missing provider keys"}`);
}

async function enforceRateLimit(
  scope: string,
  subjectRaw: string,
  maxAttempts: number,
  windowMinutes: number,
  blockMinutes: number,
) {
  const now = new Date();
  const subject = await sha256Hex(subjectRaw);
  const { data: row, error } = await supabase
    .from("delivery_access_rate_limits")
    .select("scope, subject, window_started_at, attempt_count, blocked_until")
    .eq("scope", scope)
    .eq("subject", subject)
    .maybeSingle();
  if (error) throw new Error(`rate limit read failed: ${error.message}`);

  if (!row) {
    const { error: insertError } = await supabase.from("delivery_access_rate_limits").insert({
      scope,
      subject,
      window_started_at: nowIso(),
      attempt_count: 1,
      blocked_until: null,
      last_attempt_at: nowIso(),
    });
    if (insertError) throw new Error(`rate limit insert failed: ${insertError.message}`);
    return;
  }

  const blockedUntil = row.blocked_until ? new Date(row.blocked_until).getTime() : 0;
  if (blockedUntil > now.getTime()) {
    await logSecurityEvent({
      eventType: "rate_limited",
      severity: "warn",
      actorScope: scope,
      actorRaw: subjectRaw,
      details: { phase: "blocked_window_active", blockedUntil: row.blocked_until },
    });
    throw new Error("Too many attempts. Please retry later.");
  }

  const windowStart = new Date(row.window_started_at).getTime();
  const windowMs = windowMinutes * 60 * 1000;
  const resetWindow = now.getTime() - windowStart > windowMs;
  const nextCount = resetWindow ? 1 : (row.attempt_count as number) + 1;

  if (nextCount > maxAttempts) {
    const blocked = new Date(now.getTime() + blockMinutes * 60 * 1000).toISOString();
    const { error: blockError } = await supabase
      .from("delivery_access_rate_limits")
      .update({
        attempt_count: nextCount,
        blocked_until: blocked,
        last_attempt_at: nowIso(),
      })
      .eq("scope", scope)
      .eq("subject", subject);
    if (blockError) throw new Error(`rate limit block failed: ${blockError.message}`);
    await logSecurityEvent({
      eventType: "rate_limited",
      severity: "warn",
      actorScope: scope,
      actorRaw: subjectRaw,
      details: { phase: "threshold_exceeded", nextCount, maxAttempts, blockMinutes },
    });
    throw new Error("Too many attempts. Please retry later.");
  }

  const { error: updateError } = await supabase
    .from("delivery_access_rate_limits")
    .update({
      attempt_count: nextCount,
      window_started_at: resetWindow ? nowIso() : row.window_started_at,
      blocked_until: null,
      last_attempt_at: nowIso(),
    })
    .eq("scope", scope)
    .eq("subject", subject);
  if (updateError) throw new Error(`rate limit update failed: ${updateError.message}`);
}

async function getValidAccessKey(accessId: string, accessKey: string) {
  const accessKeyHash = await sha256Hex(accessKey);
  const { data, error } = await supabase
    .from("delivery_access_keys")
    .select("id, owner_id, mode, access_key_hash, expires_at, consumed_at, blocked_at, blocked_reason, metadata")
    .eq("id", accessId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) {
    await logSecurityEvent({
      eventType: "access_denied",
      severity: "warn",
      actorScope: "access_id",
      actorRaw: accessId,
      accessId,
      details: { reason: "access_id_not_found" },
    });
    throw new Error("Invalid access credentials.");
  }
  if (data.access_key_hash !== accessKeyHash) {
    await logSecurityEvent({
      eventType: "access_denied",
      severity: "warn",
      actorScope: "access_id",
      actorRaw: accessId,
      accessId,
      ownerId: data.owner_id,
      mode: data.mode,
      details: { reason: "access_key_mismatch" },
    });
    throw new Error("Invalid access credentials.");
  }
  if (data.consumed_at) {
    await logSecurityEvent({
      eventType: "access_denied",
      severity: "warn",
      actorScope: "access_id",
      actorRaw: accessId,
      accessId,
      ownerId: data.owner_id,
      mode: data.mode,
      details: { reason: "access_key_already_consumed" },
    });
    throw new Error("This access key has already been used.");
  }
  if (data.blocked_at) {
    await logSecurityEvent({
      eventType: "access_denied",
      severity: "warn",
      actorScope: "access_id",
      actorRaw: accessId,
      accessId,
      ownerId: data.owner_id,
      mode: data.mode,
      details: { reason: "access_key_blocked", blockedReason: data.blocked_reason ?? null },
    });
    throw new Error("This access key is temporarily blocked pending recipient verification.");
  }
  const temporaryLockUntil = readTemporaryLockUntil(data.metadata);
  if (temporaryLockUntil) {
    const lockedUntilMs = new Date(temporaryLockUntil).getTime();
    if (!Number.isNaN(lockedUntilMs) && lockedUntilMs > Date.now()) {
      await logSecurityEvent({
        eventType: "access_denied",
        severity: "warn",
        actorScope: "access_id",
        actorRaw: accessId,
        accessId,
        ownerId: data.owner_id,
        mode: data.mode,
        details: { reason: "access_key_temporarily_locked", temporaryLockUntil },
      });
      throw new Error("This receipt is temporarily locked. Please retry later.");
    }
  }
  if (new Date(data.expires_at).getTime() < Date.now()) {
    await logSecurityEvent({
      eventType: "access_denied",
      severity: "warn",
      actorScope: "access_id",
      actorRaw: accessId,
      accessId,
      ownerId: data.owner_id,
      mode: data.mode,
      details: { reason: "access_key_expired" },
    });
    throw new Error("Access key expired.");
  }
  return data as {
    id: string;
    owner_id: string;
    mode: "legacy" | "self_recovery";
    metadata?: Record<string, unknown> | null;
  };
}

async function reportWrongRecipient(accessId: string, accessKey: string, clientIp: string) {
  const valid = await getValidAccessKey(accessId, accessKey);

  const now = nowIso();
  const blockReason = "wrong_recipient_reported";
  const { error: blockError } = await supabase
    .from("delivery_access_keys")
    .update({
      blocked_at: now,
      blocked_reason: blockReason,
      metadata: {
        ...(valid.metadata ?? {}),
        wrong_recipient_reported_at: now,
        wrong_recipient_source: "beneficiary_secure_link",
      },
    })
    .eq("id", valid.id);
  if (blockError) throw new Error(`failed to block access key: ${blockError.message}`);

  const { error: reportError } = await supabase.from("delivery_wrong_recipient_reports").insert({
    access_key_id: valid.id,
    owner_id: valid.owner_id,
    mode: valid.mode,
    source: "beneficiary_secure_link",
    reported_ip_hash: await sha256Hex(clientIp),
    details: {
      accessId: accessId,
      action: "report_wrong_recipient",
    },
  });
  if (reportError) throw new Error(`failed to store wrong recipient report: ${reportError.message}`);

  await supabase.from("trigger_logs").insert({
    owner_id: valid.owner_id,
    mode: valid.mode,
    action: "wrong_recipient_reported",
    status: "sent",
    reason: "beneficiary reported this receipt is not theirs",
    metadata: {
      accessId,
      source: "beneficiary_secure_link",
    },
    processed_at: now,
  });
  await logSecurityEvent({
    eventType: "wrong_recipient_reported",
    severity: "warn",
    actorScope: "access_id",
    actorRaw: accessId,
    accessId,
    ownerId: valid.owner_id,
    mode: valid.mode,
    details: {
      source: "beneficiary_secure_link",
      action: "access_key_blocked",
    },
  });

  return {
    ok: true,
    message:
      "Thanks for reporting. This receipt has been paused and routed for re-verification. Do not share the link or code.",
  };
}

type TotpPolicy = {
  required: boolean;
  factorEnabled: boolean;
  secretBase32?: string;
  digits: number;
  periodSeconds: number;
};

async function getTotpPolicy(ownerId: string): Promise<TotpPolicy> {
  const { data: settings, error: settingsError } = await supabase
    .from("user_safety_settings")
    .select("require_totp_unlock")
    .eq("owner_id", ownerId)
    .maybeSingle();
  if (settingsError) throw new Error(settingsError.message);
  const required = Boolean(settings?.require_totp_unlock);

  const { data: factor, error: factorError } = await supabase
    .from("user_totp_factors")
    .select("secret_base32, digits, period_seconds, enabled")
    .eq("owner_id", ownerId)
    .maybeSingle();
  if (factorError) throw new Error(factorError.message);

  return {
    required,
    factorEnabled: Boolean(factor?.enabled),
    secretBase32: factor?.secret_base32 as string | undefined,
    digits: Number(factor?.digits ?? 6),
    periodSeconds: Number(factor?.period_seconds ?? 30),
  };
}

function base32ToBytes(base32: string): Uint8Array {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  const normalized = base32.replace(/=+$/g, "").replace(/\s+/g, "").toUpperCase();
  let bits = "";
  for (const char of normalized) {
    const idx = alphabet.indexOf(char);
    if (idx < 0) continue;
    bits += idx.toString(2).padStart(5, "0");
  }
  const bytes: number[] = [];
  for (let i = 0; i + 8 <= bits.length; i += 8) {
    bytes.push(parseInt(bits.slice(i, i + 8), 2));
  }
  return new Uint8Array(bytes);
}

async function hmacSha1(key: Uint8Array, message: Uint8Array): Promise<Uint8Array> {
  const cryptoKey = await crypto.subtle.importKey("raw", key, { name: "HMAC", hash: "SHA-1" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", cryptoKey, message);
  return new Uint8Array(sig);
}

async function generateTotpCode(secretBase32: string, digits: number, periodSeconds: number, tsMs: number): Promise<string> {
  const key = base32ToBytes(secretBase32);
  const counter = Math.floor(tsMs / 1000 / periodSeconds);
  const counterBytes = new Uint8Array(8);
  let c = counter;
  for (let i = 7; i >= 0; i--) {
    counterBytes[i] = c & 0xff;
    c = Math.floor(c / 256);
  }
  const hmac = await hmacSha1(key, counterBytes);
  const offset = hmac[hmac.length - 1] & 0x0f;
  const binCode =
    ((hmac[offset] & 0x7f) << 24) |
    ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) |
    (hmac[offset + 3] & 0xff);
  const mod = 10 ** digits;
  return String(binCode % mod).padStart(digits, "0");
}

async function verifyTotpCode(secretBase32: string, digits: number, periodSeconds: number, provided: string): Promise<boolean> {
  const now = Date.now();
  const windows = [-1, 0, 1];
  for (const w of windows) {
    const candidate = await generateTotpCode(secretBase32, digits, periodSeconds, now + w * periodSeconds * 1000);
    if (candidate === provided) return true;
  }
  return false;
}

async function getTargetEmail(ownerId: string, mode: "legacy" | "self_recovery"): Promise<string> {
  const { data, error } = await supabase
    .from("profiles")
    .select("backup_email, beneficiary_email")
    .eq("id", ownerId)
    .single();
  if (error || !data) throw new Error(`Profile missing: ${error?.message}`);
  const email = mode === "legacy" ? data.beneficiary_email : data.backup_email;
  if (!email) throw new Error("Delivery recipient not configured.");
  return email as string;
}

async function verifyLegacyBeneficiaryIdentity(
  ownerId: string,
  providedName?: string,
  providedPhrase?: string,
) {
  const { data, error } = await supabase
    .from("profiles")
    .select("beneficiary_name, beneficiary_verification_phrase_hash")
    .eq("id", ownerId)
    .maybeSingle();
  if (error) throw new Error(`Beneficiary identity lookup failed: ${error.message}`);
  if (!data) throw new Error("Owner profile missing.");

  const registeredName = (data.beneficiary_name ?? "").trim();
  const phraseHash = (data.beneficiary_verification_phrase_hash ?? "").trim();
  if (!registeredName || !phraseHash) {
    throw new Error("Beneficiary identity is not fully configured for this release.");
  }

  const normalizedName = normalizeIdentityText(providedName ?? "");
  if (!normalizedName || normalizedName !== normalizeIdentityText(registeredName)) {
    throw new Error("Beneficiary identity did not match the pre-registered name.");
  }

  const normalizedPhrase = normalizeIdentityText(providedPhrase ?? "");
  if (!normalizedPhrase) {
    throw new Error("Missing verification phrase.");
  }
  const providedHash = await sha256Hex(normalizedPhrase);
  if (providedHash !== phraseHash) {
    throw new Error("Verification phrase did not match the pre-registered identity.");
  }
}

async function getActiveChallenge(accessKeyId: string) {
  const { data, error } = await supabase
    .from("delivery_access_challenges")
    .select("id, code_hash, expires_at, consumed_at, attempts, max_attempts, created_at")
    .eq("access_key_id", accessKeyId)
    .is("consumed_at", null)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data as
    | {
        id: string;
        code_hash: string;
        expires_at: string;
        consumed_at: string | null;
        attempts: number;
        max_attempts: number;
        created_at: string;
      }
    | null;
}

async function registerChallengeFailure(
  challenge: { id: string; attempts: number; max_attempts: number },
  valid: { id: string; owner_id: string; mode: "legacy" | "self_recovery"; metadata?: Record<string, unknown> | null },
  accessId: string,
  reason: string,
) {
  const attemptsAfter = challenge.attempts + 1;
  await supabase
    .from("delivery_access_challenges")
    .update({ attempts: attemptsAfter })
    .eq("id", challenge.id);

  await logSecurityEvent({
    eventType: "invalid_code",
    severity: "warn",
    actorScope: "access_id",
    actorRaw: accessId,
    accessId,
    ownerId: valid.owner_id,
    mode: valid.mode,
    details: { attemptsAfter, maxAttempts: challenge.max_attempts, reason },
  });

  if (reason.startsWith("totp_")) {
    await logSecurityEvent({
      eventType: "invalid_totp",
      severity: "warn",
      actorScope: "access_id",
      actorRaw: accessId,
      accessId,
      ownerId: valid.owner_id,
      mode: valid.mode,
      details: { attemptsAfter, maxAttempts: challenge.max_attempts, reason },
    });
  }

  if (attemptsAfter < challenge.max_attempts) {
    return;
  }

  const temporaryLockUntil = addMinutesIso(10);
  const metadata = metadataRecord(valid.metadata);
  const { error: lockError } = await supabase
    .from("delivery_access_keys")
    .update({
      metadata: {
        ...metadata,
        temporary_lock_until: temporaryLockUntil,
        temporary_lock_reason: reason,
      },
    })
    .eq("id", valid.id);
  if (lockError) {
    throw new Error(`failed to apply temporary lock: ${lockError.message}`);
  }

  await logSecurityEvent({
    eventType: "unlock_temporary_lock",
    severity: "warn",
    actorScope: "access_id",
    actorRaw: accessId,
    accessId,
    ownerId: valid.owner_id,
    mode: valid.mode,
    details: { temporaryLockUntil, reason, attemptsAfter },
  });
}

async function requestCode(accessId: string, accessKey: string, manualMode = false) {
  const valid = await getValidAccessKey(accessId, accessKey);
  const activeChallenge = await getActiveChallenge(valid.id);
  if (activeChallenge && new Date(activeChallenge.expires_at).getTime() > Date.now()) {
    if (manualMode) {
      await supabase
        .from("delivery_access_challenges")
        .update({ consumed_at: nowIso() })
        .eq("id", activeChallenge.id);
    } else {
      await logSecurityEvent({
        eventType: "challenge_reuse_guard",
        severity: "info",
        actorScope: "access_id",
        actorRaw: accessId,
        accessId,
        ownerId: valid.owner_id,
        mode: valid.mode,
        details: { reason: "active_challenge_exists", challengeId: activeChallenge.id },
      });
      return {
        ok: true,
        message: "A verification code is already active for this receipt. Please use it or wait for expiration before requesting another code.",
      };
    }
  }

  if (manualMode && !BETA_MANUAL_CODE_ENABLED) {
    await logSecurityEvent({
      eventType: "manual_beta_code_denied",
      severity: "warn",
      actorScope: "access_id",
      actorRaw: accessId,
      accessId,
      ownerId: valid.owner_id,
      mode: valid.mode,
      details: { reason: "beta_manual_code_disabled" },
    });
    throw new Error("Closed beta manual code path is disabled.");
  }
  const code = String(Math.floor(100000 + Math.random() * 900000));
  const codeHash = await sha256Hex(code);
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

  await supabase.from("delivery_access_challenges").insert({
    access_key_id: valid.id,
    code_hash: codeHash,
    expires_at: expiresAt,
    max_attempts: 5,
  });

  if (manualMode) {
    await logSecurityEvent({
      eventType: "manual_beta_code_issued",
      severity: "warn",
      actorScope: "access_id",
      actorRaw: accessId,
      accessId,
      ownerId: valid.owner_id,
      mode: valid.mode,
      details: { expiresAt },
    });
    return {
      ok: true,
      manual_mode: true,
      manual_code: code,
      expires_at: expiresAt,
      message:
        "Closed beta code generated in-app. Share through a pre-arranged trusted channel only, and enter it in the app directly.",
    };
  }

  const to = await getTargetEmail(valid.owner_id, valid.mode);
  await sendEmail(
    to,
    "รหัสยืนยันสำหรับการรับมอบ | Digital Legacy Weaver",
    `<p>คุณได้รับรหัสนี้เพราะมีการเริ่มขั้นตอนรับมอบที่ตั้งไว้ล่วงหน้าใน Digital Legacy Weaver</p>
<p>You received this code because a pre-arranged Digital Legacy Weaver handoff was initiated.</p>
<p><strong>ระบบจะไม่ขอให้คุณโอนเงินหรือเปิดเผยรหัสผ่านทางอีเมลนี้</strong></p>
<p><strong>We never ask for money transfer or password reset in this email.</strong></p>
<p>รหัสยืนยันของคุณคือ: <strong>${code}</strong></p>
<p>Your verification code is: <strong>${code}</strong></p>
<p>รหัสหมดอายุใน 10 นาที | Code expires in 10 minutes.</p>
<p>หากคุณไม่ได้เริ่มขั้นตอนนี้จากในแอปด้วยตัวเอง ให้หยุดและยืนยันกับพยาน/ญาติก่อนดำเนินการต่อ</p>
<p>If this request was not initiated by you in-app, stop and verify with a family guardian before continuing.</p>`,
  );

  return { ok: true, message: "Verification code sent." };
}

async function unlock(
  accessId: string,
  accessKey: string,
  code: string,
  totpCode?: string,
  beneficiaryName?: string,
  verificationPhrase?: string,
) {
  const valid = await getValidAccessKey(accessId, accessKey);
  const now = Date.now();
  const challenge = await getActiveChallenge(valid.id);
  if (!challenge) throw new Error("No active verification challenge. Request code first.");
  if (challenge.consumed_at) throw new Error("Challenge already used.");
  if (new Date(challenge.expires_at).getTime() < now) throw new Error("Verification code expired.");
  if (challenge.attempts >= challenge.max_attempts) throw new Error("Too many attempts.");

  const providedHash = await sha256Hex(code);
  if (providedHash !== challenge.code_hash) {
    await registerChallengeFailure(challenge, valid, accessId, "invalid_verification_code");
    throw new Error("Invalid verification code.");
  }

  if (valid.mode === "legacy") {
    try {
      await verifyLegacyBeneficiaryIdentity(valid.owner_id, beneficiaryName, verificationPhrase);
    } catch (_) {
      await registerChallengeFailure(
        challenge,
        valid,
        accessId,
        "beneficiary_identity_mismatch",
      );
      throw new Error("Beneficiary identity did not match the pre-registered identity.");
    }
  }

  const totpPolicy = await getTotpPolicy(valid.owner_id);
  if (totpPolicy.required) {
    if (!totpPolicy.factorEnabled || !totpPolicy.secretBase32) {
      throw new Error("TOTP is required but not configured for this release profile.");
    }
    if (!totpCode || !/^\d{6,8}$/.test(totpCode)) {
      await registerChallengeFailure(challenge, valid, accessId, "totp_missing_or_bad_format");
      throw new Error("Missing or invalid TOTP code.");
    }
    const ok = await verifyTotpCode(
      totpPolicy.secretBase32,
      totpPolicy.digits,
      totpPolicy.periodSeconds,
      totpCode,
    );
    if (!ok) {
      await registerChallengeFailure(challenge, valid, accessId, "totp_mismatch");
      throw new Error("Invalid TOTP code.");
    }
  }

  await supabase
    .from("delivery_access_challenges")
    .update({ consumed_at: nowIso(), attempts: challenge.attempts + 1 })
    .eq("id", challenge.id);
  await supabase.from("delivery_access_keys").update({ consumed_at: nowIso() }).eq("id", valid.id);

  const { data: items, error: itemsError } = await supabase
    .from("recovery_items")
    .select("id, kind, title, release_notes, post_trigger_visibility, value_disclosure_mode")
    .eq("owner_id", valid.owner_id)
    .eq("kind", valid.mode)
    .eq("is_active", true);
  if (itemsError) throw new Error(itemsError.message);
  const receiptItems = buildReceiptItems((items ?? []) as Array<Record<string, unknown>>);
  const deliveryContext = await getDeliveryContext(valid.owner_id, valid.mode);

  await supabase.from("trigger_logs").insert({
    owner_id: valid.owner_id,
    mode: valid.mode,
    action: "unlock_delivery_bundle",
    status: "sent",
    reason: "delivery access key + verification code succeeded",
    metadata: { deliveredItems: items?.length ?? 0 },
    processed_at: nowIso(),
  });
  await logSecurityEvent({
    eventType: "unlock_success",
    severity: "info",
    actorScope: "access_id",
    actorRaw: accessId,
    accessId,
    ownerId: valid.owner_id,
    mode: valid.mode,
    details: { deliveredItems: items?.length ?? 0 },
  });

  return {
    ok: true,
    mode: valid.mode,
    items: receiptItems,
    delivery_context: deliveryContext,
    item_count: receiptItems.length,
  };
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ ok: false, error: "Use POST." }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }
    const payload = (await req.json()) as RequestPayload;
    if (!payload?.action || !payload.access_id || !payload.access_key) {
      throw new Error("Missing required fields.");
    }
    const globalSafety = await isUnlockEnabled();
    if (!globalSafety.enabled) {
      await logSecurityEvent({
        eventType: "unlock_disabled",
        severity: "warn",
        actorScope: "access_id",
        actorRaw: payload.access_id,
        accessId: payload.access_id,
        details: { reason: globalSafety.reason ?? "unlock disabled by global safety control" },
      });
      return new Response(
        JSON.stringify({
          ok: false,
          error: globalSafety.reason ?? "Unlock temporarily disabled by system safety control.",
        }),
        {
          status: 503,
          headers: { "Content-Type": "application/json" },
        },
      );
    }
    const clientIp = extractClientIp(req);

    if (payload.action === "request_code" || payload.action === "request_code_manual") {
      await enforceRateLimit("request_code_by_ip", clientIp, 12, 15, 30);
      await enforceRateLimit("request_code_by_access_id", payload.access_id, 4, 15, 30);
      if (payload.action === "request_code_manual") {
        await enforceRateLimit("request_code_manual_by_ip", clientIp, 4, 15, 30);
        await enforceRateLimit("request_code_manual_by_access_id", payload.access_id, 2, 15, 30);
      }
      const result = await requestCode(
        payload.access_id,
        payload.access_key,
        payload.action === "request_code_manual",
      );
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (payload.action === "unlock") {
      if (!payload.verification_code) throw new Error("Missing verification_code.");
      await enforceRateLimit("unlock_by_ip", clientIp, 25, 15, 30);
      await enforceRateLimit("unlock_by_access_id", payload.access_id, 10, 15, 30);
      const result = await unlock(
        payload.access_id,
        payload.access_key,
        payload.verification_code,
        payload.totp_code,
        payload.beneficiary_name,
        payload.verification_phrase,
      );
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (payload.action === "report_wrong_recipient") {
      await enforceRateLimit("wrong_recipient_by_ip", clientIp, 8, 15, 30);
      await enforceRateLimit("wrong_recipient_by_access_id", payload.access_id, 3, 15, 30);
      const result = await reportWrongRecipient(payload.access_id, payload.access_key, clientIp);
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: false, error: "Unsupported action." }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    try {
      await logSecurityEvent({
        eventType: "unlock_error",
        severity: "warn",
        actorScope: "request",
        details: { error: String(error) },
      });
    } catch (_) {
      // best effort only
    }
    return new Response(JSON.stringify({ ok: false, error: String(error) }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
