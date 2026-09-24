import logging
from decimal import Decimal

from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.bookings.models import Booking
from apps.bookings.serializers import BookingSerializer
from apps.bookings.services import cancel_booking, confirm_booking

from .models import Payment

logger = logging.getLogger("tripgo")


class MockPaymentView(APIView):
    """
    DEMO / MOCK PAYMENT ONLY. No real money is transferred.
    Deterministic demo behavior driven by `action`:
      start  -> INITIATED/PROCESSING
      success-> SUCCESS (confirms booking, generates PNR + ticket)
      failure-> FAILED  (no PNR, no ticket, seat released)
      cancel -> CANCELLED (no PNR, no ticket, seat released)
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        booking = request.user.bookings.filter(pk=request.data.get("booking_id")).first()
        if not booking:
            return Response({"success": False, "error": "Booking not found.", "data": None}, status=status.HTTP_404_NOT_FOUND)

        action = request.data.get("action", "start")
        method = request.data.get("method", "app")
        amount = Decimal(request.data.get("amount", booking.total_amount))

        reference = Payment.make_reference(booking.id)
        payment = Payment.objects.create(
            user=request.user,
            booking=booking,
            method=method,
            status="INITIATED",
            reference=reference,
            amount=amount,
        )

        if action == "start":
            payment.status = "PROCESSING"
            payment.save(update_fields=["status", "updated_at"])
            return Response({"success": True, "data": self._payload(payment, "PROCESSING")})

        if action == "success":
            return self._finalize(request, payment, booking, "SUCCESS")

        if action == "failure":
            return self._finalize(request, payment, booking, "FAILED", fail_message="Payment failed. No PNR or ticket was generated.")

        if action == "cancel":
            return self._finalize(request, payment, booking, "CANCELLED", fail_message="Payment cancelled. No money was charged.")

        return Response({"success": False, "error": "Unknown payment action.", "data": None}, status=status.HTTP_400_BAD_REQUEST)

    def _finalize(self, request, payment, booking, result, fail_message=""):
        if result == "SUCCESS":
            with transaction.atomic():
                if booking.state == "CONFIRMED":
                    payment.booking = booking
                payment.status = "SUCCESS"
                payment.save(update_fields=["status", "updated_at"])
                try:
                    ticket = confirm_booking(booking)
                except Exception as exc:  # pragma: no cover
                    logger.exception("Confirmation failed")
                    return Response({"success": False, "error": str(exc), "data": None}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            logger.info("Payment %s SUCCESS; booking %s confirmed", payment.reference, booking.id)
            return Response({"success": True, "data": self._payload(payment, "SUCCESS", BookingSerializer(booking).data)})
        else:
            # release seats, never create PNR/ticket, booking stays retryable
            with transaction.atomic():
                from apps.bookings.services import release_expired_holds as _rel

                payment.status = result
                payment.gateway_response = {"message": fail_message}
                payment.save(update_fields=["status", "gateway_response", "updated_at"])
                if booking.state == "HELD":
                    cancel_booking(booking, reason="Payment " + result.lower())
                elif booking.state == "CONFIRMED":
                    pass
            message = fail_message or ("Payment " + result.lower())
            return Response({"success": False, "error": message, "data": self._payload(payment, result)})

    def _payload(self, payment, status_text, booking_data=None):
        return {
            "payment": {
                "id": payment.id,
                "reference": payment.reference,
                "method": payment.method,
                "status": status_text,
                "amount": str(payment.amount),
                "created_at": payment.created_at.isoformat(),
            },
            "booking": booking_data,
        }


class PaymentDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        payment = request.user.payments.filter(pk=pk).first()
        if not payment:
            return Response({"success": False, "error": "Payment not found.", "data": None}, status=status.HTTP_404_NOT_FOUND)
        return Response(
            {
                "success": True,
                "data": {
                    "id": payment.id,
                    "reference": payment.reference,
                    "method": payment.method,
                    "status": payment.status,
                    "amount": str(payment.amount),
                    "booking": BookingSerializer(payment.booking).data,
                },
            }
        )


class PaymentRetryView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        payment = request.user.payments.filter(pk=pk).first()
        if not payment:
            return Response({"success": False, "error": "Payment not found.", "data": None}, status=status.HTTP_404_NOT_FOUND)
        booking = payment.booking
        # prevent retry after confirmation
        if booking.state == "CONFIRMED":
            return Response({"success": False, "error": "Booking is already confirmed.", "data": None}, status=status.HTTP_400_BAD_REQUEST)
        return Response({"success": True, "data": {"message": "Ready for retry.", "booking_id": booking.id}})