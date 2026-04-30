# Image Disease Dataset

Put labeled medical images in this folder to train the image disease model.

Use one folder per disease label:

```text
images/
  Pneumonia/
    pneumonia_001.jpg
    pneumonia_002.png
  Tuberculosis/
    tb_001.jpg
    tb_002.png
```

Supported image types:

- `.png`
- `.jpg`
- `.jpeg`
- `.bmp`
- `.webp`

Train after adding images:

```powershell
.\.venv\Scripts\python.exe -m Ml_model.train --task image
```

For useful training, keep at least 20-50 images per disease class. The code requires at least 2 images per disease label so cross-validation can run.
