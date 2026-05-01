# AI-Driven Healthcare Diagnostics

This project combines a Flutter frontend, a Flask backend, and an ML-assisted analysis service for medical report review and symptom-based health guidance. Users can sign up, log in, upload PDF/TXT/image reports, analyze typed symptoms, receive in-app status notifications, and review trends from recent analyses.

## What Improved From Feedback

- Added stronger backend structure with an app factory to support testing
- Added backend tests for signup/login, symptom analysis, and admin authorization
- Added an admin-only analytics endpoint for report overview data
- Improved report result presentation with explainable AI bars, trend summaries, and care guidance
- Confirmed no hardcoded mobile map secret is stored in the repo
- Expanded setup and testing documentation

## Project Structure

```text
Mini/
|-- backend/              Flask API, auth, report routes, services, tests
|-- frontend_flutter/     Flutter application
|-- Ml_model/             ML and heuristic analysis service
|-- Assets/               UI assets
`-- README.md
```

Additional docs:

- `backend/README.md` for backend architecture, routes, security, and tests
- `Ml_model/README.md` for the ML service, training, and inference flow

## Core Features

- User signup and login with password hashing and JWT auth
- PDF medical report upload and text extraction
- TXT and image report upload with OCR support when Tesseract is available
- Symptom text analysis
- In-app notification timeline for analysis status and high-urgency alerts
- Trend summaries from recent analyses
- Explainable result cards with confidence and probability views
- Role-aware backend claims with admin-only overview access
- Rate limiting, input validation, CORS, and security headers

## Architecture Overview

The system is split into three runtime pieces:

1. Flutter frontend
   Handles authentication, report upload, symptom entry, and result visualization.
2. Flask backend
   Manages users, JWT auth, request validation, persistence, trend summaries, and secure routing.
3. ML service
   Extracts PDF text, scores report/symptom input, and returns structured analysis output.

Typical request flow:

1. A user logs in from Flutter and receives a JWT from the backend.
2. Flutter sends the JWT with report uploads or symptom analysis requests.
3. The backend validates the request and forwards analysis work to the ML service.
4. The backend stores the result, computes history/trend summaries, and returns a structured response.
5. Flutter renders prediction, confidence, urgency, explanation, and trend insights.

## Run Locally

Open three terminals if you want the full stack. All commands below can be run from the project root.

### 1. Install dependencies

```powershell
.\.venv\Scripts\python.exe -m pip install -r backend/requirements.txt
.\.venv\Scripts\python.exe -m pip install -r Ml_model/requirements.txt
```

### 2. Start the ML analysis service

```powershell
.\.venv\Scripts\python.exe -m Ml_model.app
```

The ML API runs on `http://127.0.0.1:5001`.

### 3. Start the backend API

```powershell
.\.venv\Scripts\python.exe backend/app.py
```

The backend runs on `http://127.0.0.1:5000`.

### 4. Start the Flutter app

```powershell
cd frontend_flutter
flutter pub get
flutter run
```

Default API base URLs:

- Android emulator: `http://10.0.2.2:5000`
- Windows/Web/local desktop: `http://127.0.0.1:5000`

You can override the Flutter base URL with:

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

## Environment Setup

Copy `.env.example` when you need local environment variables. Keep real `.env` files uncommitted.

Important values:

- `JWT_SECRET_KEY`: required for production; local development can generate one automatically.
- `MAX_UPLOAD_BYTES`: default upload limit is `10485760`.
- `CORS_ORIGINS`: comma-separated browser origins allowed to call the backend.
- `ML_API_URL` and `ML_SYMPTOM_API_URL`: backend-to-ML service endpoints.
- `API_BASE_URL`: Flutter `--dart-define` value for the backend URL.
- `MAPS_RUNTIME_KEY`: build-time placeholder only; no real Google or AWS key belongs in committed config.

## Docker

Build and start the backend and ML service:

```powershell
docker compose build
docker compose up
```

Default compose URLs:

- Backend: `http://127.0.0.1:5000`
- ML service: `http://127.0.0.1:5001`

The backend container calls the ML container through `http://ml:5001`.

## Security Notes

- JWT secrets should come from environment variables in production
- For local development, the backend generates and reuses `instance/.jwt_secret`
- The mobile map key uses `MAPS_RUNTIME_KEY` build-time indirection, so the repo does not store a real API key value
- Auth routes and analysis routes use rate limiting
- User input is normalized and validated before processing
- CSRF protection is not used because the app uses bearer-token JSON APIs rather than cookie/session auth. Do not add cookie-based auth unless CSRF protection is added at the same time.

## API Endpoints

- `POST /signup`
- `POST /login`
- `POST /upload-report`
- `POST /analyze-symptoms`
- `GET /reports/history`
- `GET /reports/overview`
  Requires JWT with `role=admin`

For request/response expectations and backend internals, see `backend/README.md`.

## Testing

Backend tests:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s backend/tests
```

Flutter checks:

```powershell
cd frontend_flutter
flutter analyze
flutter test
```

ML smoke checks:

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s Ml_model/tests
```

Python lint:

```powershell
.\.venv\Scripts\python.exe -m ruff check backend Ml_model
```

CI runs backend tests, ML smoke tests, Python lint, `flutter analyze`, and `flutter test` through `.github/workflows/ci.yml`.

## Notes

- The ML service can fall back to heuristic analysis when optional model artifacts or some ML packages are missing
- Report upload supports PDF, TXT, PNG, JPG, and JPEG input; image/scanned extraction requires local OCR support
- The admin overview endpoint is ready for future dashboard/admin UI expansion
- Local development uses SQLite for simplicity
- Backend runtime data now lives consistently under `backend/instance/`
- In production, set `DATABASE_URL` to a managed Postgres or MySQL database to avoid ephemeral SQLite storage
- Training writes model lifecycle metadata to `Ml_model/models/metrics.json`

## Known Limitations

- This is diagnosis-support software for education/demo workflows, not a replacement for clinician review.
- Rate limiting is process-local and should be replaced with Redis or gateway-level throttling for production.
- SQLite is suitable for local development but not the intended production database.
- Image-only disease prediction requires a local labeled dataset and trained image artifact.

## Contributors

- Aditya Pratap
- Himanshu Gupta
- Piyush Kumar
