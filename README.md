# Taiga en Railway (plantilla)

[Taiga](https://www.taiga.io/) es una herramienta de gestión de proyectos
(Scrum, Kanban) libre y open source. Esta plantilla despliega una
instancia completa de Taiga en [Railway](https://railway.app/) con la
mínima configuración posible por parte del usuario final.

## Arquitectura

El proyecto se compone de **6 servicios** dentro de un mismo proyecto de
Railway. Todos ellos se comunican por la red privada (`*.railway.internal`);
solo el **gateway** queda expuesto públicamente.

```
Cliente (https://<tu-dominio>.up.railway.app)
   │
   ▼
┌──────────────────┐   (red privada)
│    gateway        │  nginx: SPA + reverse proxy
└──────┬───────┬────┘
       │       │
   /api/ /admin/   /events
   /static/ /media/
       │       │
       ▼       ▼
┌───────────┐ ┌──────────────┐
│ taiga-back │ │ taiga-events │
│  (gunicorn)│ │  (websockets)│
└─────┬─────┘ └──────┬───────┘
      │              │
      │              ▼
      │        ┌────────────┐
      │        │  rabbitmq   │
      │        └────────────┘
      ├────────────┐
      ▼            ▼
┌────────────┐ ┌────────────┐
│  postgres   │ │ taiga-async│
│             │ │  (celery)  │
└────────────┘ └────────────┘
```

| Servicio | Imagen / origen | Puerta de red | Volúmenes |
|---|---|---|---|
| `gateway` | `docker/gateway` (sobre `taigaio/taiga-front:6.10.3`) | Pública (HTTP) | — |
| `taiga-back` | `docker/back` (sobre `taigaio/taiga-back:6.10.2`) | Privada | `/taiga-back/media`, `/taiga-back/static` |
| `taiga-async` | `docker/back` con `ROLE=async` (Celery) | Privada | — |
| `taiga-events` | `taigaio/taiga-events:6.10.0` | Privada | — |
| `rabbitmq` | `rabbitmq:3.8.34-alpine` | Privada | `/var/lib/rabbitmq` |
| `postgres` | `postgres:12.3` | Privada | `/var/lib/postgresql/data` |

### Por qué un volumen `static` y `media` propios

Railway **no permite compartir un volumen entre varios servicios**. En el
despliegue oficial de Taiga, nginx sirve los estáticos desde el mismo
volumen que comparte con el backend. Aquí el backend recoge los estáticos
en `collectstatic` al arrancar y los sirve él mismo sobre HTTP; el gateway
simplemente los redirige por la red privada. Los adjuntos (`media`) se
almacenan en el volumen del backend y se sirven de la misma forma.

### Variables de entorno

Todas las variables quedan definidas en la plantilla. El usuario final solo
debe rellenar las de tipo *secret* que le pida Railway al crear el
proyecto. Las más relevantes:

| Variable | Descripción |
|---|---|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | Credenciales de PostgreSQL |
| `TAIGA_SECRET_KEY` | Clave secreta de Django (generar una aleatoria) |
| `TAIGA_SITES_SCHEME` / `TAIGA_SITES_DOMAIN` | URL pública de la instalación |
| `ADMIN_INITIAL_PASSWORD` | Contraseña del primer administrador |
| `GUNICORN_WORKERS` | Workers de gunicorn (default `2`) |
| `CELERY_CONCURRENCY` | Concurrencia del worker de Celery (default `2`) |
| `RABBITMQ_USER` / `RABBITMQ_PASS` | Credenciales de RabbitMQ |
| `TAIGA_EVENTS_RABBITMQ_HOST` / `TAIGA_ASYNC_RABBITMQ_HOST` | Hostname privado de RabbitMQ |
| `TAIGA_BACK_URL` / `TAIGA_EVENTS_URL` | URLs internas usadas por la API |

> El gateway deriva su URL pública de `RAILWAY_PUBLIC_DOMAIN`
> automáticamente, sin configuración adicional.

## Despliegue

1. Crea un proyecto vacío en [Railway](https://railway.app/new).
2. Añade los servicios tal y como se indica en
   [docs/deploy-railway.md](docs/deploy-railway.md) (o usa la plantilla
   publicada: Railway desplegará todo automáticamente).
3. Espera al primer despliegue: `taiga-back` recoge estáticos y crea el
   administrador en el arranque inicial.
4. Accede a la URL pública del servicio `gateway` e inicia sesión con el
   usuario `admin` y la contraseña definida en `ADMIN_INITIAL_PASSWORD`.

### Requisitos de la capa gratuita

Se ha configurado todo para que quepa en la capa gratuita de Railway:
- PostgreSQL y RabbitMQ con límites de memoria ajustados.
- Workers de gunicorn y Celery reducidos (variables `GUNICORN_WORKERS` y
  `CELERY_CONCURRENCY`, por defecto `2`).
- Un único volumen por servicio (solo back, rabbitmq y postgres).

## Estructura del repositorio

```
├── docker/
│   ├── back/           Backend (imagen oficial + settings/entrypoint propios)
│   │   ├── Dockerfile
│   │   ├── entrypoint.sh
│   │   ├── settings_railway.py
│   │   ├── urls_railway.py
│   │   └── bootstrap_admin.py
│   └── gateway/        Gateway público (nginx + reverse proxy)
│       ├── Dockerfile
│       ├── gateway.conf
│       └── 20_railway_env.envsh
├── docs/
│   ├── deploy-railway.md   Pasos manuales de despliegue
│   └── guia-template.md    Guía para publicar la plantilla
├── LICENSE
└── THIRD_PARTY.md
```

## Solución de problemas

- **La SPA carga pero la API falla**: revisa que el servicio `taiga-back`
  esté en la red privada y que la variable `TAIGA_URL` del gateway sea la
  URL pública.
- **Los avatares/adjuntos no cargan**: comprueba que `/media/` llega al
  backend y que el volumen `/taiga-back/media` está montado.
- **El admin no se crea**: mira los logs de `taiga-back`; si
  `ADMIN_INITIAL_PASSWORD` está vacía se omite (a propósito) la creación.
- **No renombres los servicios**: los hostnames `taiga-back.railway.internal`
  y `taiga-events.railway.internal` están fijados en `gateway.conf`.

## Licencias

Ver [THIRD_PARTY.md](THIRD_PARTY.md) y [LICENSE](LICENSE).
