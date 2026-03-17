from dataclasses import dataclass
from pathlib import Path

import joblib
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import make_scorer, precision_score, recall_score, f1_score
from sklearn.model_selection import StratifiedKFold, cross_validate
from sklearn.naive_bayes import ComplementNB
from sklearn.pipeline import FeatureUnion, Pipeline
from sklearn.svm import LinearSVC

from Ml_model.training.dataset_loader import load_dataset
from Ml_model.utils.preprocessing import preprocess_text


MODEL_DIR = Path(__file__).resolve().parents[1] / "models"
MODEL_PATHS = {
    "report": MODEL_DIR / "report_disease_classifier.joblib",
    "symptom": MODEL_DIR / "symptom_disease_classifier.joblib",
}


@dataclass
class TrainingResult:
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


def train_models(dataset_path: str | None = None, task: str = "report") -> TrainingResult:
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
                ),
            ),
        ]
    )

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

    return TrainingResult(
        task=task,
        best_model_name=best_name or "unknown",
        metrics=leaderboard,
        model_path=str(model_path),
    )


def _augment_symptom_dataset(dataframe: pd.DataFrame) -> pd.DataFrame:
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

        for variant in variants:
            augmented_rows.append({"text": variant, "label": label})

    return pd.DataFrame(augmented_rows).drop_duplicates().reset_index(drop=True)
