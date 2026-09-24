import logging
from datetime import time
from decimal import Decimal

from django.db import transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.buses.models import BusSchedule
from apps.offers.models import Offer
from apps.trains.models import TrainCoach, TrainSchedule

from .models import Booking
from .serializers import BookingCreateSerializer, BookingSerializer
from .services import cancel_booking, compute_fare, hold_seats

logger = logging.getLogger("tripgo")

SERVICE_FEE = {"bus": Decimal("50"), "train": Decimal("40")}


class BookingCreateView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        serializer = BookingCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        transport = data["transport_type"]
        schedule_id = data["schedule_id"]
        seat_labels = data["seat_labels"]
        coach_id = data.get("coach_id")

        booking = Booking(user=request.user, transport_type=transport)
        vehicle_fare = Decimal("0")

        if transport == "bus":
            schedule = BusSchedule.objects.select_related("bus", "source_city", "destination_city").get(pk=schedule_id)
            booking.bus_schedule = schedule
            booking.travel_date = _parse_date(data)
            booking.source = schedule.source_city.name
            booking.destination = schedule.destination_city.name
            booking.boarding_point = schedule.boarding_point
            booking.dropping_point = schedule.dropping_point
            booking.departure_time = schedule.boarding_time
            booking.arrival_time = schedule.dropping_time
            booking.vehicle_name = schedule.bus.name
            booking.vehicle_number = schedule.bus.bus_type
            booking.vehicle_type = schedule.bus.bus_type
            vehicle_fare = schedule.base_fare
        else:
            schedule = TrainSchedule.objects.select_related("train", "source_station", "destination_station").get(pk=schedule_id)
            coach = TrainCoach.objects.select_related("schedule").get(pk=coach_id, schedule=schedule) if coach_id else None
            if coach is None:
                return Response({"success": False, "error": "A valid coach is required.", "data": None}, status=status.HTTP_400_BAD_REQUEST)
            booking.train_schedule = schedule
            booking.train_coach = coach
            booking.travel_date = schedule.travel_date
            booking.source = schedule.source_station.name
            booking.destination = schedule.destination_station.name
            booking.source_code = schedule.source_station.code
            booking.destination_code = schedule.destination_station.code
            booking.boarding_point = schedule.source_station.name
            booking.dropping_point = schedule.destination_station.name
            booking.departure_time = _route_time(schedule, schedule.source_station, depart=True)
            booking.arrival_time = _route_time(schedule, schedule.destination_station, depart=False)
            booking.vehicle_name = schedule.train.name
            booking.vehicle_number = schedule.train.number
            booking.vehicle_type = schedule.train.train_type
            vehicle_fare = coach.class_fare

        discount = Decimal("0")
        offer_code = data.get("offer_code") or ""
        if offer_code:
            offer = Offer.objects.filter(code__iexact=offer_code, active=True).first()
            if offer and offer.is_valid_today():
                discount = offer.discount_amount

        fare = compute_fare(vehicle_fare, len(data["passengers"]), SERVICE_FEE[transport], discount)
        booking.passenger_fare = fare["passenger_fare"]
        booking.service_fee = fare["service_fee"]
        booking.tax = fare["tax"]
        booking.discount = fare["discount"]
        booking.total_amount = fare["total_amount"]
        booking.offer_code = offer_code
        booking.save()

        for p in data["passengers"]:
            booking.passengers.create(**p)

        try:
            hold_seats(booking, seat_labels, coach_name=coach.name if coach_id else "")
        except Exception as exc:
            booking.state = "CANCELLED"
            booking.save(update_fields=["state"])
            return Response({"success": False, "error": str(exc), "data": None}, status=status.HTTP_409_CONFLICT)

        logger.info("Booking %s created and seats held for user %s", booking.id, request.user.email)
        return Response({"success": True, "data": BookingSerializer(booking).data}, status=status.HTTP_201_CREATED)


def _parse_date(data):
    from datetime import date as _date

    try:
        return _date.fromisoformat(str(data.get("travel_date", "")))
    except Exception:
        return timezone.localdate()


def _route_time(schedule, station, depart):
    entry = schedule.train.route.filter(station=station).first()
    if not entry:
        return time(0, 0)
    return entry.departure_time if depart else entry.arrival_time


class BookingListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        bookings = request.user.bookings.prefetch_related("passengers", "seats")
        status_filter = request.query_params.get("state", "")
        if status_filter:
            bookings = bookings.filter(state=status_filter)
        return Response({"success": True, "data": BookingSerializer(bookings, many=True).data})


class BookingDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, request, pk):
        return request.user.bookings.prefetch_related("passengers", "seats").filter(pk=pk).first()

    def get(self, request, pk):
        booking = self.get_object(request, pk)
        if not booking:
            return Response({"success": False, "error": "Booking not found.", "data": None}, status=status.HTTP_404_NOT_FOUND)
        return Response({"success": True, "data": BookingSerializer(booking).data})


class BookingCancelView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        booking = request.user.bookings.filter(pk=pk).first()
        if not booking:
            return Response({"success": False, "error": "Booking not found.", "data": None}, status=status.HTTP_404_NOT_FOUND)
        if booking.state in ("CONFIRMED", "HELD", "PAYMENT_PENDING"):
            cancel_booking(booking)
            logger.info("Booking %s cancelled", booking.id)
            return Response({"success": True, "data": BookingSerializer(booking).data})
        return Response({"success": False, "error": f"Cannot cancel booking in state {booking.state}.", "data": None}, status=status.HTTP_400_BAD_REQUEST)


class BookingHoldView(APIView):
    """Re-hold seats for a booking that was created but whose hold lapsed/failed."""

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        booking = request.user.bookings.filter(pk=pk).first()
        if not booking:
            return Response({"success": False, "error": "Booking not found.", "data": None}, status=status.HTTP_404_NOT_FOUND)
        if booking.state in ("PAYMENT_PENDING", "HELD", "EXPIRED"):
            booking.seats.all().delete()
            try:
                hold_seats(booking, [s.label for s in request.data.get("seats", [])])
            except Exception as exc:
                return Response({"success": False, "error": str(exc), "data": None}, status=status.HTTP_409_CONFLICT)
            return Response({"success": True, "data": BookingSerializer(booking).data})
        return Response({"success": False, "error": f"Cannot hold booking in state {booking.state}.", "data": None}, status=status.HTTP_400_BAD_REQUEST)