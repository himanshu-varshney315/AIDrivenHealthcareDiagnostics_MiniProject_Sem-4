from flask import Flask, jsonify, request

from Ml_model.predict import analyze_medical_report_text, analyze_symptom_text
from Ml_model.utils.pdf_extractor import extract_text_from_pdf_bytes, ocr_is_available


app = Flask(__name__)


@app.route("/analyze-report", methods=["POST"])
def analyze_report() -> tuple:
    if "file" not in request.files:
        return jsonify({"message": "No file uploaded"}), 400

    uploaded_file = request.files["file"]
    if not uploaded_file.filename:
        return jsonify({"message": "Empty file name"}), 400
    if not uploaded_file.filename.lower().endswith(".pdf"):
        return jsonify({"message": "Only PDF files are supported"}), 400

    extracted_text = extract_text_from_pdf_bytes(uploaded_file.read())
    if not extracted_text:
        message = "Could not extract text from PDF"
        if not ocr_is_available():
            message += ". This PDF appears scanned or image-based. Install Tesseract OCR and pytesseract for OCR support."
        return jsonify({"message": message}), 400

    result = analyze_medical_report_text(extracted_text)
    return (
        jsonify(
            {
                "prediction": result["prediction"],
                "confidence": result["confidence"],
                "extracted_symptoms": result["extracted_symptoms"],
                "explanation": result["explanation"],
                "entities": result["entities"],
                "probabilities": result["probabilities"],
                "recommendations": result["recommendations"],
                "precautions": result["precautions"],
                "recommended_medicines": result["recommended_medicines"],
                "seek_care": result["seek_care"],
                "urgency": result["urgency"],
            }
        ),
        200,
    )


@app.route("/analyze-symptoms", methods=["POST"])
def analyze_symptoms() -> tuple:
    data = request.get_json(silent=True) or {}
    symptoms_text = (data.get("symptoms_text") or "").strip()
    if not symptoms_text:
        return jsonify({"message": "symptoms_text is required"}), 400

    result = analyze_symptom_text(symptoms_text)
    return (
        jsonify(
            {
                "prediction": result["prediction"],
                "confidence": result["confidence"],
                "extracted_symptoms": result["extracted_symptoms"],
                "explanation": result["explanation"],
                "entities": result["entities"],
                "probabilities": result["probabilities"],
                "recommendations": result["recommendations"],
                "precautions": result["precautions"],
                "recommended_medicines": result["recommended_medicines"],
                "seek_care": result["seek_care"],
                "urgency": result["urgency"],
            }
        ),
        200,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)
