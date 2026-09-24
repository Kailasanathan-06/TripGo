from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    ForgotPasswordView,
    LoginView,
    LogoutView,
    MeView,
    OTPVerifyView,
    RegisterView,
    SavedPassengerDetailView,
    SavedPassengerListView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("me/", MeView.as_view(), name="me"),
    path("forgot-password/", ForgotPasswordView.as_view(), name="forgot_password"),
    path("verify-otp/", OTPVerifyView.as_view(), name="verify_otp"),
    path("passengers/", SavedPassengerListView.as_view(), name="saved_passengers"),
    path("passengers/<int:pk>/", SavedPassengerDetailView.as_view(), name="saved_passenger_detail"),
]