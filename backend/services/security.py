import re
import time
from collections import defaultdict, deque
from functools import wraps

from flask import jsonify, request
from flask_jwt_extended import get_jwt, verify_jwt_in_request


EMAIL_PATTERN = re.compile(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$", re.IGNORECASE)


class InMemoryRateLimiter:
    """Small process-local limiter for development and test deployments."""

    def __init__(self) -> None:
        self._hits = defaultdict(deque)

    def is_allowed(self, key: str, limit: int, window_seconds: int) -> bool:
        """Record one hit and report whether the key remains under the limit."""
        now = time.time()
        timestamps = self._hits[key]
        cutoff = now - window_seconds

        while timestamps and timestamps[0] <= cutoff:
            timestamps.popleft()

        if len(timestamps) >= limit:
            return False

        timestamps.append(now)
        return True

    def reset(self) -> None:
        """Clear tracked hits, mainly for deterministic tests."""
        self._hits.clear()


rate_limiter = InMemoryRateLimiter()


def rate_limit(limit: int, window_seconds: int, scope: str):
    """Limit requests for a route by client IP and logical scope."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            client_ip = request.headers.get("X-Forwarded-For", request.remote_addr or "unknown")
            key = f"{scope}:{client_ip}"
            if not rate_limiter.is_allowed(key, limit=limit, window_seconds=window_seconds):
                return (
                    jsonify(
                        {
                            "message": "Too many requests. Please wait a moment and try again.",
                        }
                    ),
                    429,
                )
            return func(*args, **kwargs)

        return wrapper

    return decorator


def require_role(*allowed_roles: str):
    """Require a JWT with one of the allowed role claims."""
    normalized_roles = {role.strip().lower() for role in allowed_roles if role.strip()}

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            claims = get_jwt()
            role = (claims.get("role") or "").strip().lower()
            if role not in normalized_roles:
                return jsonify({"message": "You do not have permission to access this resource."}), 403
            return func(*args, **kwargs)

        return wrapper

    return decorator


def is_valid_email(email: str) -> bool:
    """Return whether a string looks like a valid email address."""
    return bool(EMAIL_PATTERN.fullmatch(email or ""))


def is_valid_name(name: str) -> bool:
    """Return whether a display name is within accepted length bounds."""
    cleaned = (name or "").strip()
    return 2 <= len(cleaned) <= 120


def is_valid_password(password: str) -> bool:
    """Return whether a password length matches current policy."""
    return 8 <= len(password or "") <= 128


def sanitize_text(value: str, *, max_length: int) -> str:
    """Collapse whitespace and cap untrusted text to a maximum length."""
    cleaned = " ".join((value or "").strip().split())
    return cleaned.replace("<", "").replace(">", "")[:max_length]
