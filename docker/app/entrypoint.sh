#!/bin/sh
# Entrypoint del contenedor todo-en-uno de Taiga para Railway.
#
# Responsabilidades:
#   0. Derivar la URL pública de la instalación a partir de
#      RAILWAY_PUBLIC_DOMAIN (que Railway inyecta automáticamente), para
#      que el usuario final no tenga que configurar nada.
#   1. Esperar a que PostgreSQL esté disponible (hasta ~3 minutos).
#   2. Aplicar migraciones, cargar las plantillas iniciales y recoger los
#      archivos estáticos dentro del volumen persistente.
#   3. Crear el primer administrador automáticamente (idempotente).
#   4. Generar conf.json del front (SPA) y el .env de taiga-events.
#   5. Arrancar supervisord (nginx + gunicorn + celery + events).
set -e

# --- 0. Derivar la URL pública desde Railway -----------------------------
export TAIGA_SITES_SCHEME="${TAIGA_SITES_SCHEME:-https}"
if [ -z "${TAIGA_SITES_DOMAIN:-}" ]; then
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
        export TAIGA_SITES_DOMAIN="$RAILWAY_PUBLIC_DOMAIN"
    else
        export TAIGA_SITES_DOMAIN="localhost"
    fi
fi
if [ -z "${TAIGA_URL:-}" ]; then
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
        export TAIGA_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
    else
        export TAIGA_URL="http://localhost"
    fi
fi
if [ -z "${TAIGA_WEBSOCKETS_URL:-}" ]; then
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
        export TAIGA_WEBSOCKETS_URL="wss://${RAILWAY_PUBLIC_DOMAIN}"
    else
        export TAIGA_WEBSOCKETS_URL="ws://localhost"
    fi
fi
export TAIGA_SUBPATH="${TAIGA_SUBPATH:-}"

# Defaults ajustados a la capa gratuita de Railway (512 MB por servicio)
export GUNICORN_WORKERS="${GUNICORN_WORKERS:-1}"
export CELERY_CONCURRENCY="${CELERY_CONCURRENCY:-1}"

# --- 1. Esperar a PostgreSQL ---------------------------------------------
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

# --- 2. Migraciones + plantillas + estáticos -----------------------------
echo "[railway] Aplicando migraciones..."
python manage.py migrate --noinput

echo "[railway] Cargando plantillas iniciales..."
python manage.py loaddata initial_project_templates

echo "[railway] Recogiendo archivos estáticos..."
python manage.py collectstatic --noinput

# --- 3. Bootstrap del administrador --------------------------------------
if [ "${ADMIN_BOOTSTRAP_ENABLED:-true}" = "true" ]; then
    echo "[railway] Verificando administrador inicial..."
    python /taiga-back/railway_bootstrap_admin.py
else
    echo "[railway] ADMIN_BOOTSTRAP_ENABLED=false, omitiendo administrador inicial."
fi

# --- 4. Configuración del front (conf.json) -------------------------------
# Se elimina cualquier conf.json previo para forzar su regeneración con las
# URLs reales (mismo comportamiento que la imagen oficial de taiga-front).
rm -f /usr/share/nginx/html/conf.json
bash /taiga-back/railway_config_env_subst.sh

# --- 5. Configuración de taiga-events (.env) ------------------------------
{
    echo "RABBITMQ_URL=\"amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@${TAIGA_EVENTS_RABBITMQ_HOST:-rabbitmq.railway.internal}:5672/taiga\""
    echo "SECRET=\"${TAIGA_SECRET_KEY}\""
    echo "WEB_SOCKET_SERVER_PORT=8888"
    echo "APP_PORT=3023"
} > /taiga-events/.env

# --- 6. Permisos y arranque ----------------------------------------------
# En algunos despliegues Railway conserva el symlink sites-enabled/default
# del paquete nginx; se elimina por seguridad para evitar conflictos con
# nuestro server block.
rm -f /etc/nginx/sites-enabled/default
chown -R taiga:taiga /taiga-back /taiga-events

echo "[railway] Arrancando supervisord (nginx + gunicorn + celery + events)..."
exec supervisord -n -c /etc/supervisor/supervisord.conf
