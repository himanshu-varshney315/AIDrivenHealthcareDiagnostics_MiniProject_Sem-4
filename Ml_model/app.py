from flask import Flask, jsonify, request

from Ml_model.predict import analyze_medical_image_file_bytes, analyze_medical_report_text, analyze_symptom_text
from Ml_model.utils.pdf_extractor import extract_text_from_file_bytes, ocr_is_available


app = Flask(__name__)


@app.route("/analyze-report", methods=["POST"])
def analyze_report() -> tuple:
    if "file" not in request.files:
        return jsonify({"message": "No file uploaded"}), 400

    uploaded_file = request.files["file"]
    if not uploaded_file.filename:
        return jsonify({"message": "Empty file name"}), 400
    supported_extensions = (".pdf", ".txt", ".png", ".jpg", ".jpeg")
    if not uploaded_file.filename.lower().endswith(supported_extensions):
        return jsonify({"message": "Only PDF, TXT, PNG, JPG, and JPEG files are supported"}), 400

    file_bytes = uploaded_file.read()
    extracted_text = extract_text_from_file_bytes(
        file_bytes,
        filename=uploaded_file.filename,
    )
    is_image = uploaded_file.filename.lower().endswith((".png", ".jpg", ".jpeg"))
    if not extracted_text and not is_image:
        message = "Could not extract text from report"
        if not ocr_is_available():
            message += ". Image and scanned report support requires Tesseract OCR and pytesseract."
        return jsonify({"message": message}), 400

    if is_image:
        result = analyze_medical_image_file_bytes(file_bytes, extracted_text=extracted_text)
    else:
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
                "task": result.get("task", "report"),
                "image_prediction": result.get("image_prediction"),
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
