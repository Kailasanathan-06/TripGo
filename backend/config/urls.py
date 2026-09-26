from django.conf import settings
from django.urls import include, path
from rest_framework_simplejwt.views import TokenObtainPairView

from apps.common.views import HealthView

_api_patterns = [
    path("api/health/", HealthView.as_view(), name="health"),
    path("api/auth/", include("apps.accounts.urls")),
    path("api/", include("apps.cities.urls")),
    path("api/", include("apps.buses.urls")),
    path("api/", include("apps.trains.urls")),
    path("api/", include("apps.bookings.urls")),
    path("api/", include("apps.payments.urls")),
    path("api/", include("apps.tickets.urls")),
    path("api/", include("apps.offers.urls")),
    path("api/", include("apps.notifications.urls")),
]

urlpatterns = list(_api_patterns)

if not settings.EMBEDDED:
    # The admin site is not installed in embedded mode, so it must not be routed
    # either - importing it there would undo the start-up saving.
    from django.contrib import admin

    urlpatterns.insert(0, path("admin/", admin.site.urls))
