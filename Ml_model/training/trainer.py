from dataclasses import dataclass
from datetime import datetime, timezone
import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.ensemble import VotingClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import make_scorer, precision_score, recall_score, f1_score
from sklearn.model_selection import StratifiedKFold, cross_validate
from sklearn.naive_bayes import ComplementNB
from sklearn.pipeline import FeatureUnion, Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import LinearSVC

from Ml_model.training.dataset_loader import load_dataset, load_image_dataset
from Ml_model.utils.image_features import image_file_to_features
from Ml_model.utils.preprocessing import preprocess_text


MODEL_DIR = Path(__file__).resolve().parents[1] / "models"
METRICS_PATH = MODEL_DIR / "metrics.json"
MODEL_PATHS = {
    "report": MODEL_DIR / "report_disease_classifier.joblib",
    "symptom": MODEL_DIR / "symptom_disease_classifier.joblib",
    "image": MODEL_DIR / "image_disease_classifier.joblib",
}


@dataclass
class TrainingResult:
    """Summary returned after fitting and saving one trained model artifact."""

    task: str
    best_model_name: str
    metrics: dict
    model_path: str


SYMPTOM_REPLACEMENTS = {
    "i have": ["i am having", "i'm having", "i feel"],
    "runny nose": ["running nose", "nasal discharge"],
    "sore throat": ["throat pain", "throat irritation"],
    "body ache": ["body pain", "muscle ache"],
    "shortness of breath": ["breathlessness", "difficulty breathing"],
    "headache": ["head pain"],
    "vomiting": ["throwing up"],
    "diarrhea": ["loose motions"],
    "itchy eyes": ["eye itching"],
    "watery nose": ["runny nose"],
    "fatigue": ["tiredness"],
}

SYMPTOM_PREFIXES = [
    "",
    "since yesterday, ",
    "since this morning, ",
    "for one day, ",
    "mildly, ",
    "i think ",
]

SYMPTOM_SUFFIXES = [
    "",
    " since yesterday",
    " from today",
    " and it is mild",
    " and i want basic advice",
]


def train_models(dataset_path: str | None = None, task: str = "report") -> TrainingResult:
    """Train one text classifier and persist its model and metrics metadata."""
    if task == "image":
        return train_image_model(dataset_path)

    dataframe = load_dataset(dataset_path, task=task)
    if task == "symptom":
        dataframe = _augment_symptom_dataset(dataframe)
    dataframe["processed_text"] = dataframe["text"].map(preprocess_text)
    features = dataframe["processed_text"]
    labels = dataframe["label"]
    min_class_count = int(dataframe["label"].value_counts().min())

    feature_stack = FeatureUnion(
        [
            (
                "word_tfidf",
                TfidfVectorizer(
                    ngram_range=(1, 2),
                    min_df=1,
                    sublinear_tf=True,
                    strip_accents="unicode",
                    lowercase=True,
                ),
            ),
            (
                "char_tfidf",
                TfidfVectorizer(
                    analyzer="char_wb",
                    ngram_range=(3, 5),
                    min_df=1,
                    sublinear_tf=True,
                    strip_accents="unicode",
                    lowercase=True,
                ),
            ),
        ]
    )

    soft_voting_estimators = [
        (
            "lr",
            LogisticRegression(
                max_iter=4000,
                C=2.5,
                class_weight="balanced",
            ),
        ),
        ("nb", ComplementNB(alpha=0.5)),
        (
            "rf",
            RandomForestClassifier(
                n_estimators=500,
                min_samples_leaf=1,
                random_state=42,
                class_weight="balanced_subsample",
            ),
        ),
    ]

    candidate_models = {
        "logistic_regression_hybrid": Pipeline(
            [
                ("features", feature_stack),
                (
                    "classifier",
                    LogisticRegression(
                        max_iter=3000,
                        C=3.0,
                        class_weight="balanced",
                    ),
                ),
            ]
        ),
        "complement_nb": Pipeline(
            [
                ("features", feature_stack),
                ("classifier", ComplementNB(alpha=0.7)),
            ]
        ),
        "random_forest": Pipeline(
            [
                ("features", feature_stack),
                (
                    "classifier",
                    RandomForestClassifier(
                        n_estimators=400,
                        min_samples_leaf=1,
                        random_state=42,
                        class_weight="balanced_subsample",
                    ),
                ),
            ]
        ),
        "soft_voting_ensemble": Pipeline(
            [
                ("features", feature_stack),
                (
                    "classifier",
                    VotingClassifier(
                        estimators=soft_voting_estimators,
                        voting="soft",
                    ),
                ),
            ]
        ),
    }

    if min_class_count >= 3:
        candidate_models["linear_svc_calibrated"] = Pipeline(
            [
                ("features", feature_stack),
                (
                    "classifier",
                    CalibratedClassifierCV(
                        estimator=LinearSVC(C=1.5, class_weight="balanced"),
                        cv=2,
                    ),
                ),
            ]
        )

    cv_splits = min(3, min_class_count)
    cv = StratifiedKFold(n_splits=cv_splits, shuffle=True, random_state=42)
    scoring = {
        "accuracy": "accuracy",
        "precision": make_scorer(precision_score, average="macro", zero_division=0),
        "recall": make_scorer(recall_score, average="macro", zero_division=0),
        "f1_score": make_scorer(f1_score, average="macro", zero_division=0),
    }

    leaderboard = {}
    best_name = None
    best_pipeline = None
    best_f1 = -1.0

    for model_name, pipeline in candidate_models.items():
        cv_result = cross_validate(
            pipeline,
            features,
            labels,
            cv=cv,
            scoring=scoring,
            n_jobs=1,
        )
        metrics = {
            "accuracy": round(float(cv_result["test_accuracy"].mean()), 4),
            "precision": round(float(cv_result["test_precision"].mean()), 4),
            "recall": round(float(cv_result["test_recall"].mean()), 4),
            "f1_score": round(float(cv_result["test_f1_score"].mean()), 4),
        }
        leaderboard[model_name] = metrics

        if metrics["f1_score"] > best_f1:
            best_f1 = metrics["f1_score"]
            best_name = model_name
            best_pipeline = pipeline

    best_pipeline.fit(features, labels)

    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    model_path = MODEL_PATHS[task]
    artifact = {
        "task": task,
        "model_name": best_name,
        "pipeline": best_pipeline,
        "labels": sorted(dataframe["label"].unique().tolist()),
        "metrics": leaderboard,
        "cv_strategy": f"StratifiedKFold(n_splits={cv_splits}, shuffle=True, random_state=42)",
    }
    joblib.dump(artifact, model_path)
    _write_metrics_artifact(
        task=task,
        selected_model=best_name or "unknown",
        dataset_size=len(dataframe),
        labels=sorted(dataframe["label"].unique().tolist()),
        cv_strategy=artifact["cv_strategy"],
        leaderboard=leaderboard,
        model_path=str(model_path),
    )

    return TrainingResult(
        task=task,
        best_model_name=best_name or "unknown",
        metrics=leaderboard,
        model_path=str(model_path),
    )


def train_image_model(dataset_path: str | None = None) -> TrainingResult:
    """Train the optional image classifier and persist model lifecycle metadata."""
    dataframe = load_image_dataset(dataset_path)
    labels = dataframe["label"]
    min_class_count = int(labels.value_counts().min())
    if min_class_count < 2:
        raise ValueError("Image model training needs at least 2 images per disease label.")

    features = [image_file_to_features(path) for path in dataframe["image_path"]]

    candidate_models = {
        "image_logistic_regression": Pipeline(
            [
                ("scaler", StandardScaler()),
                (
                    "classifier",
                    LogisticRegression(
                        max_iter=3000,
                        C=1.5,
                        class_weight="balanced",
                    ),
                ),
            ]
        ),
        "image_random_forest": RandomForestClassifier(
            n_estimators=300,
            min_samples_leaf=1,
            random_state=42,
            class_weight="balanced_subsample",
        ),
    }

    cv_splits = min(3, min_class_count)
    cv = StratifiedKFold(n_splits=cv_splits, shuffle=True, random_state=42)
    scoring = {
        "accuracy": "accuracy",
        "precision": make_scorer(precision_score, average="macro", zero_division=0),
        "recall": make_scorer(recall_score, average="macro", zero_division=0),
        "f1_score": make_scorer(f1_score, average="macro", zero_division=0),
    }

    leaderboard = {}
    best_name = None
    best_pipeline = None
    best_f1 = -1.0

    for model_name, pipeline in candidate_models.items():
        cv_result = cross_validate(
            pipeline,
            features,
            labels,
            cv=cv,
            scoring=scoring,
            n_jobs=1,
        )
        metrics = {
            "accuracy": round(float(cv_result["test_accuracy"].mean()), 4),
            "precision": round(float(cv_result["test_precision"].mean()), 4),
            "recall": round(float(cv_result["test_recall"].mean()), 4),
            "f1_score": round(float(cv_result["test_f1_score"].mean()), 4),
        }
        leaderboard[model_name] = metrics

        if metrics["f1_score"] > best_f1:
            best_f1 = metrics["f1_score"]
            best_name = model_name
            best_pipeline = pipeline

    best_pipeline.fit(features, labels)

    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    model_path = MODEL_PATHS["image"]
    artifact = {
        "task": "image",
        "model_name": best_name,
        "pipeline": best_pipeline,
        "labels": sorted(labels.unique().tolist()),
        "metrics": leaderboard,
        "feature_schema": {
            "image_size": [64, 64],
            "channels": "rgb_histogram_plus_grayscale_pixels",
        },
        "cv_strategy": f"StratifiedKFold(n_splits={cv_splits}, shuffle=True, random_state=42)",
    }
    joblib.dump(artifact, model_path)
    _write_metrics_artifact(
        task="image",
        selected_model=best_name or "unknown",
        dataset_size=len(dataframe),
        labels=sorted(labels.unique().tolist()),
        cv_strategy=artifact["cv_strategy"],
        leaderboard=leaderboard,
        model_path=str(model_path),
    )

    return TrainingResult(
        task="image",
        best_model_name=best_name or "unknown",
        metrics=leaderboard,
        model_path=str(model_path),
    )


def _augment_symptom_dataset(dataframe: pd.DataFrame) -> pd.DataFrame:
    """Create small natural-language variants for symptom examples."""
    augmented_rows = []
    for row in dataframe.itertuples(index=False):
        text = row.text
        label = row.label
        variants = {
            text,
            f"since today, {text}",
            f"for two days, {text}",
        }

        for source, replacements in SYMPTOM_REPLACEMENTS.items():
            if source in text:
                for replacement in replacements[:2]:
                    variants.add(text.replace(source, replacement))

        normalized = text.strip()
        stripped = normalized
        if stripped.startswith("i have "):
            stripped = stripped[len("i have ") :]
        elif stripped.startswith("i feel "):
            stripped = stripped[len("i feel ") :]
        elif stripped.startswith("my "):
            stripped = stripped[len("my ") :]

        for prefix in SYMPTOM_PREFIXES:
            variants.add(f"{prefix}{normalized}".strip(", "))
            variants.add(f"{prefix}{stripped}".strip(", "))

        for suffix in SYMPTOM_SUFFIXES:
            variants.add(f"{normalized}{suffix}".strip())
            variants.add(f"{stripped}{suffix}".strip())

        if "," in normalized:
            variants.add(normalized.replace(",", " and"))
        if " and " in normalized:
            first_chunk = normalized.split(" and ")[0].strip()
            if len(first_chunk.split()) >= 2:
                variants.add(first_chunk)

        for variant in variants:
            augmented_rows.append({"text": variant, "label": label})

    return pd.DataFrame(augmented_rows).drop_duplicates().reset_index(drop=True)


def _write_metrics_artifact(
    *,
    task: str,
    selected_model: str,
    dataset_size: int,
    labels: list[str],
    cv_strategy: str,
    leaderboard: dict,
    model_path: str,
) -> dict:
    """Upsert one task's training metadata into Ml_model/models/metrics.json."""
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    if METRICS_PATH.exists():
        payload = json.loads(METRICS_PATH.read_text(encoding="utf-8"))
    else:
        payload = {"tasks": {}}

    payload.setdefault("tasks", {})[task] = {
        "task": task,
        "selected_model": selected_model,
        "dataset_size": dataset_size,
        "labels": labels,
        "cv_strategy": cv_strategy,
        "metrics_leaderboard": leaderboard,
        "model_path": model_path,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }
    METRICS_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return payload
