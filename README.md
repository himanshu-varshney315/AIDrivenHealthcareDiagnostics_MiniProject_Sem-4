# AI-Driven Healthcare Diagnostics

This project combines a Flutter frontend with a Flask backend for healthcare report intake and rule-based risk analysis. Users can sign up, log in, upload PDF medical reports, and receive a simple risk classification with extracted risk factors.

## Current Scope

- Flutter app for signup, login, dashboard, profile, and PDF report upload
- Flask API with SQLite-based user storage
- PDF text extraction using PyMuPDF
- Rule-based health risk analysis from extracted report text

## Project Structure

```text
Mini/
|-- backend/              Flask API, database, routes, services
|-- frontend_flutter/     Flutter application
|-- Assets/               Design assets
|-- healthcare_ai.py      Standalone ML experiment script
|-- healthcare_dataset - Sheet1.csv
`-- README.md
```

## Backend

Key endpoints:

- `POST /signup`
- `POST /login`
- `POST /upload-report`

Run locally:

```bash
cd backend
pip install -r requirements.txt
python app.py
```

The API runs on `http://127.0.0.1:5000` by default.

Set a stronger JWT secret in production:

```bash
set JWT_SECRET_KEY=replace-with-a-long-random-secret
python app.py
```

## Frontend

Run locally:

```bash
cd frontend_flutter
flutter pub get
flutter run
```

Default API base URLs:

- Android emulator: `http://10.0.2.2:5000`
- Windows/Web/local desktop: `http://127.0.0.1:5000`

You can override this at build or run time with `--dart-define=API_BASE_URL=...`.

## Validation

The project was checked with:

- `flutter analyze`
- `flutter test`
- `python -m compileall backend healthcare_ai.py`
- Flask smoke tests for signup, login, and upload validation

## Notes

- `healthcare_ai.py` is a separate experimental script and is not wired into the Flask API.
- The backend currently uses a local SQLite database file for development.

## Contributors

- Aditya Pratap
- Himanshu Gupta
- Piyush Kumar
