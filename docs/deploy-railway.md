# Despliegue manual en Railway

Guía paso a paso para levantar Taiga en Railway desde cero, **sin usar el
template publicado**. Es el proceso que la plantilla automatiza y sirve para
reproducir el proyecto de referencia a mano.

> Requisitos: una cuenta en Railway y este repositorio (el servicio `app` se
> construye desde su Dockerfile).

## 1. Crear el proyecto

1. En Railway, pulsa **New Project** → **Empty Project** (vacío).
2. Anota el **nombre del proyecto**. Usaremos `app`, `postgres` y `rabbitmq`
   como nombres de servicio (los hostnames de la red privada dependen de
   ellos).

## 2. Crear los servicios

Todos se comunican por la red privada (`*.railway.internal`); solo `app`
tiene dominio público.

### 2.1 PostgreSQL

- **New Service** → **GitHub Repo / Docker Image** → imagen `postgres:12.3`.
- Variables del servicio:

  | Variable | Valor |
  |---|---|
  | `PGDATA` | `/var/lib/postgresql/data/pgdata` |
  | `POSTGRES_USER` | `taiga` |
  | `POSTGRES_PASSWORD` | `${{secret(32)}}` (generar) |
  | `POSTGRES_DB` | `taiga` |

- **Volumes**: crear volumen montado en `/var/lib/postgresql/data`.
- No exponer puertos públicos.

> `PGDATA` debe apuntar a un subdirectorio del volumen; si apunta a la raíz,
> PostgreSQL falla con `initdb: directory exists but is not empty`
> (`lost+found` del punto de montaje).

### 2.2 RabbitMQ

- **New Service** → **GitHub Repo / Docker Image** → imagen
  `rabbitmq:3.8.34-alpine`.
- Variables del servicio:

  | Variable | Valor |
  |---|---|
  | `RABBITMQ_DEFAULT_USER` | `taiga` |
  | `RABBITMQ_DEFAULT_PASS` | `${{secret(32)}}` (generar) |
  | `RABBITMQ_DEFAULT_VHOST` | `taiga` |

- **Volumes**: crear volumen montado en `/var/lib/rabbitmq`.
- No exponer puertos públicos.

### 2.3 app (todo-en-uno, desde este repositorio)

Contiene nginx (SPA + proxy), gunicorn (API), celery (worker + beat) y
taiga-events (WebSockets), orquestados por supervisord.

- **New Service** → **GitHub Repo** → selecciona este repositorio.
- **Root Directory**: `docker/app`.
- **Networking** → **Generate Domain** (este es el dominio público final) y
  fija el **target port a 80** (la autodetección puede quedarse con el puerto
  que hereda la imagen base, `8000`).
- **Volumes**: crear volumen montado en `/taiga-back/media`.
- Variables del servicio:

  | Variable | Valor |
  |---|---|
  | `DJANGO_SETTINGS_MODULE` | `settings.settings_railway` |
  | `TAIGA_SECRET_KEY` | `${{secret(32)}}` (generar) |
  | `POSTGRES_HOST` | `postgres.railway.internal` |
  | `POSTGRES_PORT` | `5432` |
  | `POSTGRES_USER` | `taiga` |
  | `POSTGRES_PASSWORD` | la misma que en PostgreSQL (referencia `${{ Postgres.POSTGRES_PASSWORD }}`) |
  | `POSTGRES_DB` | `taiga` |
  | `RABBITMQ_USER` | `taiga` |
  | `RABBITMQ_PASS` | la misma que en RabbitMQ (referencia `${{ RabbitMQ.RABBITMQ_DEFAULT_PASS }}`) |
  | `TAIGA_EVENTS_RABBITMQ_HOST` | `rabbitmq.railway.internal` |
  | `TAIGA_ASYNC_RABBITMQ_HOST` | `rabbitmq.railway.internal` |
  | `ADMIN_USER` | `admin` |
  | `ADMIN_EMAIL` | `admin@example.com` |
  | `ADMIN_INITIAL_PASSWORD` | `${{secret(32)}}` (generar) |
  | `ADMIN_BOOTSTRAP_ENABLED` | `true` |
  | `GUNICORN_WORKERS` | `1` (opcional) |
  | `CELERY_CONCURRENCY` | `1` (opcional) |

> La URL pública del sitio se deriva automáticamente de
> `RAILWAY_PUBLIC_DOMAIN`; no hay que definir `TAIGA_SITES_DOMAIN`.

## 3. Verificación

1. Abre la URL pública del servicio `app`: debe cargar la pantalla de login
   de Taiga.
2. Inicia sesión con `admin` / `ADMIN_INITIAL_PASSWORD` (lo copias de las
   Variables del proyecto).
3. Crea un proyecto de prueba y comprueba que las tareas y el timeline en
   tiempo real funcionan (WebSockets).

## Notas

- Los hostnames `*.railway.internal` se resuelven solo dentro del mismo
  proyecto. No cambies el nombre de los servicios.
- El primer arranque del `app` tarda más: aplica migraciones, carga las
  plantillas, recoge estáticos y crea el admin.
- Cambia `ADMIN_INITIAL_PASSWORD` tras el primer acceso.
- Para desplegar en un clic, usa el template:
  https://railway.com/deploy/taiga (ver `docs/guia-template.md`).
