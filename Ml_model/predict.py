from functools import lru_cache
from pathlib import Path
from typing import Dict, List

try:
    import joblib
except ImportError:  # pragma: no cover
    joblib = None

from Ml_model.nlp_model.entity_extractor import EntityExtractor
from Ml_model.utils.preprocessing import preprocess_text


MODEL_DIR = Path(__file__).resolve().parent / "models"
MODEL_PATHS = {
    "report": MODEL_DIR / "report_disease_classifier.joblib",
    "symptom": MODEL_DIR / "symptom_disease_classifier.joblib",
}


REPORT_DISEASE_KEYWORDS = {
    "Diabetes": ["glucose", "hba1c", "a1c", "frequent urination", "thirst", "blurred vision", "polyuria"],
    "Hypertension": ["blood pressure", "bp", "systolic", "diastolic", "headache", "hypertension"],
    "Pneumonia": ["fever", "cough", "shortness of breath", "infiltrate", "consolidation", "spo2"],
    "Anemia": ["hemoglobin", "hb", "pallor", "fatigue", "dizziness", "iron deficiency"],
    "Heart Disease": ["chest pain", "ecg", "troponin", "palpitations", "edema", "coronary", "heart failure"],
    "Dengue": ["dengue", "platelet", "thrombocytopenia", "rash", "body ache", "joint pain", "ns1"],
    "Asthma": ["wheeze", "wheezing", "chest tightness", "shortness of breath", "night cough", "inhaler"],
    "Stroke": ["facial droop", "slurred speech", "arm weakness", "vision loss", "sudden dizziness", "stroke"],
    "Chikungunya": ["high fever", "joint pain", "severe joint pain", "rash", "chikungunya", "mosquito bite"],
    "Acute Diarrheal Disease": ["diarrhea", "diarrhoea", "loose stool", "vomiting", "dehydration", "oral rehydration"],
}

SYMPTOM_DISEASE_KEYWORDS = {
    **REPORT_DISEASE_KEYWORDS,
    "Common Cold": ["runny nose", "sneezing", "sore throat", "nasal congestion", "cold"],
    "Influenza": ["flu", "influenza", "high fever", "body ache", "chills", "dry cough"],
    "Allergic Rhinitis": ["allergy", "sneezing", "itchy eyes", "watery eyes", "hay fever", "runny nose"],
    "Viral Gastroenteritis": ["diarrhea", "loose motions", "vomiting", "nausea", "stomach flu", "abdominal pain"],
    "Migraine": ["migraine", "throbbing", "headache", "light sensitivity", "sound sensitivity", "aura"],
}

DISEASE_GUIDANCE = {
    "Diabetes": {
        "recommendations": [
            "Monitor blood sugar regularly and keep a note of recent readings.",
            "Prefer low-sugar, balanced meals and avoid sugary drinks.",
            "Schedule a physician review if symptoms are new or worsening.",
        ],
        "precautions": [
            "Seek urgent care if vomiting, confusion, or dehydration appears.",
            "Do not skip prescribed diabetes medicines without advice.",
            "Watch for blurred vision, foot numbness, or increased urination.",
        ],
        "recommended_medicines": [
            "Do not change diabetes medicines without clinician advice.",
            "Only use glucose-lowering medicines exactly as already prescribed.",
        ],
        "seek_care": "See a doctor soon if blood sugar stays high or symptoms keep increasing.",
        "urgency": "medium",
    },
    "Hypertension": {
        "recommendations": [
            "Check blood pressure more than once and note the readings.",
            "Reduce excess salt intake and avoid tobacco if applicable.",
            "Arrange a medical follow-up for sustained high blood pressure readings.",
        ],
        "precautions": [
            "Seek urgent care for chest pain, severe headache, or vision changes.",
            "Do not stop blood pressure medicines abruptly.",
            "Limit high-sodium packaged foods and manage stress where possible.",
        ],
        "recommended_medicines": [
            "Continue prescribed blood pressure medicines unless a clinician tells you otherwise.",
            "Do not self-start new blood pressure tablets without medical advice.",
        ],
        "seek_care": "Prompt medical review is advised if blood pressure remains elevated or symptoms intensify.",
        "urgency": "medium",
    },
    "Pneumonia": {
        "recommendations": [
            "Rest, take fluids, and monitor fever and breathing symptoms closely.",
            "Use medical evaluation promptly if cough and fever persist.",
            "Track oxygen saturation if you have a pulse oximeter.",
        ],
        "precautions": [
            "Seek urgent care for shortness of breath or low oxygen levels.",
            "Avoid exertion while chest symptoms are active.",
            "Do not delay evaluation if fever is persistent with cough and chest findings.",
        ],
        "recommended_medicines": [
            "Acetaminophen/paracetamol may help fever if safe for you.",
            "Prescription treatment may be needed depending on the cause, so medical review is important.",
        ],
        "seek_care": "Same-day medical review is recommended for worsening cough, fever, or breathing trouble.",
        "urgency": "high",
    },
    "Anemia": {
        "recommendations": [
            "Get a complete blood count or physician review if weakness is ongoing.",
            "Maintain iron-rich meals unless a doctor has told you otherwise.",
            "Discuss the cause of anemia rather than self-treating blindly.",
        ],
        "precautions": [
            "Seek medical help if there is fainting, severe weakness, or shortness of breath.",
            "Do not start iron supplements in excess without medical advice.",
            "Monitor fatigue, pallor, and dizziness if symptoms continue.",
        ],
        "recommended_medicines": [
            "Iron supplements should only be used as advised after confirming the cause.",
            "Avoid self-medicating heavily without blood test review.",
        ],
        "seek_care": "Medical assessment is advised if symptoms are persistent or lab values are low.",
        "urgency": "medium",
    },
    "Heart Disease": {
        "recommendations": [
            "Seek professional cardiac evaluation, especially with chest symptoms.",
            "Keep a note of chest pain timing, exertion triggers, and palpitations.",
            "Avoid heavy exertion until reviewed if chest symptoms are active.",
        ],
        "precautions": [
            "Treat chest pain, fainting, or severe breathlessness as urgent.",
            "Do not ignore symptoms with ECG changes or rising cardiac markers.",
            "Emergency care is needed for crushing chest pain or sudden collapse.",
        ],
        "recommended_medicines": [
            "Do not self-medicate for possible heart-related chest pain.",
            "Urgent clinician evaluation is more important than OTC symptom treatment here.",
        ],
        "seek_care": "Urgent medical review is recommended for chest pain, abnormal ECG findings, or breathlessness.",
        "urgency": "high",
    },
    "Dengue": {
        "recommendations": [
            "Increase oral fluids and monitor fever, platelets, and hydration.",
            "Use medical review for confirmed or suspected dengue, especially with low platelets.",
            "Prefer paracetamol if fever control is needed and medically suitable.",
        ],
        "precautions": [
            "Avoid ibuprofen or aspirin unless a doctor specifically advises them.",
            "Seek urgent care for bleeding, severe abdominal pain, or persistent vomiting.",
            "Track platelet count and warning signs during the fever period.",
        ],
        "recommended_medicines": [
            "Acetaminophen/paracetamol may help fever if safe for you.",
            "Avoid aspirin and ibuprofen unless specifically advised by a clinician.",
        ],
        "seek_care": "Medical evaluation is recommended quickly if dengue is suspected or warning signs appear.",
        "urgency": "high",
    },
    "Common Cold": {
        "recommendations": [
            "Rest, drink fluids, and monitor whether symptoms improve over the next few days.",
            "Use saline nasal spray or steam for congestion relief.",
            "Avoid unnecessary antibiotics for typical cold symptoms.",
        ],
        "precautions": [
            "Seek care if breathing becomes difficult or symptoms worsen instead of improving.",
            "Watch for persistent fever or symptoms lasting longer than expected.",
            "Stay hydrated and reduce exposure to smoke or dust.",
        ],
        "recommended_medicines": [
            "Saline nasal spray or drops may help congestion.",
            "Honey may help cough in adults and children older than 1 year.",
            "Acetaminophen/paracetamol may help aches or fever if safe for you.",
        ],
        "seek_care": "See a doctor if breathing trouble, chest pain, or worsening symptoms appear.",
        "urgency": "low",
    },
    "Influenza": {
        "recommendations": [
            "Rest, hydrate, and monitor fever and body aches closely.",
            "A clinician review is useful early, especially if symptoms started recently.",
            "People at higher risk for complications should seek prompt medical advice.",
        ],
        "precautions": [
            "Seek care urgently for breathing trouble, confusion, or dehydration.",
            "Antibiotics do not treat influenza unless a bacterial infection is confirmed.",
            "High-risk patients should contact a clinician early about antiviral treatment.",
        ],
        "recommended_medicines": [
            "Acetaminophen/paracetamol may help fever or aches if safe for you.",
            "Prescription antivirals may help if started early and prescribed by a clinician.",
            "Fluids and oral rehydration may help if intake is reduced.",
        ],
        "seek_care": "Prompt medical care is recommended for severe symptoms or if you are at higher risk of flu complications.",
        "urgency": "medium",
    },
    "Allergic Rhinitis": {
        "recommendations": [
            "Reduce pollen or dust exposure where possible and keep windows closed during heavy pollen times.",
            "Consider daily symptom control during allergy season if symptoms are frequent.",
            "Track common triggers such as pollen, dust, or pets.",
        ],
        "precautions": [
            "Seek care if wheezing, breathing difficulty, or severe swelling occurs.",
            "Use medicines as directed and ask a clinician about the best option for you.",
            "Avoid known triggers where practical.",
        ],
        "recommended_medicines": [
            "An over-the-counter antihistamine may help if suitable for you.",
            "Saline nasal rinse or saline spray may reduce nasal irritation.",
            "Ask a clinician or pharmacist before combining antihistamines with decongestants.",
        ],
        "seek_care": "See a doctor if symptoms are persistent, severe, or affect breathing or sleep.",
        "urgency": "low",
    },
    "Viral Gastroenteritis": {
        "recommendations": [
            "Focus on hydration and replace fluids slowly with water or oral rehydration solution.",
            "Rest and eat light foods only as tolerated.",
            "Monitor for signs of dehydration if vomiting or diarrhea continues.",
        ],
        "precautions": [
            "Seek urgent care if you cannot keep fluids down or there are signs of dehydration.",
            "Avoid anti-diarrheal medicines without advice if there is high fever or bloody stool.",
            "Wash hands well to reduce spread to others.",
        ],
        "recommended_medicines": [
            "Oral rehydration solution is often the most useful first step.",
            "Acetaminophen/paracetamol may be used for fever if safe for you.",
            "Ask a clinician before using anti-diarrheal medicines if symptoms are severe.",
        ],
        "seek_care": "See a doctor if dehydration, persistent vomiting, blood in stool, or prolonged diarrhea occurs.",
        "urgency": "medium",
    },
    "Migraine": {
        "recommendations": [
            "Rest in a quiet, dark room and reduce screen exposure.",
            "Hydrate and try to identify triggers such as sleep loss, skipped meals, or stress.",
            "Use a symptom diary if headaches recur.",
        ],
        "precautions": [
            "Seek urgent care for new neurological symptoms, weakness, speech trouble, or a sudden severe headache.",
            "Do not overuse pain medicines repeatedly without medical advice.",
            "Recurring or worsening migraines should be medically evaluated.",
        ],
        "recommended_medicines": [
            "Acetaminophen/paracetamol may help if safe for you.",
            "Ibuprofen or naproxen may help some people if they are safe for you and medically appropriate.",
            "Prescription migraine medicines may be needed for recurrent attacks.",
        ],
        "seek_care": "Get medical care for severe, frequent, or unusual headaches, especially with neurological symptoms.",
        "urgency": "medium",
    },
    "Asthma": {
        "recommendations": [
            "Avoid smoke, dust, and other known triggers while symptoms are active.",
            "Use prescribed reliever/controller inhalers exactly as directed by your clinician.",
            "Arrange medical review if cough, wheeze, or chest tightness keeps returning.",
        ],
        "precautions": [
            "Seek urgent care if speaking is difficult, breathing worsens, or lips look blue.",
            "Do not rely on repeated reliever use alone if symptoms are escalating.",
            "Night-time symptoms or symptoms at rest need prompt review.",
        ],
        "recommended_medicines": [
            "Only use inhalers already prescribed to you and use the spacer/device correctly.",
            "Ask a clinician about inhaled corticosteroid access if symptoms recur.",
        ],
        "seek_care": "Urgent medical care is recommended for worsening shortness of breath, severe wheeze, or poor response to inhaler use.",
        "urgency": "high",
    },
    "Stroke": {
        "recommendations": [
            "Treat sudden face droop, arm weakness, vision loss, or speech trouble as an emergency.",
            "Note the exact time symptoms started because urgent treatment depends on timing.",
            "Use emergency medical services immediately rather than waiting for symptoms to pass.",
        ],
        "precautions": [
            "Do not drive yourself if stroke symptoms are suspected.",
            "Do not delay urgent assessment because rapid treatment can reduce disability.",
            "A transient improvement can still represent a medical emergency.",
        ],
        "recommended_medicines": [
            "Do not self-start aspirin or other medicines unless a clinician has advised it after evaluation.",
            "Immediate medical assessment is more important than home treatment.",
        ],
        "seek_care": "Emergency medical evaluation is needed immediately for any suspected stroke symptoms.",
        "urgency": "high",
    },
    "Chikungunya": {
        "recommendations": [
            "Rest, take fluids, and monitor fever and joint pain closely.",
            "Prevent mosquito bites while ill to reduce further spread.",
            "Use medical review if fever and joint pain are significant or persistent.",
        ],
        "precautions": [
            "Seek urgent care for dehydration, confusion, severe weakness, or vulnerable age groups.",
            "Because symptoms overlap with dengue, worsening illness needs medical review.",
            "Persistent joint pain after fever should still be medically assessed.",
        ],
        "recommended_medicines": [
            "Acetaminophen/paracetamol may help fever or pain if safe for you.",
            "Ask a clinician before using NSAIDs when dengue has not been ruled out.",
        ],
        "seek_care": "Prompt medical review is recommended for high fever with severe joint pain or worsening symptoms.",
        "urgency": "medium",
    },
    "Acute Diarrheal Disease": {
        "recommendations": [
            "Start oral rehydration solution or fluids early to prevent dehydration.",
            "Keep taking small frequent sips even if nausea is present.",
            "Monitor urine output, thirst, weakness, and the ability to keep fluids down.",
        ],
        "precautions": [
            "Seek urgent care for severe dehydration, confusion, lethargy, or inability to drink.",
            "Blood in stool, ongoing vomiting, or shock symptoms need rapid evaluation.",
            "Wash hands carefully to reduce spread to others.",
        ],
        "recommended_medicines": [
            "Oral rehydration solution is often the first supportive step if safe and available.",
            "Use antidiarrheal medicines only with clinician advice when symptoms are severe or atypical.",
        ],
        "seek_care": "Medical care is recommended quickly if dehydration signs, bloody stool, or persistent vomiting are present.",
        "urgency": "medium",
    },
}

RED_FLAG_TERMS = {
    "chest pain",
    "shortness of breath",
    "breathing difficulty",
    "unconscious",
    "seizure",
    "bleeding",
    "blood in stool",
    "blood in vomit",
    "persistent vomiting",
    "slurred speech",
    "face droop",
    "facial droop",
    "arm weakness",
    "vision loss",
    "wheezing at rest",
    "cannot breathe",
    "severe dehydration",
}

SYMPTOM_SAFETY_PRIORS = {
    "Common Cold": 1.2,
    "Allergic Rhinitis": 1.15,
    "Influenza": 1.08,
    "Migraine": 1.0,
    "Viral Gastroenteritis": 1.0,
    "Anemia": 0.96,
    "Hypertension": 0.95,
    "Diabetes": 0.94,
    "Dengue": 0.8,
    "Pneumonia": 0.72,
    "Heart Disease": 0.68,
    "Stroke": 0.5,
    "Asthma": 0.9,
    "Chikungunya": 0.88,
    "Acute Diarrheal Disease": 0.98,
}

SEVERE_DISEASES = {"Pneumonia", "Heart Disease", "Dengue", "Stroke"}
COMMON_MILD_DISEASES = {"Common Cold", "Influenza", "Allergic Rhinitis"}
SEVERE_SUPPORT_TERMS = {
    "Pneumonia": {"shortness of breath", "breathing difficulty", "low oxygen", "spo2", "chest congestion", "sputum"},
    "Heart Disease": {"chest pain", "palpitations", "chest tightness", "swelling", "breathless", "edema"},
    "Dengue": {"rash", "joint pain", "retro orbital pain", "platelet", "body ache", "muscle pain"},
    "Stroke": {"slurred speech", "facial droop", "face droop", "arm weakness", "vision loss", "sudden dizziness"},
}


class HeuristicPredictor:
    def __init__(self, task: str) -> None:
        self.task = task

    def predict(self, text: str) -> tuple[str, float, Dict[str, float]]:
        lowered = text.lower()
        scores: Dict[str, float] = {}
        keyword_map = REPORT_DISEASE_KEYWORDS if self.task == "report" else SYMPTOM_DISEASE_KEYWORDS
        for disease, keywords in keyword_map.items():
            matched = sum(1 for keyword in keywords if keyword in lowered)
            scores[disease] = matched / max(len(keywords), 1)

        predicted = max(scores, key=scores.get)
        raw_confidence = scores[predicted]
        normalized_scores = _normalize_scores(scores)
        return predicted, max(raw_confidence, normalized_scores[predicted]), normalized_scores


@lru_cache(maxsize=1)
def _load_artifact(task: str) -> dict | None:
    if joblib is None:
        return None
    model_path = MODEL_PATHS[task]
    if not Path(model_path).exists():
        return None
    return joblib.load(model_path)


@lru_cache(maxsize=1)
def _get_entity_extractor() -> EntityExtractor:
    return EntityExtractor()


def analyze_medical_report_text(text: str) -> Dict[str, object]:
    return _analyze_text(text, task="report")


def analyze_symptom_text(text: str) -> Dict[str, object]:
    return _analyze_text(text, task="symptom")


def _analyze_text(text: str, task: str) -> Dict[str, object]:
    processed_text = preprocess_text(text)
    entities = _get_entity_extractor().extract(text)
    heuristic_label, heuristic_confidence, heuristic_probabilities = HeuristicPredictor(task).predict(text)

    artifact = _load_artifact(task)
    if artifact is None:
        predicted_label, confidence, probabilities = heuristic_label, heuristic_confidence, heuristic_probabilities
    else:
        pipeline = artifact["pipeline"]
        probability_matrix = pipeline.predict_proba([processed_text])[0]
        labels = pipeline.classes_
        model_probabilities = {label: float(score) for label, score in zip(labels, probability_matrix)}
        combined_probabilities = _blend_probabilities(
            model_probabilities,
            heuristic_probabilities,
            raw_text=text,
            entities=entities,
            task=task,
        )
        ranked_probabilities = sorted(
            combined_probabilities.items(),
            key=lambda item: item[1],
            reverse=True,
        )
        predicted_label = ranked_probabilities[0][0]
        confidence = ranked_probabilities[0][1]
        probabilities = {
            label: round(score, 4)
            for label, score in ranked_probabilities
        }

    explanation = _build_explanation(predicted_label, confidence, entities)
    guidance = _build_guidance(predicted_label, text, task=task)
    return {
        "task": task,
        "prediction": predicted_label,
        "confidence": round(float(confidence), 4),
        "extracted_symptoms": entities["symptoms"],
        "entities": entities,
        "explanation": explanation,
        "probabilities": probabilities,
        "recommendations": guidance["recommendations"],
        "precautions": guidance["precautions"],
        "recommended_medicines": guidance["recommended_medicines"],
        "seek_care": guidance["seek_care"],
        "urgency": guidance["urgency"],
    }


def _normalize_scores(scores: Dict[str, float]) -> Dict[str, float]:
    total = sum(scores.values())
    if total <= 0:
        uniform = round(1 / len(scores), 4)
        return {label: uniform for label in scores}
    return {label: round(score / total, 4) for label, score in scores.items()}


def _blend_probabilities(
    model_probabilities: Dict[str, float],
    heuristic_probabilities: Dict[str, float],
    raw_text: str,
    entities: Dict[str, List[str]],
    task: str,
) -> Dict[str, float]:
    labels = sorted(set(model_probabilities) | set(heuristic_probabilities))
    blended = {}
    model_weight = 0.78 if task == "report" else 0.58
    heuristic_weight = 1.0 - model_weight
    for label in labels:
        model_score = model_probabilities.get(label, 0.0)
        heuristic_score = heuristic_probabilities.get(label, 0.0)
        blended[label] = (model_weight * model_score) + (heuristic_weight * heuristic_score)

    if task == "symptom":
        blended = _apply_symptom_safety_bias(blended, raw_text=raw_text, entities=entities)

    total = sum(blended.values())
    if total <= 0:
        return {label: 1 / len(labels) for label in labels}
    return {label: score / total for label, score in blended.items()}


def _apply_symptom_safety_bias(
    probabilities: Dict[str, float],
    raw_text: str,
    entities: Dict[str, List[str]],
) -> Dict[str, float]:
    lowered = raw_text.lower()
    token_count = len(preprocess_text(raw_text).split())
    symptom_count = len(entities.get("symptoms") or [])
    red_flag_present = any(term in lowered for term in RED_FLAG_TERMS)
    is_ambiguous = token_count <= 4 or symptom_count <= 1

    adjusted = {}
    for label, score in probabilities.items():
        adjusted_score = score * SYMPTOM_SAFETY_PRIORS.get(label, 1.0)
        support_terms = SEVERE_SUPPORT_TERMS.get(label, set())
        support_hits = sum(1 for term in support_terms if term in lowered)

        if label in SEVERE_DISEASES and not red_flag_present:
            if support_hits == 0:
                adjusted_score *= 0.45 if is_ambiguous else 0.7
            elif support_hits == 1 and is_ambiguous:
                adjusted_score *= 0.8

        if label in COMMON_MILD_DISEASES and is_ambiguous and not red_flag_present:
            adjusted_score *= 1.18

        adjusted[label] = adjusted_score

    return adjusted


def _build_explanation(prediction: str, confidence: float, entities: Dict[str, List[str]]) -> str:
    symptoms = entities.get("symptoms") or []
    lab_values = entities.get("lab_values") or []
    symptom_text = ", ".join(symptoms[:4]) if symptoms else "no strong symptom keywords"
    lab_text = ", ".join(lab_values[:3]) if lab_values else "no major lab markers parsed"
    confidence_pct = round(confidence * 100, 1)
    return (
        f"The model suggests {prediction} with {confidence_pct}% confidence based on "
        f"symptoms such as {symptom_text} and report findings including {lab_text}."
    )


def _build_guidance(prediction: str, raw_text: str, task: str) -> Dict[str, object]:
    guidance = DISEASE_GUIDANCE.get(
        prediction,
        {
            "recommendations": [
                "Monitor symptoms and arrange medical review if they are not improving.",
                "Keep hydration and rest adequate while tracking symptom changes.",
            ],
            "precautions": [
                "Do not rely only on the prediction if symptoms are severe.",
                "Seek medical care if symptoms worsen or persist.",
            ],
            "recommended_medicines": [
                "Only use simple over-the-counter symptom relief if it is already known to be safe for you.",
                "Ask a clinician or pharmacist before starting a new medicine when unsure.",
            ],
            "seek_care": "Use a clinician visit for persistent or worsening symptoms.",
            "urgency": "medium",
        },
    ).copy()

    lowered = raw_text.lower()
    if any(term in lowered for term in RED_FLAG_TERMS):
        guidance["urgency"] = "high"
        guidance["precautions"] = [
            "This symptom description includes red-flag signs that may need urgent in-person assessment.",
            *guidance["precautions"],
        ]
        guidance["seek_care"] = "Urgent medical evaluation is recommended because red-flag symptoms were detected."

    if task == "report":
        guidance["recommendations"] = [
            "Use the uploaded report findings together with a clinician review for confirmation.",
            *guidance["recommendations"][:2],
        ]
        guidance["recommended_medicines"] = [
            "Medicine decisions should be based on the full report, current prescriptions, and clinician advice.",
            "Do not start or stop prescription medicines only from this AI output.",
        ]
    else:
        guidance["recommendations"] = [
            "This result is based only on typed symptoms, so include report tests or a doctor review for confirmation.",
            *guidance["recommendations"][:2],
        ]

    return guidance
