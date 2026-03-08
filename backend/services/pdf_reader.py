import fitz


def extract_text_from_pdf(file_bytes):
    if not file_bytes:
        return ""

    document = fitz.open(stream=file_bytes, filetype="pdf")
    extracted_chunks = []

    for page in document:
        extracted_chunks.append(page.get_text("text"))

    document.close()
    return "\n".join(extracted_chunks).strip()
