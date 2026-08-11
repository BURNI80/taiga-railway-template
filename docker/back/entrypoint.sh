#!/bin/sh
# Entrypoint de Railway para el backend de Taiga.
#
# Responsabilidades:
#   1. Esperar a que PostgreSQL esté disponible (hasta ~3 minutos).
#   2. Recoger los archivos estáticos dentro del volumen persistente
#      (necesario porque el volumen se monta vacío la primera vez).
#   3. Crear el primer administrador automáticamente (idempotente).
#   4. Delegar en el entrypoint oficial de Taiga (migraciones + gunicorn)
#      o en el entrypoint de Celery según el rol de la instancia.
set -e

ROLE="${ROLE:-back}"

# --- 1. Esperar a PostgreSQL -------------------------------------------
echo "[railway] Esperando a PostgreSQL..."
attempt=0
until python -c "
import os, sys, psycopg2
conn = psycopg2.connect(
    host=os.getenv('POSTGRES_HOST', 'postgres'),
    port=int(os.getenv('POSTGRES_PORT', '5432')),
    user=os.getenv('POSTGRES_USER', 'taiga'),
    password=os.getenv('POSTGRES_PASSWORD', ''),
    dbname=os.getenv('POSTGRES_DB', 'taiga'),
    connect_timeout=5,
)
conn.close()
"; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 36 ]; then
        echo "[railway] ERROR: PostgreSQL no está disponible tras 3 minutos." >&2
        exit 1
    fi
    echo "[railway] PostgreSQL no listo (intento $attempt), reintentando en 5s..."
    sleep 5
done
echo "[railway] PostgreSQL disponible."

# --- Rol async: Celery worker + beat -----------------------------------
if [ "$ROLE" = "async" ]; then
    echo "[railway] Rol async detectado, arrancando Celery..."
    CELERY_CONCURRENCY="${CELERY_CONCURRENCY:-2}"
    echo "[railway] Concurrencia de Celery: $CELERY_CONCURRENCY"
    exec /taiga-back/docker/async_entrypoint.sh --concurrency "$CELERY_CONCURRENCY" "$@"
fi

# --- 2. Migraciones + recoger estáticos --------------------------------
# Corremos las migraciones aquí para que las tablas existan antes de
# crear el administrador. El entrypoint oficial las vuelve a ejecutar
# más tarde (es idempotente).
echo "[railway] Aplicando migraciones..."
python manage.py migrate --noinput

echo "[railway] Recogiendo archivos estáticos..."
python manage.py collectstatic --noinput

# --- 3. Bootstrap del administrador ------------------------------------
if [ "${ADMIN_BOOTSTRAP_ENABLED:-true}" = "true" ]; then
    echo "[railway] Verificando administrador inicial..."
    python /taiga-back/railway_bootstrap_admin.py
else
    echo "[railway] ADMIN_BOOTSTRAP_ENABLED=false, omitiendo administrador inicial."
fi

# --- 4. Delegar en el entrypoint oficial -------------------------------
# Se reduce el número de workers de gunicorn para ajustarse a la capa
# gratuita de Railway (configurable con GUNICORN_WORKERS).
GUNICORN_WORKERS="${GUNICORN_WORKERS:-2}"
echo "[railway] Workers de gunicorn: $GUNICORN_WORKERS"
echo "[railway] Delegando en el entrypoint oficial de Taiga (migraciones + gunicorn)..."
exec /taiga-back/docker/entrypoint.sh --workers "$GUNICORN_WORKERS" "$@"
