# Taiga todo-en-uno para Railway.
#
# Fusiona las imágenes oficiales de Taiga (back + front + events) en un
# único contenedor gestionado por supervisord, de modo que todo el stack
# cabe en los 3 servicios que permite la capa gratuita de Railway
# (postgres, rabbitmq y app).
#
# Procesos dentro del contenedor:
#   - nginx         (SPA + reverse proxy, puerto 80 -> público)
#   - gunicorn      (API de Django, puerto 8000)
#   - celery worker (tareas asíncronas, -B incluye beat)
#   - node events   (WebSockets, puerto 8888)
#
# Orígenes: taigaio/taiga-back:6.10.2 (MPL-2.0), taigaio/taiga-front:6.10.3
# (AGPL-3.0) y taigaio/taiga-events:6.10.0 (MPL-2.0). Ver THIRD_PARTY.md.
FROM taigaio/taiga-back:6.10.2

LABEL org.opencontainers.image.title="Taiga all-in-one (Railway)"
LABEL org.opencontainers.image.description="Taiga completo (front + back + events + celery) en un contenedor para Railway."
LABEL org.opencontainers.image.source="https://github.com/tu-usuario/taiga-railway-template"

# --- Backend: settings y urls propios de Railway -------------------------
COPY settings_railway.py /taiga-back/settings/settings_railway.py
COPY urls_railway.py /taiga-back/urls_railway.py
COPY bootstrap_admin.py /taiga-back/railway_bootstrap_admin.py

# --- Events: servidor WebSocket desde la imagen oficial de taiga-events --
COPY --from=taigaio/taiga-events:6.10.0 /taiga-events /taiga-events

# --- Herramientas extra: nginx, node, supervisor, bash, envsubst ---------
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bash \
        gettext-base \
        nginx \
        nodejs \
        supervisor; \
    rm -rf /var/lib/apt/lists/*

# --- Front: SPA desde la imagen oficial de taiga-front -------------------
# Debe copiarse DESPUÉS de instalar el paquete nginx de Debian, porque su
# postinst escribe su propio index.html ("Welcome to nginx!") en
# /usr/share/nginx/html/index.html y pisaría la SPA de Taiga.
COPY --from=taigaio/taiga-front:6.10.3 /usr/share/nginx/html /usr/share/nginx/html

# --- Config de nginx (SPA + proxy a los procesos internos) ---------------
COPY nginx.conf /etc/nginx/sites-available/taiga.conf
RUN ln -sf /etc/nginx/sites-available/taiga.conf /etc/nginx/sites-enabled/taiga.conf \
    && rm -f /etc/nginx/sites-enabled/default \
    && rm -f /etc/nginx/conf.d/default.conf

# --- Supervisord (orquesta los 4 procesos) -------------------------------
COPY supervisord.conf /etc/supervisor/conf.d/taiga.conf

# --- Scripts de arranque ---------------------------------------------------
COPY entrypoint.sh /taiga-back/railway_entrypoint.sh
COPY config_env_subst.sh /taiga-back/railway_config_env_subst.sh

RUN chmod +x /taiga-back/railway_entrypoint.sh \
    && chmod +x /taiga-back/railway_config_env_subst.sh \
    && chown taiga:taiga /taiga-back/settings/settings_railway.py \
    && chown taiga:taiga /taiga-back/urls_railway.py \
    && chown taiga:taiga /taiga-back/railway_bootstrap_admin.py

ENV DJANGO_SETTINGS_MODULE=settings.settings_railway

EXPOSE 80

ENTRYPOINT ["/taiga-back/railway_entrypoint.sh"]
