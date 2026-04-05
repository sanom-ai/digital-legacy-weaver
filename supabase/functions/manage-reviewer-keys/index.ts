import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Action = "list_keys" | "add_key" | "deactivate_key";

type RequestPayload = {
  action: Action;
  key_plaintext?: string;
  reviewer_ref?: string;
  role?: "reviewer" | "admin";
  label?: string;
  expires_at?: string;
  key_id?: string;
  rotated_from?: string;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const REVIEWER_ADMIN_API_KEY = Deno.env.get("REVIEWER_ADMIN_API_KEY");

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function isAdminAuthorized(req: Request): boolean {
  if (!REVIEWER_ADMIN_API_KEY) return false;
  const key = req.headers.get("x-reviewer-admin-key")?.trim();
  return Boolean(key && key === REVIEWER_ADMIN_API_KEY);
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") return json({ ok: false, error: "Use POST." }, 405);
    if (!isAdminAuthorized(req)) return json({ ok: false, error: "Reviewer admin authorization failed." }, 401);

    const payload = (await req.json()) as RequestPayload;
    if (!payload?.action) return json({ ok: false, error: "Missing action." }, 400);

    if (payload.action === "list_keys") {
      const { data, error } = await supabase
        .from("reviewer_api_keys")
        .select("id, reviewer_ref, role, label, is_active, expires_at, rotated_from, created_by, created_at, updated_at")
        .order("created_at", { ascending: false });
      if (error) throw new Error(error.message);
      return json({ ok: true, keys: data ?? [] });
    }

    if (payload.action === "add_key") {
      const keyPlaintext = (payload.key_plaintext ?? "").trim();
      const reviewerRef = (payload.reviewer_ref ?? "").trim();
      const role = payload.role ?? "reviewer";
      const label = (payload.label ?? "").trim();
      if (!keyPlaintext || !reviewerRef || !label) {
        return json({ ok: false, error: "Missing add_key fields." }, 400);
      }
      const keyHash = await sha256Hex(keyPlaintext);
      const { data, error } = await supabase
        .from("reviewer_api_keys")
        .insert({
          key_hash: keyHash,
          reviewer_ref: reviewerRef,
          role,
          label,
          expires_at: payload.expires_at ?? null,
          rotated_from: payload.rotated_from ?? null,
          created_by: "reviewer-admin-api",
          is_active: true,
        })
        .select("id, reviewer_ref, role, label, is_active, expires_at, rotated_from, created_by, created_at, updated_at")
        .single();
      if (error) throw new Error(error.message);
      return json({ ok: true, key: data });
    }

    if (payload.action === "deactivate_key") {
      const keyId = (payload.key_id ?? "").trim();
      if (!keyId) return json({ ok: false, error: "Missing key_id." }, 400);
      const { data, error } = await supabase
        .from("reviewer_api_keys")
        .update({ is_active: false })
        .eq("id", keyId)
        .select("id, reviewer_ref, role, label, is_active, expires_at, rotated_from, created_by, created_at, updated_at")
        .single();
      if (error) throw new Error(error.message);
      return json({ ok: true, key: data });
    }

    return json({ ok: false, error: "Unsupported action." }, 400);
  } catch (error) {
    return json({ ok: false, error: String(error) }, 400);
  }
});
