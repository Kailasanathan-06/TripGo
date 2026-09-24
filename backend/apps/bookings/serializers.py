from rest_framework import serializers

from apps.tickets.models import Ticket

from .models import Booking, BookingPassenger


class BookingPassengerSerializer(serializers.ModelSerializer):
    class Meta:
        model = BookingPassenger
        fields = ["id", "full_name", "age", "gender", "mobile", "email", "id_type", "id_number"]
        read_only_fields = ["id"]


class BookingCreateSerializer(serializers.Serializer):
    transport_type = serializers.ChoiceField(choices=["bus", "train"])
    schedule_id = serializers.IntegerField()
    seat_labels = serializers.ListField(child=serializers.CharField(max_length=10), min_length=1)
    coach_id = serializers.IntegerField(required=False, allow_null=True)
    passengers = BookingPassengerSerializer(many=True, min_length=1)
    offer_code = serializers.CharField(required=False, allow_blank=True, default="")


class BookingSerializer(serializers.ModelSerializer):
    passengers = BookingPassengerSerializer(many=True, read_only=True)
    seats = serializers.SerializerMethodField()
    pnr = serializers.SerializerMethodField()
    ticket_status = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            "id", "transport_type", "travel_date", "state", "source", "destination",
            "source_code", "destination_code", "boarding_point", "dropping_point",
            "departure_time", "arrival_time", "vehicle_name", "vehicle_number",
            "vehicle_type", "passenger_fare", "service_fee", "tax", "discount",
            "total_amount", "offer_code", "hold_expires_at", "created_at", "updated_at",
            "passengers", "seats", "pnr", "ticket_status",
        ]

    def get_seats(self, obj):
        return [{"label": s.label, "coach": s.coach_name, "state": s.state} for s in obj.seats.all()]

    def get_pnr(self, obj):
        ticket = Ticket.objects.filter(booking=obj).first()
        return ticket.pnr if ticket else None

    def get_ticket_status(self, obj):
        ticket = Ticket.objects.filter(booking=obj).first()
        return ticket.status if ticket else None