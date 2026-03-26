from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from database.db import db
from services.report_analysis_service import (
    analyze_symptom_entry,
    analyze_uploaded_report,
    get_admin_overview,
    get_report_history,
)
from services.security import rate_limit, require_role, sanitize_text

report_bp = Blueprint("report", __name__)


@report_bp.route("/upload-report", methods=["POST"])
@jwt_required()
@rate_limit(limit=5, window_seconds=60, scope="upload-report")
def upload_report():
    uploaded_file = request.files.get("file")

    try:
        user_id = int(get_jwt_identity())
        analysis_result, validation_error, status_code = analyze_uploaded_report(
            user_id=user_id,
            uploaded_file=uploaded_file,
        )
        if validation_error:
            if validation_error == "Uploaded PDF exceeds the 10 MB limit":
                return jsonify({"message": validation_error}), 413
            return jsonify({"message": validation_error}), status_code
        return jsonify(analysis_result), status_code
    except RuntimeError as exc:
        return jsonify({"message": str(exc)}), 502
    except Exception as exc:
        db.session.rollback()
        return jsonify({"message": f"Failed to analyze report: {str(exc)}"}), 500


@report_bp.route("/analyze-symptoms", methods=["POST"])
@jwt_required()
@rate_limit(limit=10, window_seconds=60, scope="analyze-symptoms")
def analyze_symptoms():
    payload = request.get_json(silent=True) or {}
    symptoms_text = sanitize_text(payload.get("symptoms_text") or "", max_length=1000)
    if not symptoms_text:
        return jsonify({"message": "symptoms_text is required"}), 400
    if len(symptoms_text) < 5:
        return jsonify({"message": "Please describe symptoms in a little more detail"}), 400

    try:
        analysis_result = analyze_symptom_entry(
            user_id=int(get_jwt_identity()),
            symptoms_text=symptoms_text,
        )
        return jsonify(analysis_result), 200
    except RuntimeError as exc:
        return jsonify({"message": str(exc)}), 502
    except Exception as exc:
        db.session.rollback()
        return jsonify({"message": f"Failed to analyze symptoms: {str(exc)}"}), 500


@report_bp.route("/reports/history", methods=["GET"])
@jwt_required()
def report_history():
    user_id = int(get_jwt_identity())
    limit = request.args.get("limit", default=10, type=int) or 10
    limit = max(1, min(limit, 25))
    return jsonify(get_report_history(user_id=user_id, limit=limit))


@report_bp.route("/reports/overview", methods=["GET"])
@jwt_required()
@require_role("admin")
def reports_overview():
    limit = request.args.get("limit", default=10, type=int) or 10
    limit = max(1, min(limit, 25))
    return jsonify(get_admin_overview(limit=limit))
