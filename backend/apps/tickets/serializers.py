from rest_framework import serializers

from apps.bookings.serializers import BookingSerializer

from .models import Ticket


class TicketSerializer(serializers.ModelSerializer):
    booking = BookingSerializer(read_only=True)

    class Meta:
        model = Ticket
        fields = ["id", "pnr", "ticket_number", "status", "qr_data", "pdf_url", "payload", "issued_at", "booking"]