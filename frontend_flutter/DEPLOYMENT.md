# Ayuva Mobile Deployment

## Android

1. Deploy the backend to an HTTPS URL.
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Generate a private release keystore:

   ```powershell
   cd frontend_flutter/android
   keytool -genkey -v -keystore ayuva-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ayuva
   ```

4. Fill `android/key.properties` with the keystore passwords.
5. Build the Play Store bundle:

   ```powershell
   cd frontend_flutter
   flutter build appbundle --release --dart-define=API_BASE_URL=https://your-backend-domain.com
   ```

6. Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.

For manual phone testing, build an APK instead:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://your-backend-domain.com
```

## Required Local Files

These files are intentionally ignored by Git:

- `android/key.properties`
- `android/*.jks`
- `android/*.keystore`

Keep the keystore safe. Losing it can prevent future updates to the Play Store app.

## Notes

- Debug builds allow HTTP so local emulator development still works.
- Release builds disable cleartext traffic, so use an HTTPS backend URL.
- The Android application id is `com.ayuva.health`.
