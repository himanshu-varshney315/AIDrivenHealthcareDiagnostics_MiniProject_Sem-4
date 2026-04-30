import json
from datetime import date, datetime, time, timezone

from database.db import db
from models.wearable_model import WearableConnection, WearableDailySummary
from services.wearable_risk_service import score_wearable_risk


SUPPORTED_METRICS = {
    "latest_heart_rate",
    "average_heart_rate",
    "steps",
    "sleep_minutes",
    "calories",
    "spo2",
}


def sync_wearable_summary(user_id, payload):
    """Validate and persist one daily wearable summary."""
    summary_date = _parse_summary_date(payload.get("date"))
    metrics = _extract_metrics(payload)
    if not any(value is not None for value in metrics.values()):
        return None, "At least one supported wearable metric is required", 400

    recent = _recent_summaries(user_id=user_id, before_date=summary_date, limit=6)
    risk = score_wearable_risk(metrics, recent_summaries=recent)

    record = WearableDailySummary.query.filter_by(
        user_id=user_id,
        summary_date=summary_date,
    ).first()
    if record is None:
        record = WearableDailySummary(user_id=user_id, summary_date=summary_date)
        db.session.add(record)

    for field, value in metrics.items():
        setattr(record, field, value)
    record.risk_score = risk["risk_score"]
    record.risk_level = risk["risk_level"]
    record.factors_json = json.dumps(risk["factors"])
    record.recommendations_json = json.dumps(risk["recommendations"])

    connection = WearableConnection.query.filter_by(user_id=user_id).first()
    if connection is None:
        connection = WearableConnection(user_id=user_id)
        db.session.add(connection)
    connection.status = "connected"
    connection.last_sync_at = datetime.now(timezone.utc)

    db.session.commit()
    return serialize_wearable_summary(record), None, 200


def get_latest_wearable_summary(user_id):
    record = (
        WearableDailySummary.query.filter_by(user_id=user_id)
        .order_by(WearableDailySummary.summary_date.desc(), WearableDailySummary.updated_at.desc())
        .first()
    )
    connection = WearableConnection.query.filter_by(user_id=user_id).first()
    return {
        "connected": bool(connection and connection.status == "connected"),
        "connection": serialize_connection(connection),
        "summary": serialize_wearable_summary(record) if record else None,
    }


def get_wearable_history(user_id, days):
    days = max(1, min(int(days or 7), 30))
    records = (
        WearableDailySummary.query.filter_by(user_id=user_id)
        .order_by(WearableDailySummary.summary_date.desc())
        .limit(days)
        .all()
    )
    ordered = list(reversed(records))
    return {
        "days": days,
        "history": [serialize_wearable_summary(record) for record in ordered],
    }


def serialize_connection(connection):
    if connection is None:
        return None
    return {
        "provider": connection.provider,
        "status": connection.status,
        "last_sync_at": connection.last_sync_at.isoformat() if connection.last_sync_at else None,
    }


def serialize_wearable_summary(record):
    if record is None:
        return None
    return {
        "id": record.id,
        "date": record.summary_date.isoformat(),
        "metrics": {
            "latest_heart_rate": record.latest_heart_rate,
            "average_heart_rate": record.average_heart_rate,
            "steps": record.steps,
            "sleep_minutes": record.sleep_minutes,
            "calories": record.calories,
            "spo2": record.spo2,
        },
        "risk": {
            "risk_score": record.risk_score,
            "risk_level": record.risk_level,
            "factors": json.loads(record.factors_json or "[]"),
            "recommendations": json.loads(record.recommendations_json or "[]"),
            "model_task": "vitals_risk_scoring_mvp",
        },
        "created_at": record.created_at.isoformat(),
        "updated_at": record.updated_at.isoformat(),
    }


def _extract_metrics(payload):
    source = payload.get("metrics") if isinstance(payload.get("metrics"), dict) else payload
    metrics = {}
    for key in SUPPORTED_METRICS:
        value = source.get(key)
        metrics[key] = _coerce_metric(key, value)
    return metrics


def _coerce_metric(key, value):
    if value is None or value == "":
        return None
    try:
        numeric = float(value)
    except (TypeError, ValueError):
        return None
    if numeric < 0:
        return None
    if key in {"steps", "sleep_minutes"}:
        return int(round(numeric))
    return round(numeric, 2)


def _parse_summary_date(value):
    if not value:
        return date.today()
    try:
        return date.fromisoformat(str(value)[:10])
    except ValueError:
        return date.today()


def _recent_summaries(user_id, before_date, limit):
    start_of_day = datetime.combine(before_date, time.min)
    return (
        WearableDailySummary.query.filter(WearableDailySummary.user_id == user_id)
        .filter(WearableDailySummary.summary_date < start_of_day.date())
        .order_by(WearableDailySummary.summary_date.desc())
        .limit(limit)
        .all()
    )
