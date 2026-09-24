from django.urls import path

from .views import (
    BusAmenitiesView,
    BusDetailView,
    BusPointsView,
    BusSearchView,
    BusSeatsView,
)

urlpatterns = [
    path("buses/", BusSearchView.as_view(), name="bus_search"),
    path("buses/<int:pk>/", BusDetailView.as_view(), name="bus_detail"),
    path("buses/<int:pk>/seats/", BusSeatsView.as_view(), name="bus_seats"),
    path("buses/<int:pk>/amenities/", BusAmenitiesView.as_view(), name="bus_amenities"),
    path("buses/<int:pk>/boarding-points/", BusPointsView.as_view(), name="bus_boarding"),
    path("buses/<int:pk>/dropping-points/", BusPointsView.as_view(), name="bus_dropping"),
]