import json
import uuid
from urllib import error, request as urllib_request

from flask import Blueprint, jsonify, request

report_bp = Blueprint("report", __name__)
ML_API_URL = "http://127.0.0.1:5001/analyze-report"
ML_SYMPTOM_API_URL = "http://127.0.0.1:5001/analyze-symptoms"


@report_bp.route("/upload-report", methods=["POST"])
def upload_report():
    if "file" not in request.files:
        return jsonify({"message": "No file uploaded"}), 400

    uploaded_file = request.files["file"]

    if uploaded_file.filename == "":
        return jsonify({"message": "Empty file name"}), 400

    if not uploaded_file.filename.lower().endswith(".pdf"):
        return jsonify({"message": "Only PDF files are supported"}), 400

    try:
        file_bytes = uploaded_file.read()
        if not file_bytes:
            return jsonify({"message": "Uploaded PDF is empty"}), 400

        analysis_result = _forward_report_to_ml_api(
            file_bytes=file_bytes,
            filename=uploaded_file.filename,
            content_type=uploaded_file.mimetype or "application/pdf",
        )

        analysis_result["message"] = "Report analyzed successfully"
        return jsonify(analysis_result), 200
    except RuntimeError as exc:
        return jsonify({"message": str(exc)}), 502
    except Exception as exc:
        return jsonify({"message": f"Failed to analyze report: {str(exc)}"}), 500


@report_bp.route("/analyze-symptoms", methods=["POST"])
def analyze_symptoms():
    payload = request.get_json(silent=True) or {}
    symptoms_text = (payload.get("symptoms_text") or "").strip()
    if not symptoms_text:
        return jsonify({"message": "symptoms_text is required"}), 400

    try:
        analysis_result = _forward_symptoms_to_ml_api(symptoms_text)
        analysis_result["message"] = "Symptoms analyzed successfully"
        return jsonify(analysis_result), 200
    except RuntimeError as exc:
        return jsonify({"message": str(exc)}), 502
    except Exception as exc:
        return jsonify({"message": f"Failed to analyze symptoms: {str(exc)}"}), 500


def _forward_report_to_ml_api(file_bytes, filename, content_type):
    boundary = f"----MiniBoundary{uuid.uuid4().hex}"
    body = _build_multipart_body(boundary, file_bytes, filename, content_type)

    outgoing_request = urllib_request.Request(
        ML_API_URL,
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )

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


def _build_multipart_body(boundary, file_bytes, filename, content_type):
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


def _forward_symptoms_to_ml_api(symptoms_text):
    body = json.dumps({"symptoms_text": symptoms_text}).encode("utf-8")
    outgoing_request = urllib_request.Request(
        ML_SYMPTOM_API_URL,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

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
