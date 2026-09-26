from django.db import connection
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView


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
