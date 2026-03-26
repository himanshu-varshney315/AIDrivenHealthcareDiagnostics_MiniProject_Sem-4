import os

from flask import Flask
from flask_jwt_extended import JWTManager

from config import get_jwt_secret_key
from database.db import db
from routes.auth_routes import auth_bp
from routes.report_routes import report_bp
from services.auth_management import bcrypt
from services.app_bootstrap import configure_cors, initialize_database, install_security_headers


def create_app(test_config: dict | None = None) -> Flask:
    app = Flask(__name__)
    app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///database.db"
    app.config["JWT_SECRET_KEY"] = get_jwt_secret_key()
    app.config["MAX_CONTENT_LENGTH"] = int(
        os.environ.get("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024))
    )
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

    if test_config:
        app.config.update(test_config)

    configure_cors(app)
    install_security_headers(app)

    db.init_app(app)
    bcrypt.init_app(app)
    JWTManager(app)

    app.register_blueprint(auth_bp)
    app.register_blueprint(report_bp)

    with app.app_context():
        initialize_database()

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
