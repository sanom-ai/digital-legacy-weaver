import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Action = "status" | "begin_setup" | "confirm_setup" | "disable";

type RequestPayload = {
  action: Action;
  totp_code?: string;
  require_totp_unlock?: boolean;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const ISSUER = "Digital Legacy Weaver";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function randomBase32Secret(length = 32): string {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  const bytes = crypto.getRandomValues(new Uint8Array(length));
  let out = "";
  for (let i = 0; i < length; i++) {
    out += alphabet[bytes[i] % alphabet.length];
  }
  return out;
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
  for (const windowOffset of [-1, 0, 1]) {
    const candidate = await generateTotpCode(secretBase32, digits, periodSeconds, now + windowOffset * periodSeconds * 1000);
    if (candidate === provided) return true;
  }
  return false;
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") return json({ ok: false, error: "Use POST." }, 405);
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ ok: false, error: "Missing Authorization header." }, 401);

    const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userError,
    } = await client.auth.getUser();
    if (userError || !user) return json({ ok: false, error: "Authentication required." }, 401);

    const payload = (await req.json()) as RequestPayload;
    if (!payload?.action) return json({ ok: false, error: "Missing action." }, 400);

    if (payload.action === "status") {
      const { data: factor, error: factorError } = await client
        .from("user_totp_factors")
        .select("enabled")
        .eq("owner_id", user.id)
        .maybeSingle();
      if (factorError) throw new Error(factorError.message);

      const { data: settings, error: settingsError } = await client
        .from("user_safety_settings")
        .select("require_totp_unlock")
        .eq("owner_id", user.id)
        .maybeSingle();
      if (settingsError) throw new Error(settingsError.message);

      return json({
        ok: true,
        configured: factor != null,
        enabled: Boolean(factor?.enabled),
        require_totp_unlock: Boolean(settings?.require_totp_unlock),
      });
    }

    if (payload.action === "begin_setup") {
      const secretBase32 = randomBase32Secret(32);
      const accountLabel = user.email ?? user.id;
      const otpauthUri =
        `otpauth://totp/${encodeURIComponent(`${ISSUER}:${accountLabel}`)}` +
        `?secret=${secretBase32}&issuer=${encodeURIComponent(ISSUER)}&algorithm=SHA1&digits=6&period=30`;

      const { error } = await client.from("user_totp_factors").upsert({
        owner_id: user.id,
        secret_base32: secretBase32,
        digits: 6,
        period_seconds: 30,
        algorithm: "SHA1",
        enabled: false,
        confirmed_at: null,
      });
      if (error) throw new Error(error.message);

      return json({
        ok: true,
        configured: true,
        enabled: false,
        require_totp_unlock: false,
        secret_base32: secretBase32,
        otpauth_uri: otpauthUri,
      });
    }

    if (payload.action === "confirm_setup") {
      const totpCode = (payload.totp_code ?? "").trim();
      if (!/^\d{6,8}$/.test(totpCode)) {
        return json({ ok: false, error: "Invalid totp_code format." }, 400);
      }

      const { data: factor, error: factorError } = await client
        .from("user_totp_factors")
        .select("secret_base32, digits, period_seconds")
        .eq("owner_id", user.id)
        .single();
      if (factorError || !factor) throw new Error(`TOTP factor not initialized: ${factorError?.message ?? "missing"}`);

      const isValid = await verifyTotpCode(
        factor.secret_base32 as string,
        Number(factor.digits ?? 6),
        Number(factor.period_seconds ?? 30),
        totpCode,
      );
      if (!isValid) {
        return json({ ok: false, error: "Invalid TOTP code." }, 400);
      }

      const { error: enableError } = await client
        .from("user_totp_factors")
        .update({ enabled: true, confirmed_at: new Date().toISOString() })
        .eq("owner_id", user.id);
      if (enableError) throw new Error(enableError.message);

      const requireTotpUnlock = payload.require_totp_unlock ?? true;
      const { error: settingsError } = await client.from("user_safety_settings").upsert({
        owner_id: user.id,
        require_totp_unlock: requireTotpUnlock,
      });
      if (settingsError) throw new Error(settingsError.message);

      return json({
        ok: true,
        configured: true,
        enabled: true,
        require_totp_unlock: requireTotpUnlock,
      });
    }

    if (payload.action === "disable") {
      const { error: disableFactorError } = await client
        .from("user_totp_factors")
        .update({ enabled: false, confirmed_at: null })
        .eq("owner_id", user.id);
      if (disableFactorError) throw new Error(disableFactorError.message);

      const { error: disableSettingError } = await client
        .from("user_safety_settings")
        .update({ require_totp_unlock: false })
        .eq("owner_id", user.id);
      if (disableSettingError) throw new Error(disableSettingError.message);

      return json({
        ok: true,
        configured: true,
        enabled: false,
        require_totp_unlock: false,
      });
    }

    return json({ ok: false, error: "Unsupported action." }, 400);
  } catch (error) {
    return json({ ok: false, error: String(error) }, 400);
  }
});
