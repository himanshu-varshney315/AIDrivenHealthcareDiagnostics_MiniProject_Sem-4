def score_wearable_risk(summary, recent_summaries=None):
    """Return an educational risk score from wearable daily aggregates."""
    recent_summaries = recent_summaries or []
    score = 0
    factors = []
    recommendations = []

    latest_hr = _number_or_none(summary.get("latest_heart_rate"))
    average_hr = _number_or_none(summary.get("average_heart_rate"))
    steps = _number_or_none(summary.get("steps"))
    sleep_minutes = _number_or_none(summary.get("sleep_minutes"))
    spo2 = _number_or_none(summary.get("spo2"))

    if latest_hr is not None:
        if latest_hr >= 120:
            score += 35
            factors.append(f"Very high latest heart rate ({latest_hr:.0f} bpm)")
        elif latest_hr >= 100:
            score += 18
            factors.append(f"Elevated latest heart rate ({latest_hr:.0f} bpm)")
        elif latest_hr < 50:
            score += 22
            factors.append(f"Low latest heart rate ({latest_hr:.0f} bpm)")

    if average_hr is not None and average_hr >= 100:
        score += 18
        factors.append(f"High average heart rate ({average_hr:.0f} bpm)")

    if steps is not None:
        if steps < 2000:
            score += 16
            factors.append("Very low activity today")
        elif steps < 5000:
            score += 8
            factors.append("Activity is below the usual daily target")

    if sleep_minutes is not None:
        if sleep_minutes < 300:
            score += 18
            factors.append("Sleep duration is under 5 hours")
        elif sleep_minutes < 420:
            score += 8
            factors.append("Sleep duration is under 7 hours")

    if spo2 is not None:
        if spo2 < 92:
            score += 35
            factors.append(f"Low oxygen saturation ({spo2:.0f}%)")
        elif spo2 < 95:
            score += 18
            factors.append(f"Borderline oxygen saturation ({spo2:.0f}%)")

    prior_abnormal_days = sum(
        1
        for item in recent_summaries[:6]
        if getattr(item, "risk_level", "low") in {"moderate", "high"}
    )
    if prior_abnormal_days >= 2:
        score += 10
        factors.append("Similar risk markers appeared on recent days")

    score = max(0, min(100, int(score)))
    if score >= 60:
        risk_level = "high"
        recommendations.extend(
            [
                "Consider prompt clinical advice if these readings are accurate or symptoms are present.",
                "Recheck vitals after resting and seek urgent care for chest pain, breathlessness, fainting, or confusion.",
            ]
        )
    elif score >= 30:
        risk_level = "moderate"
        recommendations.extend(
            [
                "Watch today's trend and repeat readings after rest.",
                "Improve hydration, sleep, and light activity if safe for you.",
            ]
        )
    else:
        risk_level = "low"
        recommendations.extend(
            [
                "Keep syncing wearable data to build a more useful trend.",
                "Use clinician advice for symptoms or readings that feel unusual for you.",
            ]
        )

    if not factors:
        factors.append("No major wearable risk marker detected today")

    return {
        "risk_score": score,
        "risk_level": risk_level,
        "factors": factors,
        "recommendations": recommendations,
        "model_task": "vitals_risk_scoring_mvp",
    }


def _number_or_none(value):
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None
