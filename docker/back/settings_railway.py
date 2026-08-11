# Settings propios de Railway para el backend de Taiga.
#
# Hereda TODA la configuración oficial (que se lee de variables de entorno
# en settings/config.py) y solo cambia el URLconf para poder servir los
# archivos estáticos y media sobre HTTP. Así el gateway público puede
# llegar a ellos a través de la red privada de Railway sin necesidad de
# volúmenes compartidos.
from .config import *  # noqa: F401,F403

# URLconf propio: rutas de Taiga + servir /static y /media sobre HTTP
ROOT_URLCONF = "urls_railway"
