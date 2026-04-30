import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from Ml_model.predict import analyze_medical_report_text, analyze_symptom_text
from Ml_model.training import trainer


class MlSmokeTestCase(unittest.TestCase):
    def assert_analysis_shape(self, payload):
        required_keys = {
            "prediction",
            "confidence",
            "urgency",
            "explanation",
            "extracted_symptoms",
            "entities",
            "probabilities",
            "recommendations",
            "precautions",
            "recommended_medicines",
            "seek_care",
        }
        self.assertTrue(required_keys.issubset(payload.keys()))
        self.assertIsInstance(payload["probabilities"], dict)
        self.assertIsInstance(payload["recommendations"], list)

    def test_symptom_predictor_returns_expected_shape(self):
        payload = analyze_symptom_text("fever, cough, body ache and chills since yesterday")

        self.assert_analysis_shape(payload)
        self.assertEqual(payload["task"], "symptom")

    def test_report_predictor_returns_expected_shape(self):
        payload = analyze_medical_report_text("Hemoglobin is low with fatigue and dizziness.")

        self.assert_analysis_shape(payload)
        self.assertEqual(payload["task"], "report")

    def test_heuristic_fallback_returns_expected_shape(self):
        with patch("Ml_model.predict._load_artifact", return_value=None):
            payload = analyze_symptom_text("runny nose and sneezing")

        self.assert_analysis_shape(payload)
        self.assertEqual(payload["task"], "symptom")

    def test_incompatible_model_artifact_uses_heuristic_fallback(self):
        class IncompatiblePipeline:
            def predict_proba(self, text):
                raise AttributeError("'LogisticRegression' object has no attribute 'multi_class'")

        with patch(
            "Ml_model.predict._load_artifact",
            return_value={"pipeline": IncompatiblePipeline()},
        ):
            payload = analyze_symptom_text("fever and body ache since yesterday")

        self.assert_analysis_shape(payload)
        self.assertEqual(payload["task"], "symptom")
        self.assertNotEqual(payload["prediction"], "Unknown")

    def test_metrics_artifact_writer_records_lifecycle_metadata(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            metrics_path = Path(temp_dir) / "metrics.json"
            with patch.object(trainer, "METRICS_PATH", metrics_path):
                payload = trainer._write_metrics_artifact(
                    task="symptom",
                    selected_model="smoke_model",
                    dataset_size=4,
                    labels=["Cold", "Flu"],
                    cv_strategy="StratifiedKFold(n_splits=2)",
                    leaderboard={"smoke_model": {"f1_score": 0.9}},
                    model_path="models/smoke.joblib",
                )

        symptom_metrics = payload["tasks"]["symptom"]
        self.assertEqual(symptom_metrics["selected_model"], "smoke_model")
        self.assertEqual(symptom_metrics["dataset_size"], 4)
        self.assertEqual(symptom_metrics["labels"], ["Cold", "Flu"])
        self.assertIn("generated_at", symptom_metrics)


if __name__ == "__main__":
    unittest.main()
