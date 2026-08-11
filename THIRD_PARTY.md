# Terceras partes (licencias de software que reutiliza esta plantilla)

Esta plantilla **no copia ni redistribuye** código de Taiga: los
`Dockerfile` usan las imágenes oficiales publicadas por el proyecto Taiga
y solo añaden configuración propia. Las licencias de dichos proyectos
aplican a las imágenes desplegadas:

| Proyecto | Imagen usada | Licencia |
|---|---|---|
| [taigaio/taiga-back](https://github.com/taigaio/taiga-back) | `taigaio/taiga-back:6.10.2` | [MPL-2.0](https://www.mozilla.org/en-US/MPL/2.0/) |
| [taigaio/taiga-front](https://github.com/taigaio/taiga-front) | `taigaio/taiga-front:6.10.3` | [AGPL-3.0](https://www.gnu.org/licenses/agpl-3.0.html) |
| [taigaio/taiga-events](https://github.com/taigaio/taiga-events) | `taigaio/taiga-events:6.10.0` | MPL-2.0 |
| [RabbitMQ](https://www.rabbitmq.com/) | `rabbitmq:3.8.34-alpine` | MPL-2.0 |
| [PostgreSQL](https://www.postgresql.org/) | `postgres:12.3` | PostgreSQL License |
| [nginx](https://nginx.org/) | instalado en el contenedor `app` (paquete de Debian) | BSD 2-Clause |
| [supervisord](http://supervisord.org/) | instalado en el contenedor `app` (paquete de Debian) | BSD 3-Clause |

El código incluido en este repositorio (Dockerfiles, scripts, settings y
documentación) es de nuestra autoría y se distribuye bajo la licencia MIT
(ver `LICENSE`).

Consulta el [README del proyecto Taiga](https://github.com/taigaio/taiga-back)
para los detalles de licencia y atribución de Taiga.
