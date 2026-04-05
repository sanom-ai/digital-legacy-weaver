# App Release Pack (APK + Windows ZIP)

## What this gives you

Single workflow to produce:

1. Android release APK
2. Windows release ZIP
3. GitHub Release with downloadable assets

## Workflow

File:

1. `.github/workflows/app-release.yml`

Run from GitHub Actions:

1. Open `App Release Pack`
2. Input `tag` (example: `v0.1.0`)
3. Set `prerelease` (`true` for beta)
4. Click `Run workflow`

## Expected output

In GitHub Releases for the selected tag:

1. `app-release.apk`
2. `digital-legacy-weaver-windows.zip`

## Notes

1. Workflow bootstraps missing Flutter platform folders automatically.
2. Release notes are generated automatically in the workflow.
3. This app is a technical coordination layer and does not replace legal will procedures.
