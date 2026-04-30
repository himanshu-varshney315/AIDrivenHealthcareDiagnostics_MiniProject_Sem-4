FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY Ml_model/requirements.txt /app/Ml_model/requirements.txt
RUN apt-get update \
    && apt-get install -y --no-install-recommends tesseract-ocr \
    && rm -rf /var/lib/apt/lists/* \
    && python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir -r /app/Ml_model/requirements.txt

COPY Ml_model /app/Ml_model

EXPOSE 5001

CMD ["python", "-m", "Ml_model.app"]
