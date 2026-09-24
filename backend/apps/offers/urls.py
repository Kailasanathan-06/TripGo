from django.urls import path

from .views import CouponValidateView, OfferListView

urlpatterns = [
    path("offers/", OfferListView.as_view(), name="offers"),
    path("offers/validate/", CouponValidateView.as_view(), name="offer_validate"),
]