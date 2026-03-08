from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from sqlalchemy import text

from database.db import db
from routes.auth_routes import auth_bp
from routes.report_routes import report_bp

app = Flask(__name__)

app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///database.db"
app.config["JWT_SECRET_KEY"] = "secret-key"

CORS(app)

db.init_app(app)

jwt = JWTManager(app)

app.register_blueprint(auth_bp)
app.register_blueprint(report_bp)


def ensure_user_name_column():
    inspector_sql = text("PRAGMA table_info(user)")
    columns = db.session.execute(inspector_sql).fetchall()
    column_names = {row[1] for row in columns}

    if "name" not in column_names:
        db.session.execute(
            text("ALTER TABLE user ADD COLUMN name VARCHAR(120) NOT NULL DEFAULT 'User'")
        )
        db.session.commit()


with app.app_context():
    db.create_all()
    ensure_user_name_column()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
