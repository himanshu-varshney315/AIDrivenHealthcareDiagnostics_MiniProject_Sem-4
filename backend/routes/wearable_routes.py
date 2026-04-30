from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from database.db import db
from services.security import rate_limit
from services.wearable_service import (
    get_latest_wearable_summary,
    get_wearable_history,
    sync_wearable_summary,
)

wearable_bp = Blueprint("wearable", __name__, url_prefix="/wearables")


@wearable_bp.route("/sync", methods=["POST"])
@jwt_required()
@rate_limit(limit=20, window_seconds=60, scope="wearables-sync")
def sync_wearables():
    payload = request.get_json(silent=True) or {}
    try:
        result, validation_error, status_code = sync_wearable_summary(
            user_id=int(get_jwt_identity()),
            payload=payload,
        )
        if validation_error:
            return jsonify({"message": validation_error}), status_code
        return jsonify({"message": "Wearable data synced successfully", "summary": result}), status_code
    except Exception as exc:
        db.session.rollback()
        return jsonify({"message": f"Failed to sync wearable data: {str(exc)}"}), 500


@wearable_bp.route("/latest", methods=["GET"])
@jwt_required()
def latest_wearables():
    return jsonify(get_latest_wearable_summary(user_id=int(get_jwt_identity())))


@wearable_bp.route("/history", methods=["GET"])
@jwt_required()
def wearable_history():
    days = request.args.get("days", default=7, type=int) or 7
    return jsonify(get_wearable_history(user_id=int(get_jwt_identity()), days=days))
