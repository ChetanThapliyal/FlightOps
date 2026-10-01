# Stage 1: Build / dependency install
FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Production runtime

FROM python:3.12-slim AS runtime

LABEL maintainer="Chetan Thapliyal <chetan.thapliyal@protonmail.com>" \
    org.opencontainers.image.title="FlightOps" \
    org.opencontainers.image.description="Flight booking web application" \
    org.opencontainers.image.source="https://github.com/ChetanThapliyal/FlightOps"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production \
    GUNICORN_WORKERS=4 \
    GUNICORN_THREADS=2 \
    GUNICORN_BIND=0.0.0.0:8000 \
    GUNICORN_TIMEOUT=120 \
    GUNICORN_GRACEFUL_TIMEOUT=30 \
    GUNICORN_KEEP_ALIVE=5

RUN apt-get update && \
    apt-get install -y --no-install-recommends libpq5 curl tini && \
    rm -rf /var/lib/apt/lists/*
RUN groupadd --gid 1000 flightops && \
    useradd  --uid 1000 --gid flightops --shell /bin/false --create-home flightops
COPY --from=builder /install /usr/local

WORKDIR /app

COPY --chown=flightops:flightops main.py           ./
COPY --chown=flightops:flightops requirements.txt   ./
COPY --chown=flightops:flightops templates/          templates/
COPY --chown=flightops:flightops static/             static/
COPY --chown=flightops:flightops src/                src/
COPY --chown=flightops:flightops db/                 db/

RUN chmod -R a-w /app && \
    mkdir -p /app/tmp && chown flightops:flightops /app/tmp && chmod 700 /app/tmp
USER flightops

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

EXPOSE 8000

ENTRYPOINT ["tini", "--"]

CMD ["sh", "-c", \
    "gunicorn main:app \
    --bind ${GUNICORN_BIND} \
    --workers ${GUNICORN_WORKERS} \
    --threads ${GUNICORN_THREADS} \
    --timeout ${GUNICORN_TIMEOUT} \
    --graceful-timeout ${GUNICORN_GRACEFUL_TIMEOUT} \
    --keep-alive ${GUNICORN_KEEP_ALIVE} \
    --access-logfile - \
    --error-logfile - \
    --log-level info"]