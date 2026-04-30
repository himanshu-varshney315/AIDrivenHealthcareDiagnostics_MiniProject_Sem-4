# Contributing

This project is maintained as a Flutter frontend, Flask backend, and separate ML service. Keep changes small, reviewable, and tied to one purpose.

## Workflow

- Use focused branches such as `feature/report-feedback`, `fix/auth-errors`, or `docs/docker-setup`.
- Prefer small commits that each build, test, or document one coherent change.
- Do not rewrite shared Git history after work has been pushed.
- Keep generated secrets, real API keys, local databases, and `.env` files out of commits.
- Mention the subsystem in commit messages when useful, for example `backend: add upload validation tests`.

## Review Expectations

- Explain the user-facing or engineering reason for the change.
- Include the commands you ran, especially backend tests, ML smoke checks, `flutter analyze`, and `flutter test`.
- Call out skipped checks with a reason.
- Keep UI changes consistent with the existing app theme and route structure.
- Keep backend changes inside the current route/service/model split unless a larger refactor is explicitly approved.

## Team Split

- Frontend: Flutter screens, widgets, local session handling, and API rendering.
- Backend: Flask routes, auth, validation, persistence, security headers, and API contracts.
- ML: prediction shape, training, metrics, fallback behavior, and model artifacts.
- Docs/DevOps: README updates, Docker, CI, env examples, and security notes.
