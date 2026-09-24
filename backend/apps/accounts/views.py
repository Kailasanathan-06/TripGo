import logging
import random
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import (
    ForgotPasswordSerializer,
    OTPVerifySerializer,
    RegisterSerializer,
    SavedPassengerSerializer,
    UserSerializer,
)

logger = logging.getLogger("tripgo")
User = get_user_model()


def _tokens_for(user):
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token), "user": UserSerializer(user).data}


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response({"success": True, "data": _tokens_for(user)}, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = (request.data.get("email") or "").strip().lower()
        password = request.data.get("password") or ""
        user = User.objects.filter(email__iexact=email).first()
        if user is None or not user.check_password(password):
            return Response(
                {"success": False, "error": "Invalid email or password.", "data": None},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        return Response({"success": True, "data": _tokens_for(user)})


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({"success": True, "data": UserSerializer(request.user).data})

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"success": True, "data": serializer.data})


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            token = RefreshToken(request.data.get("refresh", ""))
            token.blacklist()
        except Exception:
            pass
        return Response({"success": True, "data": None})


class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].lower()
        user = User.objects.filter(email__iexact=email).first()
        otp = f"{random.randint(100000, 999999)}"
        cache.set(f"otp:{email}", otp, timeout=600)
        logger.info("OTP for %s: %s", email, otp)
        try:
            user.email_user(
                "TripGo password reset OTP",
                f"Your TripGo OTP is {otp}. It is valid for 10 minutes.",
            )
        except Exception:
            pass
        return Response({"success": True, "data": {"message": "OTP sent to your email.", "otp": otp if settings_debug() else None}})


def settings_debug():
    from django.conf import settings

    return getattr(settings, "DEBUG", False)


class OTPVerifyView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OTPVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].lower()
        otp = str(serializer.validated_data["otp"])
        cached = cache.get(f"otp:{email}")
        user = User.objects.filter(email__iexact=email).first()
        if not cached or cached != otp:
            return Response(
                {"success": False, "error": "Invalid or expired OTP.", "data": None},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user.set_password(serializer.validated_data["new_password"])
        user.save(update_fields=["password"])
        cache.delete(f"otp:{email}")
        return Response({"success": True, "data": {"message": "Password updated. Please login."}})


class SavedPassengerListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        data = SavedPassengerSerializer(request.user.saved_passengers.all(), many=True).data
        return Response({"success": True, "data": data})

    def post(self, request):
        serializer = SavedPassengerSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"success": True, "data": serializer.data}, status=status.HTTP_201_CREATED)


class SavedPassengerDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, request, pk):
        return request.user.saved_passengers.filter(pk=pk).first()

    def delete(self, request, pk):
        obj = self.get_object(request, pk)
        if obj:
            obj.delete()
        return Response({"success": True, "data": None})