from datetime import datetime, timezone

from database.db import db


class ReportAnalysis(db.Model):
    """Stored analysis result used for user history and admin overview."""

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False, index=True)
    source_type = db.Column(db.String(20), nullable=False, default="report")
    source_name = db.Column(db.String(255), nullable=False)
    prediction = db.Column(db.String(120), nullable=False)
    confidence = db.Column(db.Float, nullable=False, default=0.0)
    urgency = db.Column(db.String(20), nullable=False, default="medium")
    extracted_symptoms_json = db.Column(db.Text, nullable=False, default="[]")
    recommendations_json = db.Column(db.Text, nullable=False, default="[]")
    precautions_json = db.Column(db.Text, nullable=False, default="[]")
    explanation = db.Column(db.Text, nullable=False, default="")
    created_at = db.Column(
        db.DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        index=True,
    )
