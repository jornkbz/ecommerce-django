# --- Fase 1: Entorno de construcción (Usa los secretos y luego se descarta) ---
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

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# Hacemos que los argumentos estén disponibles como variables de entorno SOLO en esta fase
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

# Ejecutamos collectstatic aquí, donde tenemos acceso a los secretos
RUN python manage.py collectstatic --noinput


# --- Fase 2: Entorno de producción (Limpio, sin secretos) ---
FROM python:3.11-slim-bullseye AS final

RUN groupadd -r django && useradd -r -g django django

WORKDIR /app
RUN mkdir -p /app/static && \
    mkdir -p /app/media && \
    chown -R django:django /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-deps -r requirements.txt

# Copiamos el código de la aplicación
COPY . .

# Copiamos los archivos estáticos ya recolectados de la fase anterior
COPY --from=builder /app/static /app/static

USER django

EXPOSE 8000

CMD ["gunicorn", "ecommerce.wsgi:application", "--bind", "0.0.0.0:8000"]