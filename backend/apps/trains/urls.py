from django.urls import path

from .views import (
    TrainBerthsView,
    TrainCoachesView,
    TrainDetailView,
    TrainRouteView,
    TrainSearchView,
)

urlpatterns = [
    path("trains/", TrainSearchView.as_view(), name="train_search"),
    path("trains/<int:pk>/", TrainDetailView.as_view(), name="train_detail"),
    path("trains/<int:pk>/route/", TrainRouteView.as_view(), name="train_route"),
    path("trains/<int:pk>/coaches/", TrainCoachesView.as_view(), name="train_coaches"),
    path("trains/coaches/<int:pk>/berths/", TrainBerthsView.as_view(), name="train_berths"),
]