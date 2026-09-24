from django.urls import path

from .views import (
    BookingCancelView,
    BookingCreateView,
    BookingDetailView,
    BookingHoldView,
    BookingListCreateView,
)

urlpatterns = [
    path("bookings/", BookingCreateView.as_view(), name="booking_create"),
    path("bookings/list/", BookingListCreateView.as_view(), name="booking_list"),
    path("bookings/<int:pk>/", BookingDetailView.as_view(), name="booking_detail"),
    path("bookings/<int:pk>/cancel/", BookingCancelView.as_view(), name="booking_cancel"),
    path("bookings/<int:pk>/hold/", BookingHoldView.as_view(), name="booking_hold"),
]