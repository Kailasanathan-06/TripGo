from rest_framework import serializers

from .models import City, Station


class StationSerializer(serializers.ModelSerializer):
    city = serializers.StringRelatedField()

    class Meta:
        model = Station
        fields = ["id", "name", "code", "city", "kind", "latitude", "longitude"]


class CitySerializer(serializers.ModelSerializer):
    stations = StationSerializer(many=True, read_only=True)

    class Meta:
        model = City
        fields = ["id", "name", "state", "latitude", "longitude", "is_popular", "stations"]