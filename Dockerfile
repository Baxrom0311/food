FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SETTINGS_MODULE=config.settings.production

# Create and set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install python dependencies
COPY requirements/ /app/requirements/
RUN pip install --upgrade pip
RUN pip install -r requirements/production.txt

# Copy project files
COPY . /app/

# Collect static files at build time
RUN SECRET_KEY=build-placeholder python manage.py collectstatic --noinput

# Expose port
EXPOSE 8000

# Run migrations, seed data, create demo user, then start gunicorn
CMD sh -c "python manage.py migrate --noinput && \
    python manage.py seed_foods || true && \
    python manage.py create_demo || true && \
    gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 2 --timeout 120 --log-file -"
