from functools import lru_cache
from pathlib import Path
from typing import Dict, List

try:
    import joblib
except ImportError:  # pragma: no cover
    joblib = None

from Ml_model.nlp_model.entity_extractor import EntityExtractor
from Ml_model.utils.image_features import image_bytes_to_features
from Ml_model.utils.preprocessing import preprocess_text


MODEL_DIR = Path(__file__).resolve().parent / "models"
MODEL_PATHS = {
    "report": MODEL_DIR / "report_disease_classifier.joblib",
    "symptom": MODEL_DIR / "symptom_disease_classifier.joblib",
    "image": MODEL_DIR / "image_disease_classifier.joblib",
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
    "COVID-19": ["covid", "sars cov 2", "rt pcr", "loss of smell", "dry cough", "oxygen saturation", "spo2"],
    "Tuberculosis": ["tuberculosis", "tb", "afb", "gene xpert", "night sweats", "weight loss", "cavitary lesion"],
    "Malaria": ["malaria", "plasmodium", "malarial parasite", "chills", "sweating", "rapid malaria antigen"],
    "Typhoid": ["typhoid", "widal", "salmonella typhi", "step ladder fever", "abdominal pain", "rose spots"],
    "Urinary Tract Infection": ["uti", "urinary tract infection", "burning urination", "pus cells", "nitrite", "leukocyte esterase"],
    "Kidney Disease": ["creatinine", "urea", "egfr", "proteinuria", "kidney disease", "renal impairment"],
    "Liver Disease": ["bilirubin", "sgpt", "sgot", "jaundice", "liver disease", "hepatitis"],
    "Thyroid Disorder": ["tsh", "t3", "t4", "thyroid", "hypothyroid", "hyperthyroid"],
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
    "COVID-19": {
        "recommendations": [
            "Use a clinician-approved COVID test or medical review when symptoms and exposure fit.",
            "Rest, hydrate, and monitor fever, cough, and oxygen saturation if available.",
            "Reduce close contact with others while fever or respiratory symptoms are active.",
        ],
        "precautions": [
            "Seek urgent care for breathing trouble, chest pain, confusion, or low oxygen saturation.",
            "Higher-risk patients should contact a clinician early about treatment options.",
            "Do not self-start antibiotics for viral symptoms unless prescribed.",
        ],
        "recommended_medicines": [
            "Acetaminophen/paracetamol may help fever if safe for you.",
            "Prescription antivirals may be appropriate for some high-risk patients after clinician review.",
        ],
        "seek_care": "Medical care is recommended promptly if oxygen is low, breathing worsens, or risk factors are present.",
        "urgency": "medium",
    },
    "Tuberculosis": {
        "recommendations": [
            "Arrange medical evaluation for cough lasting more than two weeks, weight loss, fever, or night sweats.",
            "Confirm suspected tuberculosis with sputum testing, imaging, and clinician review.",
            "Avoid close prolonged exposure to others until infectious risk is assessed.",
        ],
        "precautions": [
            "Do not delay care if coughing blood, severe weakness, or breathlessness appears.",
            "Do not start or stop tuberculosis medicines without a supervised treatment plan.",
            "Follow public health guidance if TB is confirmed.",
        ],
        "recommended_medicines": [
            "TB treatment requires prescription multi-drug therapy supervised by a clinician.",
            "Avoid partial or irregular TB treatment because resistance can develop.",
        ],
        "seek_care": "Prompt clinician review is recommended for suspected tuberculosis symptoms or positive TB tests.",
        "urgency": "medium",
    },
    "Malaria": {
        "recommendations": [
            "Seek testing quickly when fever with chills occurs after mosquito exposure or travel to a malaria area.",
            "Hydrate and monitor fever pattern, weakness, vomiting, and confusion.",
            "Use mosquito-bite prevention to reduce further exposure.",
        ],
        "precautions": [
            "Urgent care is needed for confusion, severe weakness, persistent vomiting, jaundice, or very high fever.",
            "Do not delay antimalarial treatment if malaria is confirmed by a clinician.",
            "Children, pregnancy, and older age increase risk and need early review.",
        ],
        "recommended_medicines": [
            "Antimalarial medicine choice depends on test result, region, pregnancy status, and clinician advice.",
            "Acetaminophen/paracetamol may help fever if safe for you.",
        ],
        "seek_care": "Same-day medical testing and review is recommended for suspected malaria.",
        "urgency": "high",
    },
    "Typhoid": {
        "recommendations": [
            "Get medical review for prolonged fever with abdominal symptoms or positive Widal/blood culture findings.",
            "Maintain fluids and light foods as tolerated.",
            "Use safe water and hand hygiene to reduce spread.",
        ],
        "precautions": [
            "Seek urgent care for persistent vomiting, severe abdominal pain, confusion, or dehydration.",
            "Do not self-start antibiotics without clinician advice and appropriate testing.",
            "Follow up if fever persists despite treatment.",
        ],
        "recommended_medicines": [
            "Typhoid usually needs prescription antibiotics chosen by a clinician.",
            "Oral rehydration solution may help if diarrhea or poor intake is present.",
        ],
        "seek_care": "Medical review is recommended for sustained fever or positive typhoid-related tests.",
        "urgency": "medium",
    },
    "Urinary Tract Infection": {
        "recommendations": [
            "Arrange urine testing or clinician review for burning urination, frequency, fever, or abnormal urine findings.",
            "Drink fluids unless a clinician has restricted fluid intake.",
            "Note fever, flank pain, pregnancy, or recurrent infections because they change urgency.",
        ],
        "precautions": [
            "Seek urgent care for fever with back/flank pain, vomiting, pregnancy, or confusion.",
            "Do not use leftover antibiotics because wrong treatment can worsen resistance.",
            "Persistent symptoms after treatment need follow-up testing.",
        ],
        "recommended_medicines": [
            "Antibiotics should be selected by a clinician based on symptoms and urine findings.",
            "Simple pain or fever relief may be used only if safe for you.",
        ],
        "seek_care": "Clinician review is advised, especially with fever, flank pain, pregnancy, or recurrent symptoms.",
        "urgency": "medium",
    },
    "Kidney Disease": {
        "recommendations": [
            "Review abnormal creatinine, urea, eGFR, swelling, or urine protein findings with a clinician.",
            "Track blood pressure, urine changes, swelling, and diabetes status if relevant.",
            "Avoid dehydration and ask before using medicines that can affect kidneys.",
        ],
        "precautions": [
            "Seek urgent care for very low urine output, severe swelling, confusion, or breathlessness.",
            "Avoid frequent NSAID painkillers unless a clinician says they are safe for you.",
            "Do not ignore rising creatinine or falling eGFR on repeat tests.",
        ],
        "recommended_medicines": [
            "Kidney-related medicines depend on the cause and lab values and need clinician supervision.",
            "Avoid self-medicating with painkillers or supplements when kidney tests are abnormal.",
        ],
        "seek_care": "Medical review is recommended for abnormal kidney function tests or swelling with urine changes.",
        "urgency": "medium",
    },
    "Liver Disease": {
        "recommendations": [
            "Review jaundice, high bilirubin, high SGPT/SGOT, or hepatitis markers with a clinician.",
            "Avoid alcohol while liver inflammation or jaundice is being evaluated.",
            "Track dark urine, pale stool, abdominal swelling, and worsening fatigue.",
        ],
        "precautions": [
            "Seek urgent care for confusion, bleeding, severe abdominal swelling, or deepening jaundice.",
            "Avoid unnecessary medicines or supplements that can stress the liver.",
            "Hepatitis-related findings need appropriate testing and follow-up.",
        ],
        "recommended_medicines": [
            "Treatment depends on the liver disease cause and should be clinician-directed.",
            "Avoid self-starting herbal or high-dose medicines when liver tests are abnormal.",
        ],
        "seek_care": "Clinician review is recommended for jaundice, high liver enzymes, or hepatitis markers.",
        "urgency": "medium",
    },
    "Thyroid Disorder": {
        "recommendations": [
            "Review abnormal TSH, T3, or T4 results with a clinician for thyroid-specific treatment.",
            "Track weight change, palpitations, fatigue, cold or heat intolerance, and neck swelling.",
            "Repeat testing may be needed before long-term treatment decisions.",
        ],
        "precautions": [
            "Seek urgent care for severe palpitations, chest pain, confusion, or extreme weakness.",
            "Do not change thyroid medicine doses without medical advice.",
            "Pregnancy or heart disease makes thyroid abnormalities more urgent to review.",
        ],
        "recommended_medicines": [
            "Thyroid medicines require prescription dosing based on lab values and clinical context.",
            "Do not self-start thyroid hormone or antithyroid medicine.",
        ],
        "seek_care": "Medical review is recommended for abnormal thyroid tests or persistent thyroid-related symptoms.",
        "urgency": "low",
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
    "coughing blood",
    "low oxygen",
    "flank pain",
    "deepening jaundice",
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
    "COVID-19": 0.92,
    "Tuberculosis": 0.86,
    "Malaria": 0.84,
    "Typhoid": 0.9,
    "Urinary Tract Infection": 1.0,
    "Kidney Disease": 0.88,
    "Liver Disease": 0.88,
    "Thyroid Disorder": 1.05,
}

SEVERE_DISEASES = {"Pneumonia", "Heart Disease", "Dengue", "Stroke", "Malaria"}
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


@lru_cache(maxsize=3)
def _load_artifact(task: str) -> dict | None:
    if joblib is None:
        return None
    model_path = MODEL_PATHS[task]
    if not Path(model_path).exists():
        return None
    try:
        return joblib.load(model_path)
    except (AttributeError, TypeError, ValueError, ImportError):
        return None


@lru_cache(maxsize=1)
def _get_entity_extractor() -> EntityExtractor:
    return EntityExtractor()


def analyze_medical_report_text(text: str) -> Dict[str, object]:
    return _analyze_text(text, task="report")


def analyze_medical_image_file_bytes(file_bytes: bytes, extracted_text: str = "") -> Dict[str, object]:
    text_result = analyze_medical_report_text(extracted_text) if extracted_text.strip() else None
    image_result = _analyze_image(file_bytes)
    if image_result is None:
        if text_result is not None:
            return text_result
        return {
            "task": "image",
            "prediction": "Unknown",
            "confidence": 0.0,
            "extracted_symptoms": [],
            "entities": {"symptoms": [], "diseases": [], "medications": [], "lab_values": []},
            "explanation": "No image disease model is trained yet and no readable report text was extracted.",
            "probabilities": {},
            "recommendations": [
                "Add labeled image training data and run the image training command before relying on image-only prediction.",
                "Use a clearer report image or upload a PDF/TXT version when available.",
            ],
            "precautions": [
                "Do not rely on this output for diagnosis because image-only prediction is not available yet.",
                "Seek clinician review for concerning symptoms or abnormal report findings.",
            ],
            "recommended_medicines": [
                "Medicine decisions need clinician advice and the full report context.",
            ],
            "seek_care": "Use clinician review if symptoms or report findings are concerning.",
            "urgency": "medium",
        }

    if text_result is None or image_result["confidence"] >= text_result["confidence"]:
        return image_result

    text_result["image_prediction"] = {
        "prediction": image_result["prediction"],
        "confidence": image_result["confidence"],
        "probabilities": image_result["probabilities"],
    }
    return text_result


def analyze_symptom_text(text: str) -> Dict[str, object]:
    return _analyze_text(text, task="symptom")


def _analyze_image(file_bytes: bytes) -> Dict[str, object] | None:
    artifact = _load_artifact("image")
    if artifact is None:
        return None

    features = image_bytes_to_features(file_bytes)
    pipeline = artifact["pipeline"]
    probability_matrix = pipeline.predict_proba([features])[0]
    labels = pipeline.classes_
    ranked_probabilities = sorted(
        ((label, float(score)) for label, score in zip(labels, probability_matrix)),
        key=lambda item: item[1],
        reverse=True,
    )
    predicted_label = ranked_probabilities[0][0]
    confidence = ranked_probabilities[0][1]
    probabilities = {
        label: round(score, 4)
        for label, score in ranked_probabilities
    }
    guidance = _build_guidance(predicted_label, "", task="image")

    return {
        "task": "image",
        "prediction": predicted_label,
        "confidence": round(float(confidence), 4),
        "extracted_symptoms": [],
        "entities": {"symptoms": [], "diseases": [], "medications": [], "lab_values": []},
        "explanation": (
            f"The image model suggests {predicted_label} with "
            f"{round(confidence * 100, 1)}% confidence from visual features."
        ),
        "probabilities": probabilities,
        "recommendations": guidance["recommendations"],
        "precautions": guidance["precautions"],
        "recommended_medicines": guidance["recommended_medicines"],
        "seek_care": guidance["seek_care"],
        "urgency": guidance["urgency"],
    }


def _analyze_text(text: str, task: str) -> Dict[str, object]:
    processed_text = preprocess_text(text)
    entities = _get_entity_extractor().extract(text)
    heuristic_label, heuristic_confidence, heuristic_probabilities = HeuristicPredictor(task).predict(text)

    artifact = _load_artifact(task)
    if artifact is None:
        predicted_label, confidence, probabilities = heuristic_label, heuristic_confidence, heuristic_probabilities
    else:
        pipeline = artifact["pipeline"]
        try:
            probability_matrix = pipeline.predict_proba([processed_text])[0]
            labels = pipeline.classes_
        except (AttributeError, TypeError, ValueError):
            predicted_label, confidence, probabilities = heuristic_label, heuristic_confidence, heuristic_probabilities
        else:
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
