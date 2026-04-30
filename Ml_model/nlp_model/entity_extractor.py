import os
import re
from dataclasses import dataclass
from typing import Dict, List

from Ml_model.utils.preprocessing import normalize_text

try:
    from transformers import pipeline
except ImportError:  # pragma: no cover
    pipeline = None


SYMPTOM_KEYWORDS = {
    "fever",
    "cough",
    "shortness of breath",
    "fatigue",
    "dizziness",
    "headache",
    "chest pain",
    "palpitations",
    "weakness",
    "thirst",
    "frequent urination",
    "blurred vision",
    "pallor",
    "edema",
    "chills",
    "chest tightness",
    "rash",
    "joint pain",
    "body ache",
    "muscle pain",
    "nausea",
    "vomiting",
    "retro orbital pain",
    "wheezing",
    "chest tightness",
    "slurred speech",
    "facial droop",
    "arm weakness",
    "vision loss",
    "diarrhea",
    "diarrhoea",
    "dehydration",
    "loss of smell",
    "night sweats",
    "burning urination",
    "flank pain",
    "jaundice",
    "weight loss",
    "cold intolerance",
    "heat intolerance",
}

DISEASE_KEYWORDS = {
    "diabetes",
    "hypertension",
    "pneumonia",
    "anemia",
    "heart disease",
    "coronary artery disease",
    "heart failure",
    "dengue",
    "dengue fever",
    "asthma",
    "stroke",
    "chikungunya",
    "diarrheal disease",
    "diarrhoeal disease",
    "covid",
    "covid-19",
    "tuberculosis",
    "malaria",
    "typhoid",
    "urinary tract infection",
    "kidney disease",
    "renal impairment",
    "liver disease",
    "thyroid disorder",
    "hypothyroidism",
    "hyperthyroidism",
}

MEDICATION_KEYWORDS = {
    "metformin",
    "insulin",
    "amlodipine",
    "losartan",
    "aspirin",
    "atorvastatin",
    "iron",
    "salbutamol",
    "albuterol",
    "ors",
    "levothyroxine",
    "azithromycin",
    "ceftriaxone",
    "artemether",
}

LAB_PATTERNS = {
    "glucose": r"(glucose|blood sugar|fbs|rbs)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "hba1c": r"(hba1c|a1c)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "hemoglobin": r"(hemoglobin|hb)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "cholesterol": r"(cholesterol|ldl|hdl|triglycerides)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "blood_pressure": r"(?:bp|blood pressure|systolic|diastolic)\s*[:\-]?\s*([0-9]{2,3})(?:\s*(?:/|over)\s*([0-9]{2,3}))?",
    "oxygen_saturation": r"(spo2|oxygen saturation)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "platelet_count": r"(platelets|platelet count)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "hematocrit": r"(hematocrit|hct)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "creatinine": r"(creatinine)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "urea": r"(urea|bun)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "egfr": r"(egfr)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "bilirubin": r"(bilirubin)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "liver_enzymes": r"(sgpt|alt|sgot|ast)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "tsh": r"(tsh)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
    "thyroid_hormone": r"\b(t3|t4)\s*[:\-]?\s*([0-9]+(?:\.[0-9]+)?)",
}


@dataclass
class EntityExtractor:
    ner_model_name: str = "emilyalsentzer/Bio_ClinicalBERT"

    def __post_init__(self) -> None:
        self._ner_pipeline = None
        if pipeline and os.getenv("ENABLE_MEDICAL_NER", "0") == "1":
            try:
                self._ner_pipeline = pipeline(
                    "ner",
                    model=self.ner_model_name,
                    aggregation_strategy="simple",
                )
            except Exception:
                self._ner_pipeline = None

    def extract(self, text: str) -> Dict[str, List[str]]:
        normalized = normalize_text(text)
        entities = {
            "symptoms": self._match_keywords(normalized, SYMPTOM_KEYWORDS),
            "diseases": self._match_keywords(normalized, DISEASE_KEYWORDS),
            "medications": self._match_keywords(normalized, MEDICATION_KEYWORDS),
            "lab_values": self._extract_lab_values(normalized),
        }

        if self._ner_pipeline:
            entities["ner_entities"] = self._extract_transformer_entities(text)

        return entities

    def _match_keywords(self, text: str, vocabulary: set[str]) -> List[str]:
        return sorted({term for term in vocabulary if term in text})

    def _extract_lab_values(self, text: str) -> List[str]:
        findings = []
        for label, pattern in LAB_PATTERNS.items():
            match = re.search(pattern, text, flags=re.IGNORECASE)
            if not match:
                continue
            values = [part for part in match.groups()[1:] if part]
            findings.append(f"{label}: {'/'.join(values)}")
        return findings

    def _extract_transformer_entities(self, text: str) -> List[str]:
        try:
            entities = self._ner_pipeline(text[:1024])
        except Exception:
            return []
        return sorted({entity["word"] for entity in entities if entity.get("word")})
