# URLconf propio de Railway para el backend de Taiga.
#
# Incluye todas las rutas de Taiga (api, admin, auth, ...) y añade las
# rutas /static/ y /media/ servidas por Django. Necesario porque Railway
# no permite compartir un volumen entre varios servicios: el gateway
# público accede a los estáticos/media a través de la red privada.
from django.conf import settings
from django.urls import include, path
from django.views.static import serve

urlpatterns = [
    path("", include("taiga.urls")),
]

# Sirve los archivos estáticos y media sobre HTTP.
# Solo se activa en producción (DEBUG=False): en desarrollo Taiga ya
# incluye estas rutas automáticamente.
if not settings.DEBUG:
    urlpatterns += [
        path("static/<path:path>", serve, {"document_root": settings.STATIC_ROOT}, name="railway-static"),
        path("media/<path:path>", serve, {"document_root": settings.MEDIA_ROOT}, name="railway-media"),
    ]
