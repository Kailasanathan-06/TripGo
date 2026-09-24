from datetime import date, time

from django.db.models import Q
from rest_framework import serializers

from .models import Bus, BusSchedule, BusSeat


class BusSerializer(serializers.ModelSerializer):
    categories = serializers.SerializerMethodField()

    class Meta:
        model = Bus
        fields = ["id", "name", "operator", "bus_type", "total_seats", "rating", "amenities", "is_ac", "is_sleeper", "image_url", "categories"]

    def get_categories(self, obj):
        return obj.bus_type


class BusScheduleSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(source="pk")
    bus = BusSerializer(read_only=True)
    source_city = serializers.StringRelatedField()
    destination_city = serializers.StringRelatedField()
    source_id = serializers.SerializerMethodField()
    destination_id = serializers.SerializerMethodField()
    duration_text = serializers.SerializerMethodField()
    available_seats = serializers.SerializerMethodField()

    class Meta:
        model = BusSchedule
        fields = [
            "id", "bus", "source_city", "destination_city", "source_id", "destination_id",
            "boarding_point", "boarding_time", "dropping_point", "dropping_time",
            "duration_minutes", "duration_text", "base_fare", "discount_amount",
            "rating", "reviews_count", "available_seats",
        ]

    def get_source_id(self, obj):
        return obj.source_city_id

    def get_destination_id(self, obj):
        return obj.destination_city_id

    def get_duration_text(self, obj):
        h, m = divmod(obj.duration_minutes, 60)
        return f"{h}h {m}m" if h else f"{m}m"

    def get_available_seats(self, obj):
        from django.utils import timezone

        now = timezone.now()
        return obj.seats.filter(
            state="AVAILABLE",
        ).exclude(
            state="HELD", hold_expires_at__lt=now
        ).count() if hasattr(obj, "_seat_count") else obj.seats.filter(state="AVAILABLE").count()


class BusSeatSerializer(serializers.ModelSerializer):
    label = serializers.CharField(source="seat_number")
    status = serializers.SerializerMethodField()

    class Meta:
        model = BusSeat
        fields = ["id", "label", "row", "floor", "status", "gender"]

    def get_status(self, obj):
        from django.utils import timezone

        if obj.state == "HELD" and obj.hold_expires_at and obj.hold_expires_at <= timezone.now():
            return "AVAILABLE"
        return obj.state


def filter_schedules(qs, params):
    source = params.get("source")
    destination = params.get("destination")
    date_str = params.get("date")
    if source:
        qs = qs.filter(source_city__name__iexact=source)
    if destination:
        qs = qs.filter(destination_city__name__iexact=destination)
    if date_str:
        try:
            d = date.fromisoformat(date_str)
        except ValueError:
            d = None
        if d:
            qs = qs.filter(available_days__contains=str(d.isoweekday()))
    return qs.order_by("boarding_time")