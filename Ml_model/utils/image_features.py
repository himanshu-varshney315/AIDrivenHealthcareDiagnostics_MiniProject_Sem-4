from io import BytesIO
from pathlib import Path

import numpy as np

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    Image = None


IMAGE_SIZE = (64, 64)
HISTOGRAM_BINS = 16


def image_file_to_features(path: str | Path) -> np.ndarray:
    if Image is None:
        raise RuntimeError("Pillow is required for image disease model training.")
    with Image.open(path) as image:
        return image_to_features(image)


def image_bytes_to_features(file_bytes: bytes) -> np.ndarray:
    if Image is None:
        raise RuntimeError("Pillow is required for image disease prediction.")
    with Image.open(BytesIO(file_bytes)) as image:
        return image_to_features(image)


def image_to_features(image: "Image.Image") -> np.ndarray:
    rgb_image = image.convert("RGB").resize(IMAGE_SIZE)
    grayscale = rgb_image.convert("L")

    grayscale_array = np.asarray(grayscale, dtype=np.float32).reshape(-1) / 255.0
    rgb_array = np.asarray(rgb_image, dtype=np.float32) / 255.0

    histograms = []
    for channel_index in range(3):
        histogram, _ = np.histogram(
            rgb_array[:, :, channel_index],
            bins=HISTOGRAM_BINS,
            range=(0.0, 1.0),
            density=True,
        )
        histograms.append(histogram.astype(np.float32))

    return np.concatenate([grayscale_array, *histograms])
