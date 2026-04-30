from datetime import date, datetime, timezone

from database.db import db


class WearableConnection(db.Model):
    """Tracks the user's wearable/Health Connect sync status."""

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False, unique=True, index=True)
    provider = db.Column(db.String(60), nullable=False, default="health_connect")
    status = db.Column(db.String(30), nullable=False, default="connected")
    last_sync_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(
        db.DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at = db.Column(
        db.DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )


class WearableDailySummary(db.Model):
    """Daily aggregate vitals synced from Health Connect."""

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=False, index=True)
    summary_date = db.Column(db.Date, nullable=False, default=date.today, index=True)
    latest_heart_rate = db.Column(db.Float, nullable=True)
    average_heart_rate = db.Column(db.Float, nullable=True)
    steps = db.Column(db.Integer, nullable=True)
    sleep_minutes = db.Column(db.Integer, nullable=True)
    calories = db.Column(db.Float, nullable=True)
    spo2 = db.Column(db.Float, nullable=True)
    risk_score = db.Column(db.Integer, nullable=False, default=0)
    risk_level = db.Column(db.String(20), nullable=False, default="low")
    factors_json = db.Column(db.Text, nullable=False, default="[]")
    recommendations_json = db.Column(db.Text, nullable=False, default="[]")
    created_at = db.Column(
        db.DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at = db.Column(
        db.DateTime,
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    __table_args__ = (
        db.UniqueConstraint("user_id", "summary_date", name="uq_wearable_user_date"),
    )
