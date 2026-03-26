from flask import Blueprint, jsonify, request

from services.auth_management import (
    authenticate_user,
    build_auth_response,
    build_signup_response,
    normalize_login_payload,
    normalize_signup_payload,
    register_user,
    validate_login_input,
    validate_signup_input,
)
from services.security import (
    rate_limit,
)

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/signup", methods=["POST"])
@rate_limit(limit=6, window_seconds=60, scope="signup")
def signup():
    data = request.json or {}
    name, email, password = normalize_signup_payload(data)
    validation_error = validate_signup_input(name, email, password)
    if validation_error:
        return jsonify({"message": validation_error}), 400

    user, registration_error = register_user(name, email, password)
    if registration_error:
        return jsonify({"message": registration_error}), 400

    return jsonify(build_signup_response(user))


@auth_bp.route("/login", methods=["POST"])
@rate_limit(limit=8, window_seconds=60, scope="login")
def login():
    data = request.json or {}
    email, password = normalize_login_payload(data)
    validation_error = validate_login_input(email, password)
    if validation_error:
        return jsonify({"message": validation_error}), 400

    user, auth_error = authenticate_user(email, password)
    if auth_error:
        return jsonify({"message": auth_error}), 401

    return jsonify(build_auth_response(user))
