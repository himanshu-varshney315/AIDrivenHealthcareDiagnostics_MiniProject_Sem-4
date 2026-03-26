import unittest
from unittest.mock import patch

from app import create_app
from database.db import db
from models.report_analysis_model import ReportAnalysis
from models.user_model import User
from services.auth_management import bcrypt


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

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()

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


if __name__ == "__main__":
    unittest.main()
