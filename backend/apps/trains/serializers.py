from datetime import date

from rest_framework import serializers

from .models import Train, TrainBerth, TrainCoach, TrainSchedule, TrainStation


class TrainSerializer(serializers.ModelSerializer):
    class Meta:
        model = Train
        fields = ["id", "number", "name", "train_type", "runs_on", "rating"]


class TrainStationSerializer(serializers.ModelSerializer):
    station_name = serializers.CharField(source="station.name")
    station_code = serializers.CharField(source="station.code")

    class Meta:
        model = TrainStation
        fields = ["order", "station_name", "station_code", "arrival_time", "departure_time", "platform", "distance_km"]


class TrainScheduleSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(source="pk")
    train = TrainSerializer(read_only=True)
    source_station_name = serializers.CharField(source="source_station.name")
    source_station_code = serializers.CharField(source="source_station.code")
    destination_station_name = serializers.CharField(source="destination_station.name")
    destination_station_code = serializers.CharField(source="destination_station.code")
    duration_text = serializers.SerializerMethodField()
    coaches = serializers.SerializerMethodField()
    total_available = serializers.SerializerMethodField()

    class Meta:
        model = TrainSchedule
        fields = [
            "id", "train", "source_station_name", "source_station_code",
            "destination_station_name", "destination_station_code",
            "travel_date", "duration_minutes", "duration_text",
            "distance_km", "base_fare", "coaches", "total_available",
        ]

    def get_duration_text(self, obj):
        h, m = divmod(obj.duration_minutes, 60)
        return f"{h}h {m}m" if h else f"{m}m"

    def get_coaches(self, obj):
        return [{k: c[k] for k in ("id", "name", "coach_class", "class_fare", "available")} for c in obj.coaches.values("id", "name", "coach_class", "class_fare", "available")]

    def get_total_available(self, obj):
        return sum(c["available"] for c in obj.coaches.values("available"))


class TrainCoachSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrainCoach
        fields = ["id", "name", "coach_class", "total_berths", "class_fare", "available"]


class TrainBerthSerializer(serializers.ModelSerializer):
    label = serializers.CharField(source="berth_number")
    status = serializers.SerializerMethodField()

    class Meta:
        model = TrainBerth
        fields = ["id", "label", "type", "coach", "status", "gender"]

    def get_status(self, obj):
        from django.utils import timezone

        if obj.state == "HELD" and obj.hold_expires_at and obj.hold_expires_at <= timezone.now():
            return "AVAILABLE"
        return obj.state


def filter_schedules(qs, params):
    source = params.get("source")
    destination = params.get("destination")
    if source:
        qs = qs.filter(source_station__city__name__iexact=source)
    if destination:
        qs = qs.filter(destination_station__city__name__iexact=destination)
    date_str = params.get("date")
    if date_str:
        try:
            d = date.fromisoformat(date_str)
            qs = qs.filter(travel_date=d)
        except ValueError:
            pass
    return qs