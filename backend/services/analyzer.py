import re


def _extract_numeric_value(text, labels):
    for label in labels:
        pattern = rf"{label}\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)"
        match = re.search(pattern, text, flags=re.IGNORECASE)
        if match:
            return float(match.group(1))
    return None


def analyze_report_text(raw_text):
    text = raw_text.lower()
    risk_score = 0
    factors = []

    glucose = _extract_numeric_value(text, ["glucose", "blood sugar", "fbs", "rbs"])
    hba1c = _extract_numeric_value(text, ["hba1c", "a1c"])
    cholesterol = _extract_numeric_value(text, ["cholesterol", "total cholesterol"])
    systolic_bp = _extract_numeric_value(text, ["systolic", "sbp"])
    diastolic_bp = _extract_numeric_value(text, ["diastolic", "dbp"])
    bmi = _extract_numeric_value(text, ["bmi", "body mass index"])

    if glucose is not None:
        if glucose >= 200:
            risk_score += 30
            factors.append(f"Very high glucose ({glucose})")
        elif glucose >= 126:
            risk_score += 20
            factors.append(f"High glucose ({glucose})")
        elif glucose >= 100:
            risk_score += 10
            factors.append(f"Borderline glucose ({glucose})")

    if hba1c is not None:
        if hba1c >= 6.5:
            risk_score += 25
            factors.append(f"High HbA1c ({hba1c})")
        elif hba1c >= 5.7:
            risk_score += 10
            factors.append(f"Borderline HbA1c ({hba1c})")

    if cholesterol is not None:
        if cholesterol >= 240:
            risk_score += 20
            factors.append(f"Very high cholesterol ({cholesterol})")
        elif cholesterol >= 200:
            risk_score += 12
            factors.append(f"High cholesterol ({cholesterol})")

    if systolic_bp is not None or diastolic_bp is not None:
        if (systolic_bp is not None and systolic_bp >= 140) or (
            diastolic_bp is not None and diastolic_bp >= 90
        ):
            risk_score += 20
            factors.append("High blood pressure range")
        elif (systolic_bp is not None and systolic_bp >= 130) or (
            diastolic_bp is not None and diastolic_bp >= 80
        ):
            risk_score += 10
            factors.append("Elevated blood pressure range")

    if bmi is not None:
        if bmi >= 30:
            risk_score += 15
            factors.append(f"Obesity BMI ({bmi})")
        elif bmi >= 25:
            risk_score += 8
            factors.append(f"Overweight BMI ({bmi})")

    for keyword in ["diabetes", "hypertension", "heart disease", "stroke", "smoker"]:
        if keyword in text:
            risk_score += 8
            factors.append(f"History keyword detected: {keyword}")

    risk_percentage = max(0, min(100, int(risk_score)))

    if risk_percentage >= 60:
        prediction = "High Risk"
    elif risk_percentage >= 30:
        prediction = "Moderate Risk"
    else:
        prediction = "Low Risk"

    if not factors:
        factors.append("No major risk marker detected in parsed text")

    return {
        "prediction": prediction,
        "risk_percentage": risk_percentage,
        "factors": factors,
    }
