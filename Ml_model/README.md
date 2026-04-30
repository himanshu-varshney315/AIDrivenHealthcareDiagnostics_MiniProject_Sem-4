# AI-Based Medical Report Analysis and Diagnosis Support System

This folder contains a standalone ML module for training and serving a medical report disease predictor.

## Features

- PDF text extraction using `pdfplumber` with PyMuPDF fallback
- TXT and image report extraction, with OCR for PNG/JPG files when Tesseract is installed
- Text preprocessing and tokenization
- Entity extraction for symptoms, diseases, medications, and lab values
- Baseline disease classification using `scikit-learn`
- Standalone Flask API for testing and later integration

## Structure

```text
Ml_model/
  dataset/
  models/
  nlp_model/
  training/
  utils/
  app.py
  predict.py
  train.py
  requirements.txt
```

## Install

```bash
pip install -r Ml_model/requirements.txt
```

Optional transformer-based NER:

```bash
set ENABLE_MEDICAL_NER=1
```

## Train

```bash
python -m Ml_model.train
```

Optional dataset path:

```bash
python -m Ml_model.train --dataset path/to/reports.csv
```

## Run API

```bash
python -m Ml_model.app
```

API endpoint:

```http
POST /analyze-report
```

Form field:

- `file`: PDF, TXT, PNG, JPG, or JPEG medical report

Response shape:

```json
{
  "prediction": "Pneumonia",
  "confidence": 0.84,
  "extracted_symptoms": ["cough", "fever", "shortness of breath"],
  "explanation": "The model suggests Pneumonia with 84.0% confidence based on symptoms such as cough, fever, shortness of breath and report findings including oxygen_saturation: 91.",
  "entities": {
    "symptoms": ["cough", "fever", "shortness of breath"],
    "diseases": ["pneumonia"],
    "medications": [],
    "lab_values": ["oxygen_saturation: 91"]
  },
  "probabilities": {
    "Pneumonia": 0.84
  }
}
```

## Metrics

Training reports:

- Accuracy
- Precision
- Recall
- F1 Score

## Notes

- The included dataset is a small starter dataset for demo and development.
- The module is isolated from the main app until you choose to integrate it.
