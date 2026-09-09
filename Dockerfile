# Stage 1: Build
FROM python:3.14-slim-trixie AS builder

ENV PYTHONUNBUFFERED=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

WORKDIR /app/
COPY pyproject.toml poetry.lock /app/
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt install -y locales libcurl4-openssl-dev libssl-dev build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install -U pip poetry && \
    poetry install --without dev --no-root && \
    rm -rf $POETRY_CACHE_DIR

# Stage 2: Runtime environment
FROM python:3.14-slim-trixie

ENV PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

# Apply Debian security updates to the runtime image.
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}
COPY . /app/

# Drop pip from the runtime image. The virtualenv is already built, and pip
# bundles vendored copies of other packages that scanners report as findings.
RUN rm -rf /usr/local/lib/python*/site-packages/pip \
           /usr/local/lib/python*/site-packages/pip-*.dist-info \
           ${VIRTUAL_ENV}/lib/python*/site-packages/pip \
           ${VIRTUAL_ENV}/lib/python*/site-packages/pip-*.dist-info

EXPOSE 9808

RUN adduser --disabled-login exporter

USER exporter

ENTRYPOINT ["python", "/app/cli.py"]
