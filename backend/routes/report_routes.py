from flask import Blueprint, jsonify, request
from services.pdf_reader import extract_text_from_pdf
from services.analyzer import analyze_report_text

report_bp = Blueprint("report", __name__)


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
        extracted_text = extract_text_from_pdf(file_bytes)

        if not extracted_text:
            return jsonify({"message": "Could not extract text from PDF"}), 400

        analysis_result = analyze_report_text(extracted_text)

        return jsonify(
            {
                "message": "Report analyzed successfully",
                "prediction": analysis_result["prediction"],
                "risk_percentage": analysis_result["risk_percentage"],
                "factors": analysis_result["factors"],
            }
        ), 200
    except Exception as exc:
        return jsonify({"message": f"Failed to analyze report: {str(exc)}"}), 500
