from pathlib import Path

import pandas as pd


DATASET_DIR = Path(__file__).resolve().parents[1] / "dataset"
DEFAULT_DATASET_PATHS = {
    "report": DATASET_DIR / "report_dataset.csv",
    "symptom": DATASET_DIR / "symptom_dataset.csv",
    "image": DATASET_DIR / "images",
}
SUPPORTED_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}


def load_dataset(dataset_path: str | None = None, task: str = "report") -> pd.DataFrame:
    path = Path(dataset_path) if dataset_path else DEFAULT_DATASET_PATHS[task]
    dataframe = pd.read_csv(path)
    required_columns = {"text", "label"}
    missing_columns = required_columns.difference(dataframe.columns)
    if missing_columns:
        raise ValueError(f"Dataset is missing required columns: {', '.join(sorted(missing_columns))}")
    return dataframe.dropna(subset=["text", "label"]).reset_index(drop=True)


def load_image_dataset(dataset_path: str | None = None) -> pd.DataFrame:
    path = Path(dataset_path) if dataset_path else DEFAULT_DATASET_PATHS["image"]
    if path.is_dir():
        rows = _load_image_folder_dataset(path)
    elif path.is_file() and path.suffix.lower() == ".csv":
        rows = _load_image_csv_dataset(path)
    else:
        raise ValueError(
            "Image dataset must be a directory with one subfolder per disease label "
            "or a CSV with image_path,label columns."
        )

    dataframe = pd.DataFrame(rows)
    if dataframe.empty:
        raise ValueError("No supported image files were found for image model training.")
    return dataframe.dropna(subset=["image_path", "label"]).reset_index(drop=True)


def _load_image_folder_dataset(root: Path) -> list[dict[str, str]]:
    rows = []
    for label_dir in sorted(item for item in root.iterdir() if item.is_dir()):
        for image_path in sorted(label_dir.rglob("*")):
            if image_path.suffix.lower() in SUPPORTED_IMAGE_EXTENSIONS:
                rows.append({"image_path": str(image_path), "label": label_dir.name})
    return rows


def _load_image_csv_dataset(path: Path) -> list[dict[str, str]]:
    dataframe = pd.read_csv(path)
    required_columns = {"image_path", "label"}
    missing_columns = required_columns.difference(dataframe.columns)
    if missing_columns:
        raise ValueError(f"Image dataset is missing required columns: {', '.join(sorted(missing_columns))}")

    rows = []
    for row in dataframe.dropna(subset=["image_path", "label"]).itertuples(index=False):
        image_path = Path(row.image_path)
        if not image_path.is_absolute():
            image_path = path.parent / image_path
        if image_path.suffix.lower() in SUPPORTED_IMAGE_EXTENSIONS:
            rows.append({"image_path": str(image_path), "label": row.label})
    return rows
