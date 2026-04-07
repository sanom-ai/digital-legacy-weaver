# Store Readiness Pack (Android)

Use this checklist before uploading to Google Play Console.

## 1) Build Outputs

1. Release workflow produced `app-release.aab`
2. Release workflow produced `app-release.apk`
3. Tag release includes both artifacts in GitHub Releases

## 2) Security and Privacy

1. Data Safety form prepared for Play Console
2. Privacy Policy URL is published and reachable
3. App does not request or process wallet seed phrases, private keys, or transfer instructions in plaintext
4. Recipient flow warning text is present: app never asks for money transfer or passwords through message links

## 3) Store Metadata

1. App name and short description are final
2. Full description reflects technical coordination role and legal disclaimer
3. At least 2 phone screenshots and 1 tablet screenshot are prepared
4. Feature graphic and app icon are finalized

## 4) Runtime Safety

1. `dispatch-trigger` heartbeat is healthy
2. `open-delivery-link` is enabled and returns live delivery context
3. Global safety controls (`dispatch_enabled`, `unlock_enabled`) are documented for incident response

## 5) Final Gate

Run:

```powershell
python tools/release_gate_preflight.py --max-age-days 30
```

Upload only when all checks above are complete.
