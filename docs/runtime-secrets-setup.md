# Runtime Secrets Setup (Production)

Use this guide before running:

```powershell
.\scripts\deploy_production.ps1 -ProjectRef <your_project_ref>
```

## 1) Secrets and where to get each value

| Secret | Where to get it | Notes |
|---|---|---|
| `SUPABASE_URL` | Supabase Project URL (`https://<project_ref>.supabase.co`) | Project Settings -> API Keys |
| `SUPABASE_ANON_KEY` | Publishable/anon key | Use client-safe key only |
| `SUPABASE_SERVICE_ROLE_KEY` | Secret key (`sb_secret_...`) | Do not use legacy JWT key |
| `SUPABASE_ACCESS_TOKEN` | Supabase Account -> Access Tokens | Used by CLI (`supabase login`) |
| `DELIVERY_BASE_URL` | Your app unlock endpoint base URL | Example: `https://app.example.com/unlock` |
| `HANDOFF_INTERNAL_KEY` | Generate random high-entropy secret | Internal auth between functions |
| `REVIEWER_API_KEY` | Generate random high-entropy secret | Reviewer operation key |
| `REVIEWER_ADMIN_API_KEY` | Generate random high-entropy secret | Admin reviewer key rotation/listing |
| `RESEND_API_KEY` | Resend dashboard | Optional if using SendGrid |
| `SENDGRID_API_KEY` | SendGrid dashboard | Optional if using Resend |
| `OPENAI_API_KEY` | OpenAI platform key | Optional for AI ops natural-language analysis |
| `AI_OPS_MODEL` | GitHub repository variable | Optional, defaults to `gpt-4o-mini` |
| `HANDOFF_PROVIDER_WEBHOOK_URL` | Partner backend endpoint | Optional |
| `HANDOFF_SIGNING_SECRET` | Shared secret with webhook target | Optional but recommended |

## 2) Generate internal keys (PowerShell)

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }))
```

Run this command 3 times for:

1. `HANDOFF_INTERNAL_KEY`
2. `REVIEWER_API_KEY`
3. `REVIEWER_ADMIN_API_KEY`

## 3) Set local environment (current shell session)

```powershell
$env:SUPABASE_URL="https://<project_ref>.supabase.co"
$env:SUPABASE_ANON_KEY="<anon_or_publishable_key>"
$env:SUPABASE_SERVICE_ROLE_KEY="<sb_secret_key>"
$env:DELIVERY_BASE_URL="https://app.example.com/unlock"
$env:HANDOFF_INTERNAL_KEY="<generated_secret>"
$env:REVIEWER_API_KEY="<generated_secret>"
$env:REVIEWER_ADMIN_API_KEY="<generated_secret>"
$env:RESEND_API_KEY="<resend_key>"   # or set SENDGRID_API_KEY instead
$env:SENDGRID_API_KEY=""             # optional fallback
```

## 4) Set GitHub Actions secrets (production repo)

Repository Settings -> Secrets and variables -> Actions:

1. `SUPABASE_URL`
2. `SUPABASE_ANON_KEY`
3. `SUPABASE_SERVICE_ROLE_KEY`
4. `SUPABASE_ACCESS_TOKEN`
5. `SUPABASE_PROJECT_REF`

If CI deploy/runtime jobs need them, also add:

1. `DELIVERY_BASE_URL`
2. `HANDOFF_INTERNAL_KEY`
3. `REVIEWER_API_KEY`
4. `REVIEWER_ADMIN_API_KEY`
5. `RESEND_API_KEY` and/or `SENDGRID_API_KEY`
6. `OPENAI_API_KEY` (for `Runtime Dispatch AI Ops` workflow)

Repository variable:

1. `AI_OPS_MODEL` (optional, example: `gpt-4o-mini`)

## 5) Verify before deploy

```powershell
python tools/release_gate_preflight.py --max-age-days 30
.\scripts\deploy_production.ps1 -ProjectRef <your_project_ref> -SkipDbPush
.\scripts\post_deploy_smoke.ps1 -ProjectRef <your_project_ref>
```

## 6) Rotation policy (recommended)

1. Rotate `SUPABASE_ACCESS_TOKEN` if ever shared.
2. Rotate `SUPABASE_SERVICE_ROLE_KEY` if leaked.
3. Rotate internal keys (`HANDOFF_INTERNAL_KEY`, reviewer keys) every 90 days.
4. Update local + GitHub secrets together, then run smoke checks.
