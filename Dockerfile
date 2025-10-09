# Dockerfile

# --- Fase 1: Entorno de construcción ---
FROM python:3.11-slim-bullseye AS builder

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Declaramos TODOS los argumentos que vamos a recibir
ARG SECRET_KEY
ARG DEBUG
ARG DB_ENGINE
ARG DB_NAME
ARG DB_USER
ARG DB_PASSWORD
ARG DB_HOST
ARG DB_PORT
ARG EMAIL_HOST
ARG EMAIL_PORT
ARG DEFAULT_FROM_EMAIL
ARG EMAIL_HOST_USER
ARG EMAIL_HOST_PASSWORD
ARG EMAIL_USE_TLS

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev

COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt


# --- Fase 2: Entorno de producción ---
FROM python:3.11-slim-bullseye AS final

# Declaramos el argumento que vamos a recibir desde docker-compose.yml
ARG SECRET_KEY

RUN groupadd -r django && useradd -r -g django django

WORKDIR /app
RUN mkdir -p /app/static && \
    mkdir -p /app/media && \
    chown -R django:django /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/wheels /wheels
RUN pip install --no-cache /wheels/*

COPY . .

# Hacemos que los argumentos estén disponibles como variables de entorno
ENV SECRET_KEY=$SECRET_KEY
ENV DEBUG=$DEBUG
ENV DB_ENGINE=$DB_ENGINE
ENV DB_NAME=$DB_NAME
ENV DB_USER=$DB_USER
ENV DB_PASSWORD=$DB_PASSWORD
ENV DB_HOST=$DB_HOST
ENV DB_PORT=$DB_PORT
ENV EMAIL_HOST=$EMAIL_HOST
ENV EMAIL_PORT=$EMAIL_PORT
ENV DEFAULT_FROM_EMAIL=$DEFAULT_FROM_EMAIL
ENV EMAIL_HOST_USER=$EMAIL_HOST_USER
ENV EMAIL_HOST_PASSWORD=$EMAIL_HOST_PASSWORD

# Ahora el comando collectstatic es simple y funcionará.
RUN python manage.py collectstatic --noinput

USER django

EXPOSE 8000

CMD ["gunicorn", "ecommerce.wsgi:application", "--bind", "0.0.0.0:8000"]