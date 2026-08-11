# Guía para publicar la plantilla en Railway

Esta guía explica cómo convertir el proyecto desplegado en un **template**
reutilizable del Marketplace de Railway, y qué se publica en cada campo.

## Antes de publicar

1. Verifica que el despliegue completo funciona (ver `deploy-railway.md`).
2. Decide qué variables deben preguntarse al usuario final (tipo `secret`)
   y cuáles quedan fijas. Para que la plantilla sea "user friendly":
   - Fijas: todo lo que no dependa del usuario (`TAIGA_SECRET_KEY` se puede
     generar como secret, `POSTGRES_*`, `ADMIN_USER`, etc.).
   - A preguntar: idealmente solo los *secrets* (`ADMIN_INITIAL_PASSWORD`,
     `POSTGRES_PASSWORD`, `TAIGA_SECRET_KEY`).

## Pasos en Railway

1. Con el proyecto desplegado y verificado, entra en **Settings** del
   proyecto → **Share Project** → **Publish as Template**.
2. Rellena los campos de la plantilla:
   - **Name**: `Taiga`.
   - **Description**: una o dos frases cortas (ver sugerencia abajo).
   - **Category**: *Project Management* (o la más parecida).
   - **Icon**: el logotipo de Taiga.
3. Marca como **Variables de configuración** (setup variables) aquellas
   que el usuario debe rellenar; marca el resto como secret si contienen
   contraseñas.
4. Publica.

> Alternativa: en vez de publicar desde la UI, se puede usar el comando
> `railway template` del CLI. *Nota: según AGENTS.md no usamos el CLI de
> Railway para publicar hasta que se indique.*

## Texto sugerido para la plantilla

**Name:** Taiga

**Short description:** Taiga, project management tool (Scrum, Kanban), running on Railway with PostgreSQL and RabbitMQ.

**Description (markdown):**

```markdown
# Taiga on Railway

Deploy [Taiga](https://www.taiga.io/), the open source project
management tool (Scrum + Kanban), on Railway.

**What's included**

- Public gateway (nginx) serving the Taiga web app
- Taiga backend API (Django/gunicorn)
- Real-time events service (WebSockets)
- RabbitMQ message broker
- PostgreSQL database

**Configuration**

You only need to fill in the *secret* variables:

- `ADMIN_INITIAL_PASSWORD`: initial password for the first admin user
  (default username: `admin`).

Everything else is pre-configured. After deploying, open the gateway URL
and log in with the admin user. Change the password after first login.

**Notes**

- This template fits in the Railway free tier.
- Do not rename the services: the gateway uses the private hostnames
  `taiga-back.railway.internal` and `taiga-events.railway.internal`.

**License**

The Taiga images are released under MPL-2.0 (backend/events) and AGPL-3.0
(front). This template configuration is MIT licensed. See `THIRD_PARTY.md`.
```

## Checklist post-publicación

- [ ] El template aparece en el Marketplace con la categoría correcta.
- [ ] Al desplegarlo, solo pide los *secrets* mínimos.
- [ ] El primer arranque crea el admin automáticamente.
- [ ] Los websockets funcionan (crea un proyecto y observa el timeline).
