# App Release Pack (AAB/APK + Windows ZIP)

## What this gives you

Single workflow to produce:

1. Android release AAB (for Play Console)
2. Android release APK (direct sideload/testing)
3. Windows release ZIP
4. GitHub Release with downloadable assets

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

1. `app-release.aab`
2. `app-release.apk`
3. `digital-legacy-weaver-windows.zip`

## Notes

1. Workflow bootstraps missing Flutter platform folders automatically.
2. Release notes are generated automatically in the workflow.
3. This app is a technical coordination layer and does not replace legal will procedures.
4. `app-release.aab` is the package for Play Store submission.
