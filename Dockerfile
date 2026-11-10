# Container image for Plan B Studio on Cloud Run.
# One gunicorn worker with 8 threads: Cloud Run adds instances for scaling, so we
# keep each instance small and predictable. Cloud Run supplies $PORT.
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /srv

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 60 "app:create_app()"
