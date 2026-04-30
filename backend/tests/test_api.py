import io
import sys
import unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app import create_app
from database.db import db
from models.report_analysis_model import ReportAnalysis
from models.user_model import User
from models.wearable_model import WearableDailySummary
from services.auth_management import bcrypt
from services.security import rate_limiter, sanitize_text
from services.wearable_risk_service import score_wearable_risk


class ApiTestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app(
            {
                "TESTING": True,
                "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
                "JWT_SECRET_KEY": "test-secret-key-with-at-least-32-bytes",
            }
        )
        self.client = self.app.test_client()

        with self.app.app_context():
            db.drop_all()
            db.create_all()
        rate_limiter.reset()

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()
            db.engine.dispose()

    def test_signup_and_login_flow(self):
        signup_response = self.client.post(
            "/signup",
            json={
                "name": "Test User",
                "email": "tester@example.com",
                "password": "password123",
            },
        )
        self.assertEqual(signup_response.status_code, 200)
        self.assertEqual(
            signup_response.get_json()["user"]["email"],
            "tester@example.com",
        )

        login_response = self.client.post(
            "/login",
            json={"email": "tester@example.com", "password": "password123"},
        )
        self.assertEqual(login_response.status_code, 200)
        self.assertIn("token", login_response.get_json())

    def test_signup_validation_and_duplicate_email(self):
        missing_response = self.client.post("/signup", json={"email": "bad"})
        self.assertEqual(missing_response.status_code, 400)
        self.assertEqual(
            missing_response.get_json()["message"],
            "Name, email and password are required",
        )

        signup_response = self.client.post(
            "/signup",
            json={
                "name": "Duplicate User",
                "email": "duplicate@example.com",
                "password": "password123",
            },
        )
        self.assertEqual(signup_response.status_code, 200)

        duplicate_response = self.client.post(
            "/signup",
            json={
                "name": "Duplicate User",
                "email": "duplicate@example.com",
                "password": "password123",
            },
        )
        self.assertEqual(duplicate_response.status_code, 400)
        self.assertEqual(duplicate_response.get_json()["message"], "User already exists")

    def test_login_validation_and_invalid_credentials(self):
        invalid_email_response = self.client.post(
            "/login",
            json={"email": "not-an-email", "password": "password123"},
        )
        self.assertEqual(invalid_email_response.status_code, 400)

        invalid_credentials_response = self.client.post(
            "/login",
            json={"email": "missing@example.com", "password": "password123"},
        )
        self.assertEqual(invalid_credentials_response.status_code, 401)
        self.assertEqual(
            invalid_credentials_response.get_json()["message"],
            "Invalid email or password",
        )

    @patch("routes.report_routes.analyze_symptom_entry")
    def test_symptom_analysis_requires_valid_token_and_returns_payload(
        self,
        mock_analyze_symptom_entry,
    ):
        mock_analyze_symptom_entry.return_value = {
            "prediction": "Influenza",
            "confidence": 0.84,
            "urgency": "medium",
            "extracted_symptoms": ["fever", "cough"],
            "recommendations": ["Rest and hydrate."],
            "precautions": ["Seek help if breathing worsens."],
            "explanation": "Symptoms match a common flu-like pattern.",
            "trend_summary": {"status": "baseline"},
            "entities": {"symptoms": ["fever", "cough"]},
            "message": "Symptoms analyzed successfully",
        }

        self.client.post(
            "/signup",
            json={
                "name": "Analysis User",
                "email": "analysis@example.com",
                "password": "password123",
            },
        )
        login_response = self.client.post(
            "/login",
            json={"email": "analysis@example.com", "password": "password123"},
        )
        token = login_response.get_json()["token"]

        response = self.client.post(
            "/analyze-symptoms",
            json={"symptoms_text": "fever and cough for two days"},
            headers={"Authorization": f"Bearer {token}"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["prediction"], "Influenza")

    def test_protected_route_rejects_missing_token(self):
        response = self.client.get("/reports/history")

        self.assertEqual(response.status_code, 401)
        self.assertEqual(
            response.get_json()["message"],
            "Authentication required.",
        )

    def test_protected_route_rejects_invalid_token(self):
        response = self.client.get(
            "/reports/history",
            headers={"Authorization": "Bearer not-a-real-token"},
        )

        self.assertEqual(response.status_code, 401)
        self.assertEqual(
            response.get_json()["message"],
            "Invalid authentication token.",
        )

    def test_security_headers_are_present(self):
        response = self.client.get("/reports/history")

        self.assertEqual(response.headers["X-Content-Type-Options"], "nosniff")
        self.assertEqual(response.headers["X-Frame-Options"], "DENY")
        self.assertIn("frame-ancestors 'none'", response.headers["Content-Security-Policy"])
        self.assertEqual(response.headers["Cache-Control"], "no-store")

    def test_sanitize_text_removes_markup_characters(self):
        cleaned = sanitize_text("  <script>alert(1)</script> fever  ", max_length=120)

        self.assertNotIn("<", cleaned)
        self.assertNotIn(">", cleaned)
        self.assertIn("script", cleaned)

    @patch.dict("os.environ", {"CORS_ORIGINS": "http://allowed.example"}, clear=False)
    def test_cors_allowlist_uses_configured_origin(self):
        app = create_app(
            {
                "TESTING": True,
                "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
                "JWT_SECRET_KEY": "test-secret-key-with-at-least-32-bytes",
            }
        )
        client = app.test_client()

        response = client.options(
            "/login",
            headers={
                "Origin": "http://allowed.example",
                "Access-Control-Request-Method": "POST",
            },
        )

        self.assertEqual(response.headers["Access-Control-Allow-Origin"], "http://allowed.example")

        with app.app_context():
            db.session.remove()
            db.drop_all()
            db.engine.dispose()

    @patch("services.report_analysis_service.forward_report_to_ml_api")
    def test_report_upload_accepts_plain_text_report(self, mock_forward_report):
        mock_forward_report.return_value = {
            "prediction": "Anemia",
            "confidence": 0.72,
            "urgency": "medium",
            "extracted_symptoms": ["fatigue"],
            "recommendations": ["Review CBC findings with a clinician."],
            "precautions": ["Seek help for severe weakness."],
            "explanation": "Low hemoglobin language was detected.",
        }

        self.client.post(
            "/signup",
            json={
                "name": "Text Upload User",
                "email": "text-upload@example.com",
                "password": "password123",
            },
        )
        login_response = self.client.post(
            "/login",
            json={"email": "text-upload@example.com", "password": "password123"},
        )
        token = login_response.get_json()["token"]

        response = self.client.post(
            "/upload-report",
            data={
                "file": (
                    io.BytesIO(b"hemoglobin 9.8 fatigue"),
                    "lab-report.txt",
                )
            },
            headers={"Authorization": f"Bearer {token}"},
            content_type="multipart/form-data",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["prediction"], "Anemia")
        self.assertIn("seek_care", response.get_json())
        self.assertIn("probabilities", response.get_json())
        mock_forward_report.assert_called_once()

    @patch("services.report_analysis_service.analyze_symptoms_locally")
    @patch("services.report_analysis_service._send_request")
    def test_symptom_analysis_falls_back_when_ml_service_is_unreachable(
        self,
        mock_send_request,
        mock_analyze_symptoms_locally,
    ):
        mock_send_request.side_effect = RuntimeError(
            "Could not reach ML API. Start it with: python -m Ml_model.app"
        )
        mock_analyze_symptoms_locally.return_value = {
            "prediction": "Influenza",
            "confidence": 0.71,
            "urgency": "medium",
            "extracted_symptoms": ["fever", "body ache"],
            "recommendations": ["Rest and drink fluids."],
            "precautions": ["Monitor fever."],
            "explanation": "Symptoms match a flu-like pattern.",
        }

        self.client.post(
            "/signup",
            json={
                "name": "Fallback User",
                "email": "fallback@example.com",
                "password": "password123",
            },
        )
        token = self.client.post(
            "/login",
            json={"email": "fallback@example.com", "password": "password123"},
        ).get_json()["token"]

        response = self.client.post(
            "/analyze-symptoms",
            json={"symptoms_text": "fever and body ache since yesterday"},
            headers={"Authorization": f"Bearer {token}"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["prediction"], "Influenza")
        mock_analyze_symptoms_locally.assert_called_once_with(
            "fever and body ache since yesterday"
        )

    def test_report_upload_validation_failures(self):
        self.client.post(
            "/signup",
            json={
                "name": "Upload User",
                "email": "upload-validation@example.com",
                "password": "password123",
            },
        )
        login_response = self.client.post(
            "/login",
            json={"email": "upload-validation@example.com", "password": "password123"},
        )
        token = login_response.get_json()["token"]

        missing_file_response = self.client.post(
            "/upload-report",
            data={},
            headers={"Authorization": f"Bearer {token}"},
            content_type="multipart/form-data",
        )
        self.assertEqual(missing_file_response.status_code, 400)
        self.assertEqual(missing_file_response.get_json()["message"], "No file uploaded")

        unsupported_file_response = self.client.post(
            "/upload-report",
            data={"file": (io.BytesIO(b"fake"), "report.exe")},
            headers={"Authorization": f"Bearer {token}"},
            content_type="multipart/form-data",
        )
        self.assertEqual(unsupported_file_response.status_code, 400)
        self.assertIn("Only PDF", unsupported_file_response.get_json()["message"])

    def test_upload_limit_error_handler(self):
        app = create_app(
            {
                "TESTING": True,
                "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
                "JWT_SECRET_KEY": "test-secret-key-with-at-least-32-bytes",
            }
        )
        client = app.test_client()
        with app.app_context():
            db.drop_all()
            db.create_all()

        client.post(
            "/signup",
            json={
                "name": "Small Limit",
                "email": "limit@example.com",
                "password": "password123",
            },
        )
        token = client.post(
            "/login",
            json={"email": "limit@example.com", "password": "password123"},
        ).get_json()["token"]
        app.config["MAX_CONTENT_LENGTH"] = 8

        response = client.post(
            "/upload-report",
            data={"file": (io.BytesIO(b"larger than eight bytes"), "report.txt")},
            headers={"Authorization": f"Bearer {token}"},
            content_type="multipart/form-data",
        )

        self.assertEqual(response.status_code, 413)

        with app.app_context():
            db.session.remove()
            db.drop_all()
            db.engine.dispose()

    def test_login_rate_limit(self):
        for _index in range(8):
            response = self.client.post(
                "/login",
                json={"email": "rate@example.com", "password": "password123"},
                headers={"X-Forwarded-For": "203.0.113.10"},
            )
            self.assertEqual(response.status_code, 401)

        limited_response = self.client.post(
            "/login",
            json={"email": "rate@example.com", "password": "password123"},
            headers={"X-Forwarded-For": "203.0.113.10"},
        )
        self.assertEqual(limited_response.status_code, 429)

    def test_reports_overview_requires_admin_role(self):
        with self.app.app_context():
            hashed_password = bcrypt.generate_password_hash("password123").decode(
                "utf-8"
            )
            admin_user = User(
                name="Admin User",
                email="admin@example.com",
                password=hashed_password,
                role="admin",
            )
            regular_user = User(
                name="Regular User",
                email="regular@example.com",
                password=hashed_password,
                role="user",
            )
            db.session.add_all([admin_user, regular_user])
            db.session.commit()

            db.session.add(
                ReportAnalysis(
                    user_id=admin_user.id,
                    source_type="report",
                    source_name="report.pdf",
                    prediction="Hypertension",
                    confidence=0.78,
                    urgency="high",
                    extracted_symptoms_json='["headache"]',
                    recommendations_json='["Check blood pressure"]',
                    precautions_json='["Consult a doctor"]',
                    explanation="Elevated BP markers detected.",
                )
            )
            db.session.commit()

        regular_login = self.client.post(
            "/login",
            json={"email": "regular@example.com", "password": "password123"},
        )
        admin_login = self.client.post(
            "/login",
            json={"email": "admin@example.com", "password": "password123"},
        )

        regular_token = regular_login.get_json()["token"]
        admin_token = admin_login.get_json()["token"]

        forbidden_response = self.client.get(
            "/reports/overview",
            headers={"Authorization": f"Bearer {regular_token}"},
        )
        self.assertEqual(forbidden_response.status_code, 403)

        allowed_response = self.client.get(
            "/reports/overview",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        self.assertEqual(allowed_response.status_code, 200)
        payload = allowed_response.get_json()
        self.assertEqual(payload["summary"]["total_analyses"], 1)
        self.assertEqual(payload["summary"]["high_urgency_count"], 1)

    def test_report_history_serializes_normalized_shape(self):
        with self.app.app_context():
            hashed_password = bcrypt.generate_password_hash("password123").decode(
                "utf-8"
            )
            user = User(
                name="History User",
                email="history@example.com",
                password=hashed_password,
                role="user",
            )
            db.session.add(user)
            db.session.commit()
            db.session.add(
                ReportAnalysis(
                    user_id=user.id,
                    source_type="symptom",
                    source_name="Symptom Chat",
                    prediction="Influenza",
                    confidence=0.65,
                    urgency="medium",
                    extracted_symptoms_json='["fever"]',
                    recommendations_json='["Rest"]',
                    precautions_json='["Monitor breathing"]',
                    explanation="Flu-like symptoms detected.",
                )
            )
            db.session.commit()

        token = self.client.post(
            "/login",
            json={"email": "history@example.com", "password": "password123"},
        ).get_json()["token"]
        response = self.client.get(
            "/reports/history",
            headers={"Authorization": f"Bearer {token}"},
        )

        self.assertEqual(response.status_code, 200)
        item = response.get_json()["history"][0]
        self.assertEqual(item["prediction"], "Influenza")
        self.assertEqual(item["extracted_symptoms"], ["fever"])
        self.assertIn("entities", item)
        self.assertIn("probabilities", item)
        self.assertIn("seek_care", item)

    def test_wearable_routes_require_authentication(self):
        latest_response = self.client.get("/wearables/latest")
        sync_response = self.client.post("/wearables/sync", json={"steps": 4200})

        self.assertEqual(latest_response.status_code, 401)
        self.assertEqual(sync_response.status_code, 401)

    def test_wearable_sync_validates_and_ignores_unsupported_metrics(self):
        self.client.post(
            "/signup",
            json={
                "name": "Wearable User",
                "email": "wearable@example.com",
                "password": "password123",
            },
        )
        token = self.client.post(
            "/login",
            json={"email": "wearable@example.com", "password": "password123"},
        ).get_json()["token"]

        empty_response = self.client.post(
            "/wearables/sync",
            json={"metrics": {"unsupported": 123}},
            headers={"Authorization": f"Bearer {token}"},
        )
        self.assertEqual(empty_response.status_code, 400)

        sync_response = self.client.post(
            "/wearables/sync",
            json={
                "date": "2026-04-30",
                "metrics": {
                    "latest_heart_rate": 82,
                    "average_heart_rate": 76,
                    "steps": 6500,
                    "sleep_minutes": 430,
                    "calories": 210,
                    "spo2": 98,
                    "unsupported": 999,
                },
            },
            headers={"Authorization": f"Bearer {token}"},
        )

        self.assertEqual(sync_response.status_code, 200)
        payload = sync_response.get_json()["summary"]
        self.assertEqual(payload["metrics"]["steps"], 6500)
        self.assertNotIn("unsupported", payload["metrics"])
        self.assertEqual(payload["risk"]["risk_level"], "low")

    def test_wearable_latest_and_history_are_user_scoped(self):
        with self.app.app_context():
            hashed_password = bcrypt.generate_password_hash("password123").decode(
                "utf-8"
            )
            first_user = User(
                name="First Wearable",
                email="first-wearable@example.com",
                password=hashed_password,
                role="user",
            )
            second_user = User(
                name="Second Wearable",
                email="second-wearable@example.com",
                password=hashed_password,
                role="user",
            )
            db.session.add_all([first_user, second_user])
            db.session.commit()
            db.session.add(
                WearableDailySummary(
                    user_id=first_user.id,
                    summary_date=date.fromisoformat("2026-04-29"),
                    latest_heart_rate=72,
                    steps=7200,
                    risk_score=8,
                    risk_level="low",
                    factors_json='["No major wearable risk marker detected today"]',
                    recommendations_json='["Keep syncing wearable data"]',
                )
            )
            db.session.add(
                WearableDailySummary(
                    user_id=second_user.id,
                    summary_date=date.fromisoformat("2026-04-30"),
                    latest_heart_rate=130,
                    steps=900,
                    risk_score=70,
                    risk_level="high",
                    factors_json='["Very high latest heart rate"]',
                    recommendations_json='["Consider prompt clinical advice"]',
                )
            )
            db.session.commit()

        first_token = self.client.post(
            "/login",
            json={"email": "first-wearable@example.com", "password": "password123"},
        ).get_json()["token"]

        latest_response = self.client.get(
            "/wearables/latest",
            headers={"Authorization": f"Bearer {first_token}"},
        )
        history_response = self.client.get(
            "/wearables/history?days=7",
            headers={"Authorization": f"Bearer {first_token}"},
        )

        self.assertEqual(latest_response.status_code, 200)
        self.assertEqual(latest_response.get_json()["summary"]["metrics"]["steps"], 7200)
        self.assertEqual(len(history_response.get_json()["history"]), 1)
        self.assertEqual(
            history_response.get_json()["history"][0]["risk"]["risk_level"],
            "low",
        )

    def test_wearable_risk_scoring_levels(self):
        low = score_wearable_risk(
            {
                "latest_heart_rate": 72,
                "average_heart_rate": 70,
                "steps": 8000,
                "sleep_minutes": 450,
                "spo2": 98,
            }
        )
        moderate = score_wearable_risk(
            {
                "latest_heart_rate": 105,
                "steps": 1500,
                "sleep_minutes": 360,
                "spo2": 96,
            }
        )
        high = score_wearable_risk(
            {
                "latest_heart_rate": 128,
                "average_heart_rate": 104,
                "steps": 800,
                "sleep_minutes": 240,
                "spo2": 90,
            }
        )

        self.assertEqual(low["risk_level"], "low")
        self.assertEqual(moderate["risk_level"], "moderate")
        self.assertEqual(high["risk_level"], "high")

    @patch.dict("os.environ", {"FLASK_ENV": "production"}, clear=False)
    def test_create_app_accepts_test_secret_in_production_environment(self):
        app = create_app(
            {
                "TESTING": True,
                "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
                "JWT_SECRET_KEY": "test-secret-key-with-at-least-32-bytes",
            }
        )

        self.assertEqual(
            app.config["JWT_SECRET_KEY"],
            "test-secret-key-with-at-least-32-bytes",
        )

        with app.app_context():
            db.session.remove()
            db.drop_all()
            db.engine.dispose()


if __name__ == "__main__":
    unittest.main()
