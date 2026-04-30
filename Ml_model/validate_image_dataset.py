import argparse
import json
from collections import Counter
from pathlib import Path

from Ml_model.training.dataset_loader import DEFAULT_DATASET_PATHS, load_image_dataset


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate a labeled medical image dataset.")
    parser.add_argument(
        "--dataset",
        dest="dataset_path",
        default=str(DEFAULT_DATASET_PATHS["image"]),
        help="Image dataset folder or CSV path. Defaults to Ml_model/dataset/images.",
    )
    args = parser.parse_args()

    dataset_path = Path(args.dataset_path)
    try:
        dataframe = load_image_dataset(str(dataset_path))
    except ValueError as exc:
        print(
            json.dumps(
                {
                    "dataset": str(dataset_path),
                    "total_images": 0,
                    "labels": {},
                    "ready_for_training": False,
                    "message": str(exc),
                },
                indent=2,
            )
        )
        return
    counts = Counter(dataframe["label"])
    too_small = {label: count for label, count in counts.items() if count < 2}

    result = {
        "dataset": str(dataset_path),
        "total_images": int(len(dataframe)),
        "labels": dict(sorted(counts.items())),
        "ready_for_training": not too_small and len(counts) >= 2,
    }
    if too_small:
        result["labels_needing_more_images"] = too_small
    if len(counts) < 2:
        result["message"] = "Add at least 2 disease label folders/classes before training."

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
