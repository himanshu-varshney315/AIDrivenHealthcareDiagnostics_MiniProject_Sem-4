import re
from typing import List


STOPWORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "by",
    "for",
    "from",
    "has",
    "in",
    "is",
    "it",
    "of",
    "on",
    "or",
    "that",
    "the",
    "to",
    "was",
    "with",
    "patient",
    "report",
    "medical",
    "shows",
    "noted",
}


def normalize_text(text: str) -> str:
    lowered = text.lower()
    cleaned = re.sub(r"[^a-z0-9\s\.%/:-]", " ", lowered)
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned.strip()


def tokenize_text(text: str) -> List[str]:
    normalized = normalize_text(text)
    tokens = re.findall(r"[a-z0-9\.%/-]+", normalized)
    return [token for token in tokens if token not in STOPWORDS]


def preprocess_text(text: str) -> str:
    return " ".join(tokenize_text(text))
