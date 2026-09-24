from django.urls import path

from .views import CityListView, StationListView

urlpatterns = [
    path("cities/", CityListView.as_view(), name="cities"),
    path("stations/", StationListView.as_view(), name="stations"),
]