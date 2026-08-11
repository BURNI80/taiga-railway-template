# Guía del template de Taiga en Railway

Guía de mantenimiento del **template publicado** de Taiga:

- **URL del template:** https://railway.com/deploy/taiga
- **Draft/template en Railway:** código `eBE5cJ` ·
  `railway.com/workspace/templates/7b747b8a-76dc-4ebe-8ea9-f1f9a6ea9494`
- **Repositorio fuente:** https://github.com/BURNI80/taiga-railway-template
  (servicio `app` = root directory `docker/app`, rama `main`)

## Contenido del template

El template despliega 3 servicios con un clic:

| Servicio | Fuente | Variables que define |
|---|---|---|
| `app` | `BURNI80/taiga-railway-template` @ `docker/app` | 17 (ver tabla abajo) |
| `postgres` | `postgres:12.3` | `PGDATA`, `POSTGRES_USER`, `POSTGRES_DB`, `POSTGRES_PASSWORD` |
| `rabbitmq` | `rabbitmq:3.8.34-alpine` | `RABBITMQ_DEFAULT_USER`, `RABBITMQ_DEFAULT_VHOST`, `RABBITMQ_DEFAULT_PASS` |

Configuración del servicio `app` a mantener:

- **Root Directory:** `docker/app`
- **Domain (público):** target port **80** (crítico: la autodetección de
  Railway puede elegir el puerto 8000 heredado de la imagen base).
- **Volumen:** `/taiga-back/media`
- **Sleep when inactive:** `true` (requerido en el plan free).

Configuración de `postgres`:

- **PGDATA:** `/var/lib/postgresql/data/pgdata` (evita el error `initdb:
  directory exists but is not empty` por el `lost+found` del volumen).
- **Volumen:** `/var/lib/postgresql/data`

## Valores de las variables del template

> El objetivo es que el usuario final **no rellene nada**: todo está fijo,
> con referencias entre servicios y funciones `${{secret(...)}}`.

### Servicio `postgres`

| Variable | Valor | Tipo |
|---|---|---|
| `PGDATA` | `/var/lib/postgresql/data/pgdata` | fija |
| `POSTGRES_DB` | `taiga` | fija |
| `POSTGRES_USER` | `taiga` | fija |
| `POSTGRES_PASSWORD` | `${{secret(32)}}` | generada |

### Servicio `rabbitmq`

| Variable | Valor | Tipo |
|---|---|---|
| `RABBITMQ_DEFAULT_USER` | `taiga` | fija |
| `RABBITMQ_DEFAULT_VHOST` | `taiga` | fija (el entrypoint usa `:5672/taiga`) |
| `RABBITMQ_DEFAULT_PASS` | `${{secret(32)}}` | generada |

### Servicio `app`

| Variable | Valor | Tipo |
|---|---|---|
| `ADMIN_USER` | `admin` | fija |
| `ADMIN_EMAIL` | `admin@example.com` | fija |
| `ADMIN_INITIAL_PASSWORD` | `${{secret(32)}}` | generada |
| `ADMIN_BOOTSTRAP_ENABLED` | `true` | fija |
| `DJANGO_SETTINGS_MODULE` | `settings.settings_railway` | fija |
| `TAIGA_SECRET_KEY` | `${{secret(32)}}` | generada |
| `POSTGRES_HOST` | `postgres.railway.internal` | fija |
| `POSTGRES_PORT` | `5432` | fija |
| `POSTGRES_USER` | `${{ Postgres.POSTGRES_USER }}` | referencia |
| `POSTGRES_DB` | `${{ Postgres.POSTGRES_DB }}` | referencia |
| `POSTGRES_PASSWORD` | `${{ Postgres.POSTGRES_PASSWORD }}` | referencia |
| `RABBITMQ_USER` | `${{ RabbitMQ.RABBITMQ_DEFAULT_USER }}` | referencia |
| `RABBITMQ_PASS` | `${{ RabbitMQ.RABBITMQ_DEFAULT_PASS }}` | referencia |
| `TAIGA_EVENTS_RABBITMQ_HOST` | `rabbitmq.railway.internal` | fija |
| `TAIGA_ASYNC_RABBITMQ_HOST` | `rabbitmq.railway.internal` | fija |
| `GUNICORN_WORKERS` | `1` | fija (free tier) |
| `CELERY_CONCURRENCY` | `1` | fija (free tier) |

> Las referencias `${{ Postgres... }}` / `${{ RabbitMQ... }}` usan el
> **nombre del servicio** en el template. Al editarlas, usa el autocompletar
> del editor para que el namespace coincida exactamente.
>
> `ADMIN_INITIAL_PASSWORD` con `${{secret(32)}}` hace que la contraseña se
> genere en cada despliegue; el usuario final la copia de
> *Project → Variables* del servicio `app`. Si se prefiere que la ponga el
> propio usuario al desplegar, marcarla como *setup variable*.

## Cómo actualizar el template

1. **Código del `app`:** se actualiza con un push a `main` del repo
   (`docker/app`). Railway redespliega el `app` automáticamente.
2. **Variables / configuración del template:** desde
   [el editor del template](https://railway.com/workspace/templates/7b747b8a-76dc-4ebe-8ea9-f1f9a6ea9494),
   o con el CLI:
   ```bash
   railway templates publish eBE5cJ \
     --category "Starters" \
     --description "Taiga project management (Scrum/Kanban) on Railway" \
     --readme-file docs/template-overview.md
   ```
   *Nota: según AGENTS.md no publicamos con el CLI salvo que se indique.*

## Crear el template desde cero (por si hace falta regenerarlo)

El template se generó a partir del proyecto desplegado con:

```bash
railway templates create --project taiga --environment production
```

Requisito: los servicios deben tener **fuente** (repo de GitHub o imagen).
El servicio `app` se desplegó primero por directorio local y eso impedía
generar el template; se conectó al repo (`BURNI80/taiga-railway-template`,
root `docker/app`) para poder generarlo.

Tras regenerar, revisar en el editor:
- [ ] Puertos objetivo de los dominios a **80**.
- [ ] Secrets con `${{secret(32)}}` y referencias entre servicios.
- [ ] Volúmenes montados en los 3 servicios.
- [ ] `PGDATA` en `postgres`.
- [ ] `Sleep when inactive: true` en todos (free plan).

## Checklist de publicación

- [x] Template creado como draft (id `7b747b8a-76dc-4ebe-8ea9-f1f9a6ea9494`).
- [x] Variables con secrets generados y referencias entre servicios.
- [x] Publicado: https://railway.com/deploy/taiga
- [ ] Tras desplegar desde el template, el primer arranque crea el admin
      (`admin` + `ADMIN_INITIAL_PASSWORD` de Variables).
- [ ] Los websockets funcionan (crear un proyecto y observar el timeline).
