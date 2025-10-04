# Use Alpine-based Python (same family you already use)
FROM python:3.12-alpine3.20

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Build-time flag to install dev requirements
ARG DEV=false

# OS packages (adjust to your DB/tooling needs)
RUN apk add --no-cache --update \
    postgresql-client \
 && apk add --no-cache --update --virtual .tmp-build-deps \
    build-base postgresql-dev musl-dev linux-headers

# Copy requirements first for better layer caching
COPY requirements.txt /tmp/requirements.txt
COPY requirements.dev.txt /tmp/requirements.dev.txt

# Create a venv, install deps, clean up, then create a user (BusyBox flags)
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-buil-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ "$DEV" = "true" ]; then /py/bin/pip install -r /tmp/requirements.dev.txt ; fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    addgroup -S django && \
    adduser  -S -H -D -G django django-user
# -S: system user, -H: don't create home, -D: no password

# Make the venv first on PATH so django-admin etc. resolve correctly
ENV PATH="/py/bin:${PATH}"

# App directory and code
WORKDIR /app
COPY . /app

# Drop privileges
USER django-user

EXPOSE 8000
