import argparse
import json
from pathlib import Path

from Ml_model.training.dataset_loader import DEFAULT_DATASET_PATHS
from Ml_model.training.trainer import train_models


SUPPORTED_IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}


def main() -> None:
    parser = argparse.ArgumentParser(description="Train the medical report and symptom classifiers.")
    parser.add_argument("--dataset", dest="dataset_path", help="Optional CSV dataset path.")
    parser.add_argument(
        "--task",
        choices=["report", "symptom", "image", "all"],
        default="all",
        help="Choose which model to train. all trains text models and image if a default image dataset exists.",
    )
    args = parser.parse_args()

    if args.task == "all":
        tasks = ["report", "symptom"]
        if _has_image_training_files(DEFAULT_DATASET_PATHS["image"]):
            tasks.append("image")
    else:
        tasks = [args.task]
    results = []
    for task in tasks:
        result = train_models(args.dataset_path, task=task)
        results.append(
            {
                "task": result.task,
                "best_model": result.best_model_name,
                "metrics": result.metrics,
                "model_path": result.model_path,
            }
        )

    print(json.dumps(results, indent=2))


def _has_image_training_files(path: Path) -> bool:
    """Return whether the default image dataset contains trainable image files."""
    if not path.exists():
        return False
    if path.is_file():
        return path.suffix.lower() == ".csv"
    return any(
        item.is_file() and item.suffix.lower() in SUPPORTED_IMAGE_EXTENSIONS
        for item in path.rglob("*")
    )


if __name__ == "__main__":
    main()
