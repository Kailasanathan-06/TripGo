from decimal import Decimal

from django.db import models

from apps.accounts.models import User


class Booking(models.Model):
    STATES = [
        ("DRAFT", "Draft"),
        ("HELD", "Held"),
        ("PAYMENT_PENDING", "Payment Pending"),
        ("CONFIRMED", "Confirmed"),
        ("CANCELLED", "Cancelled"),
        ("EXPIRED", "Expired"),
    ]
    TRANSPORTS = [("bus", "Bus"), ("train", "Train")]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="bookings")
    transport_type = models.CharField(max_length=5, choices=TRANSPORTS)
    travel_date = models.DateField()
    state = models.CharField(max_length=16, choices=STATES, default="DRAFT")

    # bus or train schedule resolved via generic seat references
    bus_schedule = models.ForeignKey(
        "buses.BusSchedule", null=True, blank=True, on_delete=models.SET_NULL, related_name="bookings"
    )
    train_schedule = models.ForeignKey(
        "trains.TrainSchedule", null=True, blank=True, on_delete=models.SET_NULL, related_name="bookings"
    )
    train_coach = models.ForeignKey(
        "trains.TrainCoach", null=True, blank=True, on_delete=models.SET_NULL, related_name="bookings"
    )

    source = models.CharField(max_length=160)
    destination = models.CharField(max_length=160)
    source_code = models.CharField(max_length=20, blank=True)
    destination_code = models.CharField(max_length=20, blank=True)
    boarding_point = models.CharField(max_length=200, blank=True)
    dropping_point = models.CharField(max_length=200, blank=True)
    departure_time = models.TimeField(null=True, blank=True)
    arrival_time = models.TimeField(null=True, blank=True)

    vehicle_name = models.CharField(max_length=200, blank=True)
    vehicle_number = models.CharField(max_length=30, blank=True)
    vehicle_type = models.CharField(max_length=40, blank=True)

    passenger_fare = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    service_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    tax = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    offer_code = models.CharField(max_length=30, blank=True)

    hold_expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Booking #{self.id} ({self.transport_type})"


class BookingSeat(models.Model):
    """A seat/berth associated with a booking."""

    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name="seats")
    label = models.CharField(max_length=10)

    # Linked physical seat/berth (kept nullable so booking data is durable)
    bus_seat = models.ForeignKey(
        "buses.BusSeat", null=True, blank=True, on_delete=models.SET_NULL, related_name="booking_seats"
    )
    train_berth = models.ForeignKey(
        "trains.TrainBerth", null=True, blank=True, on_delete=models.SET_NULL, related_name="booking_seats"
    )
    coach_name = models.CharField(max_length=10, blank=True)
    state = models.CharField(max_length=12, default="HELD")

    class Meta:
        ordering = ["id"]

    def __str__(self):
        return f"{self.booking_id} · {self.label}"


class BookingPassenger(models.Model):
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name="passengers")
    full_name = models.CharField(max_length=120)
    age = models.PositiveIntegerField()
    gender = models.CharField(max_length=10, choices=[("M", "Male"), ("F", "Female"), ("O", "Other")])
    mobile = models.CharField(max_length=15, blank=True)
    email = models.EmailField(blank=True)
    id_type = models.CharField(max_length=30, blank=True)
    id_number = models.CharField(max_length=40, blank=True)

    class Meta:
        ordering = ["id"]

    def __str__(self):
        return f"{self.full_name} · {self.age}"