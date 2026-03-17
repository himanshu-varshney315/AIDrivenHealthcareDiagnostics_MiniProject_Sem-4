# frontend_flutter

Flutter client for the healthcare app.

## Clinics Map Setup

The `Clinics` tab now uses Google Maps + Google Places to show nearby clinics and directions.

### 1. Enable APIs

Enable these APIs in your Google Cloud project:

- Maps SDK for Android
- Maps SDK for iOS
- Places API

### 2. Add the API key for Android maps

Edit [android/local.properties](/d:/Gla/Sem%20IV/Mini/frontend_flutter/android/local.properties) and add:

```properties
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 3. Add the API key for iOS maps

Edit both:

- [Debug.xcconfig](/d:/Gla/Sem%20IV/Mini/frontend_flutter/ios/Flutter/Debug.xcconfig)
- [Release.xcconfig](/d:/Gla/Sem%20IV/Mini/frontend_flutter/ios/Flutter/Release.xcconfig)

Add:

```xcconfig
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 4. Pass the key to Flutter for Places API requests

Run the app with:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```
