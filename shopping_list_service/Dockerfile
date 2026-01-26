# Dockerfile para el microservicio de listas de compras
FROM python:3.12-slim

# Variables de entorno
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Dependencias mínimas para psycopg2
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Render expone el puerto vía $PORT
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:${PORT}"]
