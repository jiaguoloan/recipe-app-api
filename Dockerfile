FROM python:3.9-alpine3.13

LABEL maintainer="londonappdeveloper.com"

RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    python3-dev \
    postgresql-dev \
    libffi-dev


# Install required system packages
RUN  apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
    python3-dev \
    libffi-dev \
    gcc \
    musl-dev \
    postgresql-libs \
    postgresql-dev \
    py3-virtualenv \
    py3-pip
RUN apk add --update --no-cache \
    postgresql-dev \
    postgresql-libs


ENV PYTHONUNBUFFERED=1

# Create a non-root user before switching
RUN apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

# Set up a virtual environment
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip

# Set the path for the virtual environment
ENV PATH="/py/bin:$PATH"

# Copy requirements and install dependencies
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
# Install dependencies and conditionally remove requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    sh -c 'if [ "$DEV" = "true" ]; then rm -f /tmp/requirements.txt; fi'

RUN pip install flake8


# Copy application files
COPY ./app /app
WORKDIR /app

# Ensure non-root user has access
RUN chown -R django-user:django-user /app

# Expose port
EXPOSE 8000

ARG DEV=false

# Switch to non-root user
USER django-user
RUN mkdir -p /tmp/.cache/pip && \
    chown -R django-user:django-user /tmp/.cache/pip
ENV PIP_CACHE_DIR="/tmp/.cache/pip"


