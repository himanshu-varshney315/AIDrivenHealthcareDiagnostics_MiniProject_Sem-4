import argparse
import json

from Ml_model.training.trainer import train_models


def main() -> None:
    parser = argparse.ArgumentParser(description="Train the medical report and symptom classifiers.")
    parser.add_argument("--dataset", dest="dataset_path", help="Optional CSV dataset path.")
    parser.add_argument(
        "--task",
        choices=["report", "symptom", "all"],
        default="all",
        help="Choose which model to train.",
    )
    args = parser.parse_args()

    tasks = ["report", "symptom"] if args.task == "all" else [args.task]
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


if __name__ == "__main__":
    main()
