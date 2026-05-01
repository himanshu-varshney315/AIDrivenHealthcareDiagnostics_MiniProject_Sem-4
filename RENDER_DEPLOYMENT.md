# Deploy Ayuva on Render

This repo includes a `render.yaml` Blueprint with three services:

- `ayuva-ml`: ML analysis API
- `ayuva-db`: Managed Postgres database
- `ayuva-backend`: Flask API used by the Flutter app

## Deploy

1. Push this repository to GitHub.
2. Open Render Dashboard.
3. Select **New > Blueprint**.
4. Connect this repo.
5. Keep the Blueprint file path as `render.yaml`.
6. Apply the Blueprint.

Render will build both Docker services. The backend receives a generated
`JWT_SECRET_KEY` and connects to the ML service through the public
`https://ayuva-ml.onrender.com` URL. This is intentional for the free plan:
Render free web services can send private network requests, but they cannot
receive them.

## After Deploy

Open the `ayuva-backend` service in Render and copy its public URL, for example:

```text
https://ayuva-backend.onrender.com
```

Use that URL when building the Flutter app:

```powershell
cd frontend_flutter
flutter build appbundle --release --dart-define=API_BASE_URL=https://ayuva-backend.onrender.com
```

## Important Notes

- The current Blueprint uses Render's free plan.
- Free services can spin down when idle, so the first request after inactivity can be slow.
- Keep `ML_API_URL` and `ML_SYMPTOM_API_URL` configured on `ayuva-backend`.
  On Render's free plan, do not rely on `ML_SERVICE_HOSTPORT` for the ML service.
- The Blueprint now includes a managed Postgres database (`ayuva-db`) for persistent data storage.
  User accounts and analysis history will survive redeploys and restarts.
- The ML service installs Torch and Transformers, so the first build can take a while.
  If the free plan runs out of memory, change `ayuva-ml` from `free` to a larger plan.
