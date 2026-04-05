import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Action = "review" | "summary" | "queue";

type RequestPayload = {
  action: Action;
  evidence_id?: string;
  reviewer_ref?: string;
  decision?: "approved" | "rejected" | "needs_info";
  notes?: string;
  status?: "submitted" | "under_review" | "verified" | "rejected";
  limit?: number;
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
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

type ReviewerPrincipal = {
  reviewerRef: string;
  role: "reviewer" | "admin";
};

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
    const expiresAt = data.expires_at ? new Date(String(data.expires_at)).getTime() : 0;
    if (!expiresAt || expiresAt > Date.now()) {
      return {
        reviewerRef: String(data.reviewer_ref),
        role: String(data.role) === "admin" ? "admin" : "reviewer",
      };
    }
  }

  // Backward-compatible fallback during transition.
  if (REVIEWER_API_KEY && rawKey === REVIEWER_API_KEY) {
    return { reviewerRef: "legacy-shared-reviewer-key", role: "admin" };
  }
  return null;
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") return json({ ok: false, error: "Use POST." }, 405);
    const principal = await resolvePrincipal(req);
    if (!principal) return json({ ok: false, error: "Reviewer authorization failed." }, 401);

    const payload = (await req.json()) as RequestPayload;
    if (!payload?.action) return json({ ok: false, error: "Missing action." }, 400);

    if (payload.action === "review") {
      const evidenceId = (payload.evidence_id ?? "").trim();
      const reviewerRef = (payload.reviewer_ref ?? principal.reviewerRef).trim();
      const decision = payload.decision;
      if (!evidenceId || !reviewerRef || !decision) {
        return json({ ok: false, error: "Missing required review fields." }, 400);
      }

      const { data, error } = await supabase.rpc("apply_legal_evidence_review", {
        p_evidence_id: evidenceId,
        p_reviewer_ref: reviewerRef,
        p_decision: decision,
        p_notes: payload.notes ?? null,
      });
      if (error) throw new Error(error.message);

      const row = Array.isArray(data) && data.length > 0 ? data[0] : {};
      return json({
        ok: true,
        evidence_id: evidenceId,
        reviewer_ref: reviewerRef,
        review_status: row.review_status ?? "under_review",
        approvals: row.approvals ?? 0,
        rejections: row.rejections ?? 0,
      });
    }

    if (payload.action === "summary") {
      const evidenceId = (payload.evidence_id ?? "").trim();
      if (!evidenceId) return json({ ok: false, error: "Missing evidence_id." }, 400);

      const { data: evidence, error: evidenceError } = await supabase
        .from("legal_evidence_records")
        .select("id, owner_id, document_type, review_status, reviewed_by, reviewed_at, review_notes")
        .eq("id", evidenceId)
        .maybeSingle();
      if (evidenceError) throw new Error(evidenceError.message);
      if (!evidence) return json({ ok: false, error: "Evidence not found." }, 404);

      const { data: reviews, error: reviewError } = await supabase
        .from("legal_evidence_reviews")
        .select("reviewer_ref, decision, notes, reviewed_at")
        .eq("evidence_id", evidenceId)
        .order("reviewed_at", { ascending: false });
      if (reviewError) throw new Error(reviewError.message);

      return json({
        ok: true,
        evidence,
        reviews: reviews ?? [],
      });
    }

    if (payload.action === "queue") {
      const status = payload.status ?? "under_review";
      const limit = Math.max(1, Math.min(Number(payload.limit ?? 50), 200));
      const { data, error } = await supabase
        .from("legal_evidence_records")
        .select("id, owner_id, document_type, review_status, issuer_country, created_at, updated_at, reviewed_by, reviewed_at")
        .eq("review_status", status)
        .order("updated_at", { ascending: true })
        .limit(limit);
      if (error) throw new Error(error.message);

      const rows = data ?? [];
      const evidenceIds = rows.map((row) => String(row.id)).filter((id) => id.length > 0);
      const countsByEvidence: Record<string, { approvals: number; rejections: number; needs_info: number }> = {};
      if (evidenceIds.length > 0) {
        const { data: decisions, error: decisionsError } = await supabase
          .from("legal_evidence_reviews")
          .select("evidence_id, decision")
          .in("evidence_id", evidenceIds);
        if (decisionsError) throw new Error(decisionsError.message);
        for (const row of decisions ?? []) {
          const evidenceId = String(row.evidence_id);
          if (!countsByEvidence[evidenceId]) {
            countsByEvidence[evidenceId] = { approvals: 0, rejections: 0, needs_info: 0 };
          }
          const decision = String(row.decision);
          if (decision === "approved") countsByEvidence[evidenceId].approvals += 1;
          if (decision === "rejected") countsByEvidence[evidenceId].rejections += 1;
          if (decision === "needs_info") countsByEvidence[evidenceId].needs_info += 1;
        }
      }

      const queue = rows.map((row) => {
        const key = String(row.id);
        const counts = countsByEvidence[key] ?? { approvals: 0, rejections: 0, needs_info: 0 };
        return {
          ...row,
          approvals: counts.approvals,
          rejections: counts.rejections,
          needs_info_count: counts.needs_info,
        };
      });

      return json({
        ok: true,
        status,
        count: queue.length,
        queue,
      });
    }

    return json({ ok: false, error: "Unsupported action." }, 400);
  } catch (error) {
    return json({ ok: false, error: String(error) }, 400);
  }
});
