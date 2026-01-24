#Imagen ligera de python
FROM python:3.12-slim

#Fuerza los logs en tiempo real (evita la creacion de archivos .pyc)
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

#Carpeta de trabajo
WORKDIR /app

#Instalacion de dependencias del sistema para psycopg2
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

#Copia e instalacion de dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

#Copia del codigo fuente
COPY . .

#Comando para iniciar el servidor en el puerto 8001
CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]