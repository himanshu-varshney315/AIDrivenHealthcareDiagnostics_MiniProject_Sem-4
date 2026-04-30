from flask_bcrypt import Bcrypt
from flask_jwt_extended import create_access_token

from database.db import db
from models.user_model import User
from services.security import (
    is_valid_email,
    is_valid_name,
    is_valid_password,
    sanitize_text,
)


bcrypt = Bcrypt()


def normalize_signup_payload(data):
    """Normalize raw signup JSON into validated service inputs."""
    name = sanitize_text(data.get("name") or "", max_length=120)
    email = sanitize_text(data.get("email") or "", max_length=120).lower()
    password = data.get("password") or ""
    return name, email, password


def normalize_login_payload(data):
    """Normalize raw login JSON into validated service inputs."""
    email = sanitize_text(data.get("email") or "", max_length=120).lower()
    password = data.get("password") or ""
    return email, password


def validate_signup_input(name, email, password):
    """Return a user-facing signup validation error, or None when valid."""
    if not name or not email or not password:
        return "Name, email and password are required"
    if not is_valid_name(name):
        return "Name must be between 2 and 120 characters"
    if not is_valid_email(email):
        return "Enter a valid email address"
    if not is_valid_password(password):
        return "Password must be between 8 and 128 characters"
    return None


def validate_login_input(email, password):
    """Return a user-facing login validation error, or None when valid."""
    if not email or not password:
        return "Email and password are required"
    if not is_valid_email(email):
        return "Enter a valid email address"
    return None


def register_user(name, email, password):
    """Create a user with a hashed password unless the email already exists."""
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return None, "User already exists"

    hashed_password = bcrypt.generate_password_hash(password).decode("utf-8")
    user = User(name=name, email=email, password=hashed_password, role="user")
    db.session.add(user)
    db.session.commit()
    return user, None


def authenticate_user(email, password):
    """Check user credentials and return either the user or an auth error."""
    user = User.query.filter_by(email=email).first()
    if not user or not bcrypt.check_password_hash(user.password, password):
        return None, "Invalid email or password"
    return user, None


def build_auth_response(user):
    """Build the public login response with a JWT access token."""
    token = create_access_token(
        identity=str(user.id),
        additional_claims={"role": user.role},
    )
    return {
        "message": "Login successful",
        "token": token,
        "user": serialize_user(user),
    }


def build_signup_response(user):
    """Build the public signup response."""
    return {
        "message": "User registered successfully",
        "user": serialize_user(user),
    }


def serialize_user(user):
    """Convert a user model into the public API shape."""
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "role": user.role,
    }
