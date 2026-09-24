from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Bus, BusSchedule
from .serializers import BusScheduleSerializer, BusSeatSerializer, filter_schedules


class BusSearchView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        qs = filter_schedules(BusSchedule.objects.select_related("bus", "source_city", "destination_city").prefetch_related("seats"), request.query_params)
        return Response({"success": True, "data": BusScheduleSerializer(qs, many=True).data, "count": qs.count()})


class BusDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        schedule = BusSchedule.objects.select_related("bus").get(pk=pk)
        return Response({"success": True, "data": BusScheduleSerializer(schedule).data})


class BusSeatsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        schedule = BusSchedule.objects.get(pk=pk)
        seats = schedule.seats.all()
        return Response({"success": True, "data": BusSeatSerializer(seats, many=True).data})


class BusAmenitiesView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        schedule = BusSchedule.objects.select_related("bus").get(pk=pk)
        return Response({"success": True, "data": schedule.bus.amenities})


class BusPointsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        schedule = BusSchedule.objects.select_related("bus").get(pk=pk)
        return Response(
            {
                "success": True,
                "data": {
                    "boarding_points": [schedule.boarding_point],
                    "dropping_points": [schedule.dropping_point],
                },
            }
        )