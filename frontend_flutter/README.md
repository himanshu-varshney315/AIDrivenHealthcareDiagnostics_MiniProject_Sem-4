# frontend_flutter

Flutter client for the healthcare diagnostics project.

## Features

- Splash, login, and signup flow
- Dashboard and profile screens
- PDF, TXT, PNG, and JPG medical report selection and upload
- Backend API integration for authentication and report analysis
- In-app notification timeline for analysis status and high-priority results
- Clinics lookup with Google Maps and Google Places

## Run

```bash
flutter pub get
flutter run
```

## API Base URL

The app uses:

- `http://10.0.2.2:5000` on Android emulator
- `http://127.0.0.1:5000` on web and desktop

Override with:

```bash
flutter run --dart-define=API_BASE_URL=http://your-server:5000
```

## Clinics Map Setup

The `Clinics` tab uses Google Maps + Google Places to show nearby clinics and directions.

### 1. Enable APIs

Enable these APIs in your Google Cloud project:

- Maps SDK for Android
- Maps SDK for iOS
- Places API

### 2. Add the API key for Android maps

Edit `android/local.properties` and add:

```properties
MAPS_RUNTIME_KEY=your_google_maps_api_key
```

### 3. Add the API key for iOS maps

Edit both `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig`, then add:

```xcconfig
MAPS_RUNTIME_KEY=your_google_maps_api_key
```

### 4. Pass the key to Flutter for Places API requests

Run the app with:

```bash
flutter run --dart-define=MAPS_RUNTIME_KEY=your_google_maps_api_key
```
