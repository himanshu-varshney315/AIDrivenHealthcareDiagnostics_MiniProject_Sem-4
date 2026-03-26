import os

from flask import jsonify
from flask_cors import CORS
from sqlalchemy import text

from database.db import db


def configure_cors(app):
    allowed_origins = os.environ.get(
        "CORS_ORIGINS",
        "http://127.0.0.1:5000,http://localhost:5000,http://127.0.0.1:3000,http://localhost:3000",
    )
    CORS(
        app,
        resources={
            r"/*": {
                "origins": [
                    origin.strip()
                    for origin in allowed_origins.split(",")
                    if origin.strip()
                ]
            }
        },
    )


def install_security_headers(app):
    @app.after_request
    def add_security_headers(response):
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Cache-Control"] = "no-store"
        return response

    @app.errorhandler(413)
    def payload_too_large(_error):
        max_mb = app.config["MAX_CONTENT_LENGTH"] / (1024 * 1024)
        return jsonify(
            {"message": f"File is too large. Maximum allowed size is {max_mb:.0f} MB."}
        ), 413


def initialize_database():
    db.create_all()
    ensure_user_columns()


def ensure_user_columns():
    columns = _get_table_columns("user")
    if "name" not in columns:
        db.session.execute(
            text("ALTER TABLE user ADD COLUMN name VARCHAR(120) NOT NULL DEFAULT 'User'")
        )
        db.session.commit()
    if "role" not in columns:
        db.session.execute(
            text("ALTER TABLE user ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'user'")
        )
        db.session.commit()


def _get_table_columns(table_name):
    inspector_sql = text(f"PRAGMA table_info({table_name})")
    return {row[1] for row in db.session.execute(inspector_sql).fetchall()}
