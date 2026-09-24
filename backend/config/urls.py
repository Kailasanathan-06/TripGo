from django.contrib import admin
from django.urls import include, path
from rest_framework_simplejwt.views import TokenObtainPairView

urlpatterns = [
    path("admin/", admin.site.urls),
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