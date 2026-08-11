# Template overview (Railway)

Este markdown es el **overview** que se muestra en la página del template en
Railway (https://railway.com/deploy/taiga). Es el contenido publicado en el
campo *Description* de la plantilla.

> Si cambias este fichero, actualiza también el overview del template desde
> el editor del template en Railway (o con
> `railway templates publish <id> --readme-file docs/template-overview.md`).

---

# Deploy and Host Taiga on Railway

Taiga is a free, open-source project management platform built for agile
teams. It supports Scrum, Kanban and mixed workflows with backlogs, sprints,
user stories, tasks, issues, wikis and real-time collaboration. It is
developed by Kaleidos and released under MPL-2.0 (backend/events) and
AGPL-3.0 (frontend).

## About Hosting Taiga

Hosting Taiga means running four cooperating pieces: the web frontend (SPA),
the Django backend API (gunicorn), the real-time events/WebSocket server and
the Celery async worker, all backed by PostgreSQL and RabbitMQ. The official
images ship separately, so a typical deployment requires wiring them together
with private networking, shared volumes and coordinated configuration.

This template packages everything into a single all-in-one container
(nginx + gunicorn + celery + taiga-events, orchestrated by supervisord). A
complete Taiga instance runs with just three services: `app`, `postgres` and
`rabbitmq`. It fits the Railway free tier, auto-creates the first admin user,
and derives the public site URL automatically from your domain.

## Common Use Cases

- Self-hosting a full project management suite (Scrum/Kanban) for your team
  or company without maintaining separate services.
- Replacing commercial project management tools (Jira, Linear, Notion) with an
  open-source, data-you-own alternative.
- Running a complete multi-process stack on the Railway free tier with minimal
  monthly cost and zero infrastructure setup.

## Dependencies for Taiga Hosting

- PostgreSQL 12+ — main database for all Taiga data.
- RabbitMQ 3.x — message broker used by Celery (async tasks) and taiga-events
  (real-time notifications/WebSockets).

### Deployment Dependencies

- [Taiga official site](https://www.taiga.io/)
- [Taiga documentation](https://docs.taiga.io/)
- [taiga-back Docker image](https://hub.docker.com/r/taigaio/taiga-back)
- [taiga-front Docker image](https://hub.docker.com/r/taigaio/taiga-front)
- [taiga-events Docker image](https://hub.docker.com/r/taigaio/taiga-events)
- [Railway documentation](https://docs.railway.com/)

### Implementation Details

The template creates three services connected through Railway's private
network (`*.railway.internal`); only `app` is exposed publicly:

| Service   | Build                                | Ports                | Volume                        |
|-----------|--------------------------------------|----------------------|-------------------------------|
| `app`     | `docker/app` (all-in-one container)  | 80 public, 8000, 8888| `/taiga-back/media`           |
| `postgres`| `postgres:12.3`                      | 5432 (private)       | `/var/lib/postgresql/data`    |
| `rabbitmq`| `rabbitmq:3.8.34-alpine`             | 5672 (private)       | `/var/lib/rabbitmq`           |

Configuration highlights:

- The public domain target port is set to **80** (the all-in-one container
  serves the SPA through nginx).
- `PGDATA=/var/lib/postgresql/data/pgdata` avoids the PostgreSQL `initdb`
  error caused by the volume's `lost+found` directory.
- Secrets (`POSTGRES_PASSWORD`, `RABBITMQ_DEFAULT_PASS`, `TAIGA_SECRET_KEY`,
  `ADMIN_INITIAL_PASSWORD`) are generated on every deploy with
  `${{secret(32)}}`; the `app` service references them from `postgres` and
  `rabbitmq` so nothing needs manual configuration.
- On first boot the container runs migrations, loads the default project
  templates, collects static files and creates the first admin user
  (`admin`, password in the project Variables).
- The stack is tuned for the free tier (1 gunicorn worker, Celery concurrency
  1) and can be scaled up by changing `GUNICORN_WORKERS` / `CELERY_CONCURRENCY`.

## Why Deploy Taiga on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway
will host your infrastructure so you don't have to deal with configuration,
while allowing you to vertically and horizontally scale it.

By deploying Taiga on Railway, you are one step closer to supporting a
complete full-stack application with minimal burden. Host your servers,
databases, AI agents, and more on Railway.
