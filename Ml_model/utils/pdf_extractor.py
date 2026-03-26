from io import BytesIO
import shutil

import fitz

try:
    import pdfplumber
except ImportError:  # pragma: no cover
    pdfplumber = None

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    Image = None

try:
    import pytesseract
except ImportError:  # pragma: no cover
    pytesseract = None


def extract_text_from_pdf_bytes(file_bytes: bytes) -> str:
    if not file_bytes:
        return ""

    extracted = []
    if pdfplumber is not None:
        with pdfplumber.open(BytesIO(file_bytes)) as pdf:
            for page in pdf.pages:
                extracted.append(page.extract_text() or "")

    text = "\n".join(chunk.strip() for chunk in extracted if chunk).strip()
    if text:
        return text

    document = fitz.open(stream=file_bytes, filetype="pdf")
    chunks = [page.get_text("text") for page in document]
    if any(chunk.strip() for chunk in chunks):
        document.close()
        return "\n".join(chunk.strip() for chunk in chunks if chunk).strip()

    ocr_text = _extract_with_ocr(document)
    document.close()
    return ocr_text


def ocr_is_available() -> bool:
    return (
        pytesseract is not None
        and Image is not None
        and shutil.which("tesseract") is not None
    )


def _extract_with_ocr(document: fitz.Document) -> str:
    if not ocr_is_available():
        return ""

    extracted = []
    for page in document:
        pixmap = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
        image_bytes = pixmap.tobytes("png")
        image = Image.open(BytesIO(image_bytes))
        text = pytesseract.image_to_string(image)
        if text.strip():
            extracted.append(text.strip())

    return "\n".join(extracted).strip()
