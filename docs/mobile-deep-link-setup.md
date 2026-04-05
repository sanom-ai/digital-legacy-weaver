# Mobile Deep Link Setup (`legacyweaver://unlock`)

Current repository has Flutter app code, but native platform folders may not exist yet.
If `android/` and `ios/` are missing, run in app directory:

```powershell
cd apps/flutter_app
flutter create .
```

Then apply native deep-link config below.

Quick apply script:

```powershell
.\scripts\apply_mobile_deeplink.ps1
```

The script patches AndroidManifest and Info.plist automatically when native folders exist.

## Android

1. Open `android/app/src/main/AndroidManifest.xml`
2. Inside `<activity android:name=".MainActivity" ...>`, add snippet from:
- `apps/flutter_app/native/android/AndroidManifest.deep-link.xml`

## iOS

1. Open `ios/Runner/Info.plist`
2. Add snippet from:
- `apps/flutter_app/native/ios/Info.plist.deep-link.xml`

## Test cases

1. Open app with:
- `legacyweaver://unlock?access_id=<id>&access_key=<key>`
2. App should navigate to Unlock flow and prefill `access_id` and `access_key`
3. Request verification code and unlock bundle
