from pathlib import Path

import pandas as pd


DATASET_DIR = Path(__file__).resolve().parents[1] / "dataset"
DEFAULT_DATASET_PATHS = {
    "report": DATASET_DIR / "report_dataset.csv",
    "symptom": DATASET_DIR / "symptom_dataset.csv",
}


def load_dataset(dataset_path: str | None = None, task: str = "report") -> pd.DataFrame:
    path = Path(dataset_path) if dataset_path else DEFAULT_DATASET_PATHS[task]
    dataframe = pd.read_csv(path)
    required_columns = {"text", "label"}
    missing_columns = required_columns.difference(dataframe.columns)
    if missing_columns:
        raise ValueError(f"Dataset is missing required columns: {', '.join(sorted(missing_columns))}")
    return dataframe.dropna(subset=["text", "label"]).reset_index(drop=True)
