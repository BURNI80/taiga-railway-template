# Taiga en Railway (plantilla)

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/taiga)

[Taiga](https://www.taiga.io/) es una herramienta de gestión de proyectos
(Scrum, Kanban) libre y open source. Esta plantilla despliega una instancia
completa de Taiga en [Railway](https://railway.app/) con la mínima
configuración posible por parte del usuario final.

> **Un clic:** despliega directamente con el botón de arriba o desde
> https://railway.com/deploy/taiga. No hay variables que rellenar a mano:
> los secrets se generan automáticamente y el primer administrador se crea
> solo.

## Arquitectura

El proyecto se compone de **3 servicios** dentro de un mismo proyecto de
Railway. Para que todo quepa en la capa gratuita (3 servicios, 512 MB por
servicio), el stack de Taiga se empaqueta en un único contenedor:

- **`app`** (contenedor todo-en-uno): nginx (SPA + reverse proxy) + gunicorn
  (API de Django) + celery (worker + beat) + taiga-events (WebSockets),
  orquestados con supervisord.
- **`postgres`**: base de datos.
- **`rabbitmq`**: broker de mensajes (tareas asíncronas y eventos).

```
Cliente (https://<tu-dominio>.up.railway.app)
   │
   ▼
┌─────────────────────────────────────────────┐
│  app (todo-en-uno)                           │
│  nginx (80) ─► SPA                           │
│    │─ /api/ /admin/ /static/ /media/ ─► gunicorn (8000)
│    │─ /events ────────────────────────► taiga-events (8888)
│    └─ celery worker + beat (colas)            │
└──────┬──────────────────────────────┬────────┘
       │                              │
       ▼ (red privada)                ▼
┌────────────┐                ┌────────────┐
│  postgres   │                │  rabbitmq   │
│  (5432)     │                │  (5672)     │
└────────────┘                └────────────┘
```

| Servicio | Imagen / origen | Puerta de red | Volumen |
|---|---|---|---|
| `app` | Repo `docker/app` (sobre `taigaio/taiga-back:6.10.2`) | Pública (puerto 80) | `/taiga-back/media` |
| `postgres` | `postgres:12.3` | Privada | `/var/lib/postgresql/data` |
| `rabbitmq` | `rabbitmq:3.8.34-alpine` | Privada | `/var/lib/rabbitmq` |

Todos los servicios se comunican por la red privada (`*.railway.internal`);
solo el `app` queda expuesto públicamente.

### Contenido del contenedor `app`

| Proceso | Rol | Puerto |
|---|---|---|
| `nginx` | Sirve la SPA y hace de reverse proxy | 80 (público) |
| `gunicorn` | API de Django (`taiga.wsgi`) | 8000 |
| `celery -B` | Worker de tareas asíncronas + beat | — |
| `taiga-events` | WebSockets en tiempo real | 8888 |

### Variables de entorno

Definidas en la plantilla con funciones `${{secret(...)}}` y variables de
referencia, de modo que el usuario final **no configura nada**. La más
relevante después del despliegue es:

| Variable | Valor en el template | Descripción |
|---|---|---|
| `ADMIN_INITIAL_PASSWORD` | `${{secret(32)}}` | Contraseña del admin (se copia de Project → Variables tras desplegar) |
| `ADMIN_USER` | `admin` | Primer administrador (se crea automáticamente) |
| `ADMIN_EMAIL` | `admin@example.com` | Email del admin |
| `TAIGA_SECRET_KEY` | `${{secret(32)}}` | Clave secreta de Django |
| `DJANGO_SETTINGS_MODULE` | `settings.settings_railway` | Settings propios de Railway |
| `POSTGRES_HOST` / `POSTGRES_PORT` | `postgres.railway.internal` / `5432` | Conexión privada a Postgres |
| `POSTGRES_USER` / `POSTGRES_DB` | `${{ Postgres.POSTGRES_USER }}` / `${{ Postgres.POSTGRES_DB }}` | Referencias al servicio Postgres |
| `POSTGRES_PASSWORD` | `${{ Postgres.POSTGRES_PASSWORD }}` | Referencia al secret de Postgres |
| `RABBITMQ_USER` | `${{ RabbitMQ.RABBITMQ_DEFAULT_USER }}` | Referencia a RabbitMQ |
| `RABBITMQ_PASS` | `${{ RabbitMQ.RABBITMQ_DEFAULT_PASS }}` | Referencia al secret de RabbitMQ |
| `TAIGA_EVENTS_RABBITMQ_HOST` / `TAIGA_ASYNC_RABBITMQ_HOST` | `rabbitmq.railway.internal` | Host privado de RabbitMQ |
| `GUNICORN_WORKERS` / `CELERY_CONCURRENCY` | `1` / `1` | Ajustados a la capa gratuita |
| `ADMIN_BOOTSTRAP_ENABLED` | `true` | Crea el admin en el primer arranque |

> La URL pública del sitio se deriva automáticamente de
> `RAILWAY_PUBLIC_DOMAIN`; no hay que definir `TAIGA_SITES_DOMAIN`.

### Postgres: por qué `PGDATA`

El servicio `postgres` define `PGDATA=/var/lib/postgresql/data/pgdata`. Sin
ella, PostgreSQL falla al arrancar sobre un volumen con
`initdb: directory exists but is not empty` (el punto de montaje contiene
`lost+found`). Al apuntar `PGDATA` a un subdirectorio el cluster se
inicializa correctamente.

### nginx: puerto objetivo del dominio

La imagen base `taigaio/taiga-back` declara `EXPOSE 8000`, que hereda nuestro
`EXPOSE 80`. La autodetección de puerto de Railway puede quedarse con el
puerto equivocado, así que el dominio del template está fijado
explícitamente al **puerto 80**.

## Despliegue

### Opción A — Template (recomendada)

1. Pulsa el botón de arriba o entra en https://railway.com/deploy/taiga.
2. Railway crea el proyecto con los 3 servicios y todos los secrets.
3. Espera al primer arranque (migraciones + creación del admin, ~2 min).
4. Abre el dominio público del servicio `app` e inicia sesión con `admin` y
   el valor de `ADMIN_INITIAL_PASSWORD` (lo ves en el proyecto: **Variables**).

### Opción B — Manual

El proceso paso a paso está en [docs/deploy-railway.md](docs/deploy-railway.md).

### Requisitos de la capa gratuita

- 3 servicios, dentro del límite de 3 del plan free.
- `GUNICORN_WORKERS=1` y `CELERY_CONCURRENCY=1` para mantenerse dentro de los
  512 MB por servicio (vigila el pico de memoria en el primer arranque).
- Un único volumen por servicio (media, postgres y rabbitmq).

## Estructura del repositorio

```
├── docker/
│   ├── app/            Contenedor todo-en-uno de Taiga (activo)
│   │   ├── Dockerfile
│   │   ├── entrypoint.sh
│   │   ├── nginx.conf
│   │   ├── supervisord.conf
│   │   ├── settings_railway.py
│   │   ├── urls_railway.py
│   │   ├── config_env_subst.sh
│   │   └── bootstrap_admin.py
│   ├── back/           (legacy) Backend separado de la arquitectura anterior
│   └── gateway/        (legacy) Gateway nginx de la arquitectura anterior
├── docs/
│   ├── deploy-railway.md    Pasos manuales de despliegue
│   ├── guia-template.md     Cómo publicar/mantener el template
│   └── template-overview.md Markdown del template en Railway
├── LICENSE
└── THIRD_PARTY.md
```

> `docker/back` y `docker/gateway` corresponden a la primera arquitectura
> (servicios separados) y ya no se usan; se conservan como referencia.

## Solución de problemas

- **502/499 en el dominio**: comprueba que el dominio del servicio `app` tiene
  **target port 80** (si la autodetección eligió otro puerto, se rompe).
- **"Welcome to nginx!" en lugar de Taiga**: el `index.html` de la SPA se
  sobrescribe si el paquete nginx de Debian se instala después del COPY del
  front. El Dockerfile ya copia el front después del `apt-get install`; si
  vuelve a pasar, redespliega el `app`.
- **Postgres `initdb: directory exists but is not empty`**: revisa que
  `PGDATA=/var/lib/postgresql/data/pgdata` esté definido en `postgres`.
- **El admin no se crea**: mira los logs de `app`; con
  `ADMIN_BOOTSTRAP_ENABLED=true` el script crea el superuser de forma
  idempotente (si ya existe, lo omite).
- **Los avatares/adjuntos no cargan**: comprueba que el volumen
  `/taiga-back/media` está montado en `app`.
- **La SPA carga pero la API falla**: revisa que `app` resuelve
  `postgres.railway.internal` y `rabbitmq.railway.internal` (red privada del
  mismo proyecto).

## Licencias

Ver [THIRD_PARTY.md](THIRD_PARTY.md) y [LICENSE](LICENSE).
