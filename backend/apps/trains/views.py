from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import TrainCoach, TrainSchedule
from .serializers import (
    TrainBerthSerializer,
    TrainCoachSerializer,
    TrainScheduleSerializer,
    TrainStationSerializer,
    filter_schedules,
)


class TrainSearchView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        qs = filter_schedules(
            TrainSchedule.objects.select_related("train", "source_station__city", "destination_station__city").prefetch_related("coaches"),
            request.query_params,
        )
        return Response({"success": True, "data": TrainScheduleSerializer(qs, many=True).data, "count": qs.count()})


class TrainDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        schedule = TrainSchedule.objects.select_related("train", "source_station", "destination_station").get(pk=pk)
        return Response({"success": True, "data": TrainScheduleSerializer(schedule).data})


class TrainRouteView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        schedule = TrainSchedule.objects.get(pk=pk)
        station_ids = [schedule.source_station_id, schedule.destination_station_id]
        route = schedule.train.route.filter(station_id__in=station_ids)
        route_ids = list(route.values_list("station_id", flat=True))
        all_route = schedule.train.route.all().order_by("order")
        start = all_route.filter(station_id=route_ids[0]).first().order
        end = all_route.filter(station_id=route_ids[-1]).first().order
        visible = all_route.filter(order__range=(start, end))
        return Response({"success": True, "data": TrainStationSerializer(visible, many=True).data})


class TrainCoachesView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        schedule = TrainSchedule.objects.get(pk=pk)
        return Response({"success": True, "data": TrainCoachSerializer(schedule.coaches.all(), many=True).data})


class TrainBerthsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        coach = TrainCoach.objects.get(pk=pk)
        return Response({"success": True, "data": TrainBerthSerializer(coach.berths.all(), many=True).data})