# Backend Documentation

This backend is a Flask API for authentication, medical report analysis requests, symptom analysis, and user-specific analysis history.

## Responsibilities

- Register and authenticate users
- Issue JWT access tokens
- Accept PDF uploads and typed symptom input
- Forward analysis work to the ML service
- Persist analysis history in SQLite
- Build trend summaries from recent analyses
- Protect endpoints with rate limiting, JWT auth, and role-aware authorization

## Folder Layout

```text
backend/
|-- app.py                     App factory and Flask bootstrap
|-- config.py                  JWT secret loading and environment-based config
|-- requirements.txt           Backend Python dependencies
|-- database/
|   `-- db.py                  SQLAlchemy instance
|-- models/
|   |-- user_model.py          User table
|   `-- report_analysis_model.py
|                              Stored analysis records
|-- routes/
|   |-- auth_routes.py         Signup and login endpoints
|   `-- report_routes.py       Report upload, symptoms, history, admin overview
|-- services/
|   |-- app_bootstrap.py       CORS, headers, DB initialization
|   |-- auth_management.py     Validation, hashing, token response logic
|   |-- report_analysis_service.py
|   |                          ML API forwarding, persistence, trend building
|   `-- security.py            Rate limiting, sanitization, role checks
`-- tests/
    `-- test_api.py            Backend smoke and authorization tests
```

## Entry Point

The backend entry point is [app.py](d:/Gla/Sem IV/Mini/backend/app.py).

It exposes `create_app()` so the API can be used both in local runtime and in tests.

## Run Locally

From the project root:

```powershell
pip install -r backend/requirements.txt
cd backend
python app.py
```

Default backend URL:

```text
http://127.0.0.1:5000
```

The ML service must also be running:

```powershell
python -m Ml_model.app
```

## Configuration

Environment variables supported by the backend:

- `JWT_SECRET_KEY`
  Required in production. If missing in local development, a secret is generated and stored in `instance/.jwt_secret`.
- `MAX_UPLOAD_BYTES`
  Maximum allowed upload size. Default is `10485760` bytes (10 MB).
- `CORS_ORIGINS`
  Comma-separated allowed origins for cross-origin requests.
- `FLASK_ENV`
  If set to `production`, the backend requires an explicit `JWT_SECRET_KEY`.

Example local env file:

```text
JWT_SECRET_KEY=replace-with-a-long-random-secret
MAX_UPLOAD_BYTES=10485760
CORS_ORIGINS=http://127.0.0.1:5000,http://localhost:5000
```

## Data Model

### User

Fields:

- `id`
- `name`
- `email`
- `password`
- `role`

Current roles:

- `user`
- `admin`

### ReportAnalysis

Fields:

- `id`
- `user_id`
- `source_type`
- `source_name`
- `prediction`
- `confidence`
- `urgency`
- `extracted_symptoms_json`
- `recommendations_json`
- `precautions_json`
- `explanation`
- `created_at`

## API Endpoints

### `POST /signup`

Creates a new user.

Request body:

```json
{
  "name": "Test User",
  "email": "test@example.com",
  "password": "password123"
}
```

Success response:

```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "name": "Test User",
    "email": "test@example.com",
    "role": "user"
  }
}
```

### `POST /login`

Authenticates a user and returns a JWT.

Request body:

```json
{
  "email": "test@example.com",
  "password": "password123"
}
```

Success response:

```json
{
  "message": "Login successful",
  "token": "jwt-token",
  "user": {
    "id": 1,
    "name": "Test User",
    "email": "test@example.com",
    "role": "user"
  }
}
```

### `POST /upload-report`

Requires `Authorization: Bearer <token>`.

Consumes multipart form-data:

- `file`: PDF report

The backend validates the file, forwards it to the ML service, stores the result, and returns analysis data plus trend context.

### `POST /analyze-symptoms`

Requires `Authorization: Bearer <token>`.

Request body:

```json
{
  "symptoms_text": "fever and cough for two days"
}
```

Returns:

- prediction
- confidence
- urgency
- explanation
- extracted symptoms
- recommendations
- precautions
- trend summary

### `GET /reports/history`

Requires `Authorization: Bearer <token>`.

Optional query param:

- `limit`

Returns recent analyses for the logged-in user plus trend summary data.

### `GET /reports/overview`

Requires `Authorization: Bearer <token>` with `role=admin`.

Optional query param:

- `limit`

Returns:

- total users
- total analyses
- high urgency count
- source breakdown
- top predictions
- recent analyses

## Security Measures

Implemented protections:

- Password hashing with `flask-bcrypt`
- JWT-based authentication
- Role-based authorization for admin-only overview access
- Input normalization and validation
- In-memory rate limiting on key endpoints
- Security response headers
- Configurable CORS allowlist
- SQLAlchemy ORM usage to reduce injection risk

Current limitations:

- Rate limiting is in-memory and resets on restart
- No refresh-token flow yet
- No password reset flow yet
- No email verification yet

## Analysis Flow

### Report upload flow

1. Client sends PDF to `/upload-report`.
2. Backend validates file presence, extension, and size.
3. Backend forwards the PDF to `http://127.0.0.1:5001/analyze-report`.
4. Backend stores the returned analysis in `ReportAnalysis`.
5. Backend builds a trend summary from recent history.
6. Backend returns the combined result to the client.

### Symptom analysis flow

1. Client sends free-text symptoms to `/analyze-symptoms`.
2. Backend sanitizes and validates the text.
3. Backend forwards the payload to `http://127.0.0.1:5001/analyze-symptoms`.
4. Backend stores the result and trend summary.
5. Client receives structured explainable output.

## Testing

Run backend tests:

```powershell
cd backend
python -m unittest discover -s tests
```

Current test coverage includes:

- signup and login flow
- protected symptom analysis flow
- admin-only authorization for overview access

## Common Issues

### Backend starts but analysis returns `502`

Cause:

- ML service is not running
- ML service failed to import dependencies

Fix:

```powershell
python -m Ml_model.app
```

### Upload rejected with size error

Cause:

- file exceeds `MAX_UPLOAD_BYTES`

Fix:

- use a smaller PDF
- or raise `MAX_UPLOAD_BYTES` in the environment

### Login fails for a valid user

Check:

- email format
- password correctness
- whether you are using the same SQLite database file as the running app

## Future Documentation Candidates

- Swagger/OpenAPI spec
- architecture diagram image
- admin dashboard usage guide
- deployment guide for Render/Railway/AWS
