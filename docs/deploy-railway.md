# Despliegue manual en Railway

Guía paso a paso para levantar Taiga en Railway desde cero. Es el proceso
que la plantilla publicada automatiza; esta guía sirve para desplegarlo a
mano y para reproducir el proyecto de referencia.

> Requisitos: una cuenta en Railway y este repositorio (para los servicios
> que se construyen desde Dockerfile).

## 1. Crear el proyecto

1. En Railway, pulsa **New Project** → **Empty Project** (vacío).
2. Anota el **nombre del proyecto**. Usaremos `taiga-back`, `taiga-events`,
   `rabbitmq`, `postgres` y `gateway` como nombres de servicio.

## 2. Crear los servicios

> Todas las imágenes PostgreSQL/RabbitMQ/events se despliegan desde
> **Docker Image**; `taiga-back` y `taiga-async` se construyen desde este
> repositorio (mismo Dockerfile en `docker/back`). Es recomendable fijar
> **límites de memoria** en postgres y rabbitmq (p. ej. 512 MB) para
> ajustarse a la capa gratuita.

### 2.1 PostgreSQL

- **New Service** → **Docker Image** → imagen `postgres:12.3`.
- Variables del servicio:

  | Variable | Valor |
  |---|---|
  | `POSTGRES_USER` | `taiga` |
  | `POSTGRES_PASSWORD` | `${{secret()}}` (generar) |
  | `POSTGRES_DB` | `taiga` |

- **Volumes**: crear volumen montado en `/var/lib/postgresql/data`.
- No exponer puertos públicos.

### 2.2 RabbitMQ

- **New Service** → **Docker Image** → imagen `rabbitmq:3.8.34-alpine`.
- Variables del servicio:

  | Variable | Valor |
  |---|---|
  | `RABBITMQ_DEFAULT_USER` | `taiga` |
  | `RABBITMQ_DEFAULT_PASS` | `${{secret()}}` (generar) |
  | `RABBITMQ_DEFAULT_VHOST` | `taiga` |

- **Volumes**: crear volumen montado en `/var/lib/rabbitmq`.
- No exponer puertos públicos.

### 2.3 taiga-events

- **New Service** → **Docker Image** → imagen `taigaio/taiga-events:6.10.0`.
- Variables del servicio:

  | Variable | Valor |
  |---|---|
  | `RABBITMQ_URL` | `amqp://taiga:<RABBITMQ_PASS>@rabbitmq.railway.internal:5672/taiga` |

  Sustituye `<RABBITMQ_PASS>` por la contraseña de RabbitMQ (usa una
  referencia `${{...}}` a la variable compartida cuando sea posible).
- No exponer puertos públicos.

### 2.4 taiga-back (desde este repositorio)

- **New Service** → **GitHub Repo** → selecciona este repositorio.
- **Root Directory**: `docker/back`.
- Variables del servicio (pueden definirse a nivel de proyecto para
  compartirse):

  | Variable | Valor |
  |---|---|
  | `DJANGO_SETTINGS_MODULE` | `settings.settings_railway` |
  | `TAIGA_SECRET_KEY` | `${{secret()}}` (generar) |
  | `TAIGA_SITES_SCHEME` | `https` |
  | `TAIGA_SITES_DOMAIN` | `<tu-dominio>.up.railway.app` |
  | `POSTGRES_HOST` | `postgres.railway.internal` |
  | `POSTGRES_PORT` | `5432` |
  | `POSTGRES_USER` | `taiga` |
  | `POSTGRES_PASSWORD` | la misma que la de PostgreSQL |
  | `POSTGRES_DB` | `taiga` |
  | `RABBITMQ_USER` | `taiga` |
  | `RABBITMQ_PASS` | la misma que en RabbitMQ |
  | `TAIGA_EVENTS_RABBITMQ_HOST` | `rabbitmq.railway.internal` |
  | `TAIGA_ASYNC_RABBITMQ_HOST` | `rabbitmq.railway.internal` |
  | `TAIGA_BACK_URL` | `http://taiga-back.railway.internal:8000` |
  | `TAIGA_EVENTS_URL` | `ws://taiga-events.railway.internal:8888/events` |
  | `ADMIN_USER` | `admin` |
  | `ADMIN_EMAIL` | `admin@example.com` |
  | `ADMIN_INITIAL_PASSWORD` | `${{secret()}}` (generar) |
  | `ADMIN_BOOTSTRAP_ENABLED` | `true` |
  | `ALLOWED_HOSTS` | `*` |
  | `GUNICORN_WORKERS` | `2` (opcional) |

- **Volumes**: dos volúmenes, montados en `/taiga-back/media` y
  `/taiga-back/static`.
- No exponer puertos públicos.
- Verificar que el despliegue termina con el log
  `[railway] Delegando en el entrypoint oficial...`.

### 2.6 taiga-async (worker de Celery, desde este repositorio)

Es el servicio que procesa las tareas asíncronas (timeline en tiempo real,
notificaciones por email, ...). Usa el mismo Dockerfile que `taiga-back`
con `ROLE=async`.

- **New Service** → **GitHub Repo** → selecciona este repositorio.
- **Root Directory**: `docker/back`.
- Variables del servicio:

  | Variable | Valor |
  |---|---|
  | `ROLE` | `async` |
  | `DJANGO_SETTINGS_MODULE` | `settings.settings_railway` |
  | `TAIGA_SECRET_KEY` | la misma que en `taiga-back` |
  | `POSTGRES_HOST` / `POSTGRES_PORT` / `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | las mismas que en `taiga-back` |
  | `RABBITMQ_USER` / `RABBITMQ_PASS` | las mismas que en `taiga-back` |
  | `TAIGA_EVENTS_RABBITMQ_HOST` / `TAIGA_ASYNC_RABBITMQ_HOST` | las mismas que en `taiga-back` |
  | `CELERY_CONCURRENCY` | `2` (opcional) |

- No exponer puertos públicos.

### 2.7 gateway (desde este repositorio)

- **New Service** → **GitHub Repo** → selecciona este repositorio.
- **Root Directory**: `docker/gateway`.
- **Networking** → **Generate Domain** (este es el dominio público final).
- No necesita variables (deriva la URL pública de `RAILWAY_PUBLIC_DOMAIN`).

## 3. Verificación

1. Abre la URL pública del **gateway**: debe cargar la pantalla de login.
2. Inicia sesión con `admin` / `ADMIN_INITIAL_PASSWORD`.
3. Crea un proyecto de prueba y comprueba que las tareas y el timeline en
   tiempo real funcionan (WebSockets).

## Notas

- Los hostnames `*.railway.internal` se resuelven solo dentro del mismo
  proyecto. No cambies el nombre de los servicios.
- Cambia `ADMIN_INITIAL_PASSWORD` tras el primer acceso.
- Para el despliegue de la plantilla publicada, ver `docs/guia-template.md`.
