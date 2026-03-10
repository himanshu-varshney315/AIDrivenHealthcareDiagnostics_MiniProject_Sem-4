# Frontend Flutter

Flutter client for the healthcare diagnostics project.

## Features

- Splash, login, and signup flow
- Dashboard and profile screens
- PDF medical report selection and upload
- Backend API integration for authentication and report analysis

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
