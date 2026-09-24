from django.db import models


class Bus(models.Model):
    BUS_TYPES = [
        ("AC_SLEEPER", "AC Sleeper"),
        ("NON_AC_SLEEPER", "Non AC Sleeper"),
        ("AC_SEATER", "AC Seater"),
        ("NON_AC_SEATER", "Non AC Seater"),
        ("AC_DLX", "AC Deluxe"),
    ]
    name = models.CharField(max_length=160)
    operator = models.CharField(max_length=120)
    bus_type = models.CharField(max_length=30, choices=BUS_TYPES, default="AC_SLEEPER")
    total_seats = models.PositiveIntegerField(default=40)
    rating = models.FloatField(default=4.0)
    amenities = models.JSONField(default=list, blank=True)
    is_ac = models.BooleanField(default=True)
    is_sleeper = models.BooleanField(default=True)
    image_url = models.URLField(blank=True)

    class Meta:
        verbose_name_plural = "buses"
        ordering = ["operator", "name"]

    def __str__(self):
        return self.name


class BusSchedule(models.Model):
    bus = models.ForeignKey(Bus, on_delete=models.CASCADE, related_name="schedules")
    source_city = models.ForeignKey(
        "cities.City", on_delete=models.CASCADE, related_name="bus_schedules_from"
    )
    destination_city = models.ForeignKey(
        "cities.City", on_delete=models.CASCADE, related_name="bus_schedules_to"
    )
    boarding_point = models.CharField(max_length=200)
    boarding_time = models.TimeField()
    dropping_point = models.CharField(max_length=200)
    dropping_time = models.TimeField()
    duration_minutes = models.PositiveIntegerField()
    base_fare = models.DecimalField(max_digits=10, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    available_days = models.CharField(max_length=30, default="1234567")
    rating = models.FloatField(default=4.0)
    reviews_count = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["boarding_time"]

    def __str__(self):
        return f"{self.bus.name}: {self.source_city.name} → {self.destination_city.name}"


class BusSeat(models.Model):
    SEAT_STATES = [
        ("AVAILABLE", "Available"),
        ("HELD", "Held"),
        ("BOOKED", "Booked"),
        ("UNAVAILABLE", "Unavailable"),
    ]
    schedule = models.ForeignKey(BusSchedule, on_delete=models.CASCADE, related_name="seats")
    seat_number = models.CharField(max_length=10)
    row = models.PositiveIntegerField()
    floor = models.PositiveIntegerField(default=1)  # upper/lower deck of sleeper
    state = models.CharField(max_length=12, choices=SEAT_STATES, default="AVAILABLE")
    gender = models.CharField(max_length=10, blank=True, choices=[("M", "Male"), ("F", "Female"), ("", "General")], default="")
    booked_by = models.ForeignKey(
        "accounts.User", null=True, blank=True, on_delete=models.SET_NULL, related_name="bus_seats"
    )
    hold_expires_at = models.DateTimeField(null=True, blank=True)
    locked_booking = models.ForeignKey(
        "bookings.Booking", null=True, blank=True, on_delete=models.SET_NULL, related_name="locked_bus_seats"
    )

    class Meta:
        ordering = ["row", "seat_number"]
        unique_together = [("schedule", "seat_number")]

    def __str__(self):
        return f"{self.schedule} · {self.seat_number}"