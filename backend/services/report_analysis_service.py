import json
import uuid
from urllib import error, request as urllib_request

from database.db import db
from models.report_analysis_model import ReportAnalysis
from models.user_model import User


ML_API_URL = "http://127.0.0.1:5001/analyze-report"
ML_SYMPTOM_API_URL = "http://127.0.0.1:5001/analyze-symptoms"
MAX_REPORT_BYTES = 10 * 1024 * 1024


def validate_uploaded_pdf(uploaded_file):
    if uploaded_file is None:
        return "No file uploaded", None
    if uploaded_file.filename == "":
        return "Empty file name", None
    if not uploaded_file.filename.lower().endswith(".pdf"):
        return "Only PDF files are supported", None

    file_bytes = uploaded_file.read()
    if not file_bytes:
        return "Uploaded PDF is empty", None
    if len(file_bytes) > MAX_REPORT_BYTES:
        return "Uploaded PDF exceeds the 10 MB limit", None
    return None, file_bytes


def analyze_uploaded_report(user_id, uploaded_file):
    validation_error, file_bytes = validate_uploaded_pdf(uploaded_file)
    if validation_error:
        return None, validation_error, 400

    result = forward_report_to_ml_api(
        file_bytes=file_bytes,
        filename=uploaded_file.filename,
        content_type=uploaded_file.mimetype or "application/pdf",
    )
    save_analysis_record(
        user_id=user_id,
        source_type="report",
        source_name=uploaded_file.filename,
        analysis_result=result,
    )
    result["uploaded_by"] = str(user_id)
    result["trend_summary"] = build_trend_summary(user_id)
    result["message"] = "Report analyzed successfully"
    return result, None, 200


def analyze_symptom_entry(user_id, symptoms_text):
    result = forward_symptoms_to_ml_api(symptoms_text)
    save_analysis_record(
        user_id=user_id,
        source_type="symptom",
        source_name="Symptom Chat",
        analysis_result=result,
    )
    result["analyzed_by"] = str(user_id)
    result["trend_summary"] = build_trend_summary(user_id)
    result["message"] = "Symptoms analyzed successfully"
    return result


def get_report_history(user_id, limit):
    records = (
        ReportAnalysis.query.filter_by(user_id=user_id)
        .order_by(ReportAnalysis.created_at.desc())
        .limit(limit)
        .all()
    )
    return {
        "history": [serialize_analysis(record) for record in records],
        "trend_summary": build_trend_summary(user_id, records=records),
    }


def get_admin_overview(limit):
    records = (
        ReportAnalysis.query.order_by(ReportAnalysis.created_at.desc())
        .limit(limit)
        .all()
    )
    total_analyses = ReportAnalysis.query.count()
    total_users = User.query.count()
    high_urgency_count = ReportAnalysis.query.filter_by(urgency="high").count()
    source_breakdown = {
        "report": ReportAnalysis.query.filter_by(source_type="report").count(),
        "symptom": ReportAnalysis.query.filter_by(source_type="symptom").count(),
    }

    top_predictions = (
        db.session.query(ReportAnalysis.prediction, db.func.count(ReportAnalysis.id))
        .group_by(ReportAnalysis.prediction)
        .order_by(db.func.count(ReportAnalysis.id).desc(), ReportAnalysis.prediction.asc())
        .limit(5)
        .all()
    )

    return {
        "summary": {
            "total_users": total_users,
            "total_analyses": total_analyses,
            "high_urgency_count": high_urgency_count,
            "source_breakdown": source_breakdown,
        },
        "top_predictions": [
            {"prediction": prediction, "count": count}
            for prediction, count in top_predictions
        ],
        "recent_analyses": [serialize_analysis(record) for record in records],
    }


def forward_report_to_ml_api(file_bytes, filename, content_type):
    boundary = f"----MiniBoundary{uuid.uuid4().hex}"
    body = build_multipart_body(boundary, file_bytes, filename, content_type)

    outgoing_request = urllib_request.Request(
        ML_API_URL,
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    return _send_request(outgoing_request)


def forward_symptoms_to_ml_api(symptoms_text):
    body = json.dumps({"symptoms_text": symptoms_text}).encode("utf-8")
    outgoing_request = urllib_request.Request(
        ML_SYMPTOM_API_URL,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    return _send_request(outgoing_request)


def build_multipart_body(boundary, file_bytes, filename, content_type):
    boundary_bytes = boundary.encode("utf-8")
    parts = [
        b"--" + boundary_bytes,
        (
            f'Content-Disposition: form-data; name="file"; filename="{filename}"\r\n'
            f"Content-Type: {content_type}\r\n\r\n"
        ).encode("utf-8"),
        file_bytes,
        b"\r\n--" + boundary_bytes + b"--\r\n",
    ]
    return b"\r\n".join(parts)


def save_analysis_record(user_id, source_type, source_name, analysis_result):
    record = ReportAnalysis(
        user_id=user_id,
        source_type=source_type,
        source_name=source_name,
        prediction=analysis_result.get("prediction") or "Unknown",
        confidence=float(analysis_result.get("confidence") or 0.0),
        urgency=(analysis_result.get("urgency") or "medium").lower(),
        extracted_symptoms_json=json.dumps(
            analysis_result.get("extracted_symptoms") or []
        ),
        recommendations_json=json.dumps(
            analysis_result.get("recommendations") or []
        ),
        precautions_json=json.dumps(analysis_result.get("precautions") or []),
        explanation=analysis_result.get("explanation") or "",
    )
    db.session.add(record)
    db.session.commit()
    return record


def serialize_analysis(record):
    return {
        "id": record.id,
        "source_type": record.source_type,
        "source_name": record.source_name,
        "prediction": record.prediction,
        "confidence": round(float(record.confidence), 4),
        "urgency": record.urgency,
        "extracted_symptoms": json.loads(record.extracted_symptoms_json or "[]"),
        "recommendations": json.loads(record.recommendations_json or "[]"),
        "precautions": json.loads(record.precautions_json or "[]"),
        "explanation": record.explanation,
        "created_at": record.created_at.isoformat(),
    }


def build_trend_summary(user_id, records=None):
    analyses = records or (
        ReportAnalysis.query.filter_by(user_id=user_id)
        .order_by(ReportAnalysis.created_at.desc())
        .limit(6)
        .all()
    )
    if not analyses:
        return {
            "status": "no-data",
            "message": "Upload reports over time to unlock health trend comparison.",
            "direction": "stable",
            "high_urgency_count": 0,
            "average_confidence": 0.0,
        }

    latest = analyses[0]
    previous = analyses[1] if len(analyses) > 1 else None
    average_confidence = round(
        sum(float(item.confidence) for item in analyses) / len(analyses), 4
    )
    high_urgency_count = sum(1 for item in analyses if item.urgency == "high")

    if previous is None:
        return {
            "status": "baseline",
            "message": f"Baseline created from your latest {latest.source_type} analysis.",
            "direction": "stable",
            "high_urgency_count": high_urgency_count,
            "average_confidence": average_confidence,
        }

    latest_rank = urgency_rank(latest.urgency)
    previous_rank = urgency_rank(previous.urgency)
    confidence_delta = round(float(latest.confidence) - float(previous.confidence), 4)

    if latest_rank < previous_rank:
        direction = "improving"
        message = "Recent analysis looks less urgent than the previous one."
    elif latest_rank > previous_rank:
        direction = "worsening"
        message = "Recent analysis looks more urgent than the previous one."
    elif latest.prediction != previous.prediction:
        direction = "changed"
        message = "Prediction pattern changed compared with the previous analysis."
    elif confidence_delta <= -0.12:
        direction = "improving"
        message = "Confidence in the previous risk pattern has decreased."
    elif confidence_delta >= 0.12:
        direction = "worsening"
        message = "Confidence in the recent risk pattern has increased."
    else:
        direction = "stable"
        message = "Recent analyses show a stable pattern."

    return {
        "status": "ready",
        "message": message,
        "direction": direction,
        "high_urgency_count": high_urgency_count,
        "average_confidence": average_confidence,
        "latest_prediction": latest.prediction,
        "previous_prediction": previous.prediction,
        "latest_urgency": latest.urgency,
        "previous_urgency": previous.urgency,
    }


def urgency_rank(urgency):
    return {"low": 1, "medium": 2, "high": 3}.get((urgency or "").lower(), 2)


def _send_request(outgoing_request):
    try:
        with urllib_request.urlopen(outgoing_request, timeout=30) as response:
            payload = response.read().decode("utf-8")
    except error.HTTPError as exc:
        payload = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(
            f"ML API returned HTTP {exc.code}: {payload or exc.reason}"
        ) from exc
    except error.URLError as exc:
        raise RuntimeError(
            "Could not reach ML API on http://127.0.0.1:5001. Start it with: python -m Ml_model.app"
        ) from exc

    return json.loads(payload)
