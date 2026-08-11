#!/usr/bin/env python3
# Crea el primer administrador (superuser) de Taiga en el primer arranque.
#
# Idempotente: si ya existe un superuser, no hace nada. Los datos se leen
# de variables de entorno para que el usuario final no tenga que ejecutar
# comandos manualmente tras desplegar la plantilla.
import os
import sys

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "settings.settings_railway")
django.setup()

from django.conf import settings  # noqa: E402
from django.contrib.auth import get_user_model  # noqa: E402


def main() -> int:
    if os.getenv("ADMIN_BOOTSTRAP_ENABLED", "true").lower() not in ("true", "1", "yes"):
        print("[railway] Admin bootstrap deshabilitado, omitiendo.", flush=True)
        return 0

    username = os.getenv("ADMIN_USER", "admin").strip()
    email = os.getenv("ADMIN_EMAIL", "admin@example.com").strip()
    password = os.getenv("ADMIN_INITIAL_PASSWORD", "").strip()

    if not password:
        print("[railway] ADMIN_INITIAL_PASSWORD no definida, omitiendo admin.", flush=True)
        return 0

    User = get_user_model()

    if User.objects.filter(is_superuser=True).exists():
        print("[railway] Ya existe un superuser, omitiendo.", flush=True)
        return 0

    # Desactivamos Celery mientras se crea el admin: el signal de timeline
    # intentaría publicar en RabbitMQ y fallaría si aún no está disponible
    # (p. ej. en el primer arranque).
    settings.CELERY_ENABLED = False

    User.objects.create_superuser(username, email, password)
    print(f"[railway] Superuser '{username}' creado correctamente.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
