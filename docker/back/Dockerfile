# Taiga backend adaptado para Railway.
#
# Parte de la imagen oficial de Taiga backend (MPL-2.0, ver THIRD_PARTY.md)
# y añade: settings propios, URLs que sirven /static y /media sobre HTTP
# y un entrypoint que espera a PostgreSQL, recoge archivos estáticos y
# crea el primer administrador automáticamente.
FROM taigaio/taiga-back:6.10.2

LABEL org.opencontainers.image.title="Taiga backend (Railway)"
LABEL org.opencontainers.image.description="API de Taiga preparada para Railway: sirve /static y /media sobre HTTP y auto-configura el primer admin."
LABEL org.opencontainers.image.source="https://github.com/tu-usuario/taiga-railway-template"

# Settings propios de Railway (heredan toda la config oficial vía env vars)
COPY settings_railway.py /taiga-back/settings/settings_railway.py
# URLconf propia: incluye todas las rutas de Taiga y añade /static y /media
COPY urls_railway.py /taiga-back/urls_railway.py
# Scripts auxiliares usados por el entrypoint
COPY bootstrap_admin.py /taiga-back/railway_bootstrap_admin.py
COPY entrypoint.sh /taiga-back/railway_entrypoint.sh

# Usamos nuestros settings por defecto
ENV DJANGO_SETTINGS_MODULE=settings.settings_railway

RUN chmod +x /taiga-back/railway_entrypoint.sh \
    && chown taiga:taiga /taiga-back/settings/settings_railway.py \
    && chown taiga:taiga /taiga-back/urls_railway.py \
    && chown taiga:taiga /taiga-back/railway_bootstrap_admin.py \
    && chown taiga:taiga /taiga-back/railway_entrypoint.sh

EXPOSE 8000

# Entrypoint propio que delega en el oficial tras preparar el entorno
ENTRYPOINT ["/taiga-back/railway_entrypoint.sh"]
