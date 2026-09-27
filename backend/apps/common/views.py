from django.db import connection
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView


class ApiIndexView(APIView):
    """Pointer for anyone who opens the server root in a browser.

    The API is mounted under ``/api/`` and has no page at ``/``, so hitting the root
    used to produce a bare 404 that looked like a broken server. It is reachable
    without a token on purpose: it is the quickest way to confirm the backend is up.
    """

    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        host = request.get_host()
        return Response(
            {
                "success": True,
                "error": None,
                "data": {
                    "service": "TripGo API",
                    "status": "running",
                    "health": f"http://{host}/api/health/",
                    "endpoints": [
                        "POST /api/auth/login/",
                        "GET  /api/cities/",
                        "GET  /api/buses/",
                        "GET  /api/trains/",
                        "GET  /api/offers/",
                    ],
                    "note": (
                        "This is an API, not a web page. The TripGo app connects to it "
                        "automatically, so there is nothing to open here."
                    ),
                },
            }
        )


class HealthView(APIView):
    """Unauthenticated liveness probe.

    The Android client polls this before it hands control to the app, so it must
    stay dependency-free and must never require a token.
    """

    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
            database = "ok"
        except Exception as exc:  # pragma: no cover - only on a broken install
            database = f"error: {exc}"
        return Response(
            {
                "success": database == "ok",
                "error": None if database == "ok" else database,
                "data": {"status": "ok" if database == "ok" else "degraded", "database": database},
            }
        )
