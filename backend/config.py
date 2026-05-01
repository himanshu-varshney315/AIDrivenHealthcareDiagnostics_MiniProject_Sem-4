import os
import secrets
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
INSTANCE_DIR = BASE_DIR / "instance"
LOCAL_SECRET_FILE = INSTANCE_DIR / ".jwt_secret"


def get_database_uri() -> str:
    configured = os.environ.get("DATABASE_URL", "").strip()
    if configured:
        return configured

    INSTANCE_DIR.mkdir(parents=True, exist_ok=True)
    database_path = Path(os.environ.get("DATABASE_PATH", str(INSTANCE_DIR / "database.db")))
    database_path.parent.mkdir(parents=True, exist_ok=True)
    return f"sqlite:///{database_path.as_posix()}"


def get_jwt_secret_key() -> str:
    configured = os.environ.get("JWT_SECRET_KEY", "").strip()
    if configured:
        return configured

    environment = os.environ.get("FLASK_ENV", "").strip().lower()
    if environment == "production":
        raise RuntimeError(
            "JWT_SECRET_KEY must be set in the environment when running in production."
        )

    INSTANCE_DIR.mkdir(parents=True, exist_ok=True)
    if LOCAL_SECRET_FILE.exists():
        saved = LOCAL_SECRET_FILE.read_text(encoding="utf-8").strip()
        if saved:
            return saved

    generated = secrets.token_urlsafe(48)
    LOCAL_SECRET_FILE.write_text(generated, encoding="utf-8")
    return generated
