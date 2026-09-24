from django.urls import path

from .views import MockPaymentView, PaymentDetailView, PaymentRetryView

urlpatterns = [
    path("payments/mock/", MockPaymentView.as_view(), name="payment_mock"),
    path("payments/<int:pk>/", PaymentDetailView.as_view(), name="payment_detail"),
    path("payments/<int:pk>/retry/", PaymentRetryView.as_view(), name="payment_retry"),
    path("payments/<int:pk>/cancel/", MockPaymentView.as_view(), name="payment_cancel"),
]