# Self-Host Scaffold

This folder provides a private self-host starter stack:

1. Postgres
2. API process (`selfhost/services/api_server.py`)
3. Worker process (`selfhost/services/worker_loop.py`)

## Start locally

```powershell
cd selfhost
docker compose -f docker-compose.selfhost.yml up -d
```

Health check:

```powershell
curl http://localhost:8080/health
```

## Why this exists

1. Reduce hard dependency on managed runtime
2. Allow technically advanced users to run private infrastructure
3. Create a migration path from hosted mode to full self-host

## Current scope

This is a first scaffold:

1. API and worker are intentionally minimal
2. Core adapter interface exists in `selfhost/core/dispatch_engine.py`
3. Next step is wiring DB adapter + PTN evaluator into worker loop
