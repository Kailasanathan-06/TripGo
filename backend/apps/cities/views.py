from django.db.models import Q
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import City, Station
from .serializers import CitySerializer, StationSerializer


class CityListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        q = request.query_params.get("q", "").strip()
        cities = City.objects.prefetch_related("stations")
        if q:
            cities = cities.filter(Q(name__icontains=q) | Q(state__icontains=q) | Q(stations__name__icontains=q)).distinct()
        return Response({"success": True, "data": CitySerializer(cities, many=True).data})


class StationListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        q = request.query_params.get("q", "").strip()
        kind = request.query_params.get("kind", "")
        stations = Station.objects.select_related("city")
        if kind:
            stations = stations.filter(Q(kind=kind) | Q(kind="both"))
        if q:
            stations = stations.filter(Q(name__icontains=q) | Q(code__icontains=q) | Q(city__name__icontains=q))
        return Response({"success": True, "data": StationSerializer(stations[:100], many=True).data})