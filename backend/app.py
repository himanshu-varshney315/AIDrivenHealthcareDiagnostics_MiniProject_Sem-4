import os
from pathlib import Path

from flask import Flask
from flask_jwt_extended import JWTManager

from config import get_jwt_secret_key
from database.db import db
from routes.auth_routes import auth_bp
from routes.report_routes import report_bp
from routes.wearable_routes import wearable_bp
from services.report_analysis_service import (
    get_ml_api_url,
    get_ml_request_timeout_seconds,
    get_ml_symptom_api_url,
)
from services.auth_management import bcrypt
from services.app_bootstrap import configure_cors, initialize_database, install_security_headers


def configure_jwt_callbacks(jwt: JWTManager) -> None:
    @jwt.unauthorized_loader
    def handle_missing_token(reason: str):
        return {"message": "Authentication required."}, 401

    @jwt.invalid_token_loader
    def handle_invalid_token(reason: str):
        return {"message": "Invalid authentication token."}, 401

    @jwt.expired_token_loader
    def handle_expired_token(jwt_header, jwt_payload):
        return {"message": "Session expired. Please sign in again."}, 401

    @jwt.revoked_token_loader
    def handle_revoked_token(jwt_header, jwt_payload):
        return {"message": "Authentication token is no longer valid."}, 401

    @jwt.needs_fresh_token_loader
    def handle_non_fresh_token(jwt_header, jwt_payload):
        return {"message": "Fresh authentication is required."}, 401


def create_app(test_config: dict | None = None) -> Flask:
    app = Flask(__name__)
    instance_dir = Path(app.instance_path)
    instance_dir.mkdir(parents=True, exist_ok=True)
    database_path = Path(
        os.environ.get("DATABASE_PATH", str(instance_dir / "database.db"))
    )
    database_path.parent.mkdir(parents=True, exist_ok=True)

    app.config["SQLALCHEMY_DATABASE_URI"] = f"sqlite:///{database_path.as_posix()}"
    app.config["MAX_CONTENT_LENGTH"] = int(
        os.environ.get("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024))
    )
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    if test_config:
        app.config.update(test_config)

    if not app.config.get("JWT_SECRET_KEY"):
        app.config["JWT_SECRET_KEY"] = get_jwt_secret_key()
    if "JWT_ACCESS_TOKEN_EXPIRES" not in app.config:
        app.config["JWT_ACCESS_TOKEN_EXPIRES"] = False

    configure_cors(app)
    install_security_headers(app)

    db.init_app(app)
    bcrypt.init_app(app)
    jwt = JWTManager(app)
    configure_jwt_callbacks(jwt)

    app.register_blueprint(auth_bp)
    app.register_blueprint(report_bp)
    app.register_blueprint(wearable_bp)

    @app.get("/health")
    def health_check():
        return {"status": "ok"}, 200

    @app.get("/diagnostics")
    def diagnostics():
        return {
            "status": "ok",
            "ml_api_url": get_ml_api_url(),
            "ml_symptom_api_url": get_ml_symptom_api_url(),
            "ml_request_timeout_seconds": get_ml_request_timeout_seconds(),
        }, 200

    with app.app_context():
        initialize_database()

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
