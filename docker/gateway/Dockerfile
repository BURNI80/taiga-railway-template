# Gateway público de Taiga para Railway.
#
# Parte de la imagen oficial de Taiga front (nginx + SPA, AGPL-3.0,
# ver THIRD_PARTY.md) y reemplaza su configuración por un reverse proxy
# completo que sirve la SPA y redirige /api, /admin, /static, /media y
# /events hacia los servicios privados del proyecto de Railway.
FROM taigaio/taiga-front:6.10.3

LABEL org.opencontainers.image.title="Taiga gateway (Railway)"
LABEL org.opencontainers.image.description="Entrada pública de Taiga en Railway: SPA + reverse proxy hacia el backend y los eventos."
LABEL org.opencontainers.image.source="https://github.com/tu-usuario/taiga-railway-template"

# Reverse proxy completo (SPA + API + admin + static + media + websockets)
COPY gateway.conf /etc/nginx/conf.d/default.conf

# Deriva la URL pública del SPA a partir de RAILWAY_PUBLIC_DOMAIN.
# Debe ser un archivo ".envsh" (no ".sh"): nginx hace "source" de los
# .envsh, así que las variables exportadas llegan al script oficial
# 30_config_env_subst.sh. Los .sh se ejecutan en un subproceso y sus
# exports se perderían.
COPY 20_railway_env.envsh /docker-entrypoint.d/20_railway_env.envsh

RUN chmod +x /docker-entrypoint.d/20_railway_env.envsh

EXPOSE 80
