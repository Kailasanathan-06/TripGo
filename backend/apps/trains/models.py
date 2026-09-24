from django.db import models


class Train(models.Model):
    number = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=160)
    train_type = models.CharField(max_length=30, default="Express")
    runs_on = models.CharField(max_length=30, default="1234567")
    rating = models.FloatField(default=4.2)

    class Meta:
        ordering = ["number"]

    def __str__(self):
        return f"{self.number} · {self.name}"


class TrainStation(models.Model):
    train = models.ForeignKey(Train, on_delete=models.CASCADE, related_name="route")
    station = models.ForeignKey("cities.Station", on_delete=models.CASCADE)
    order = models.PositiveIntegerField()
    distance_km = models.FloatField(default=0)
    arrival_time = models.TimeField(null=True, blank=True)
    departure_time = models.TimeField(null=True, blank=True)
    platform = models.CharField(max_length=10, blank=True)

    class Meta:
        ordering = ["order"]
        unique_together = [("train", "station")]

    def __str__(self):
        return f"{self.station.name} ({self.train.name})"


class TrainSchedule(models.Model):
    train = models.ForeignKey(Train, on_delete=models.CASCADE, related_name="schedules")
    source_station = models.ForeignKey(
        "cities.Station", on_delete=models.CASCADE, related_name="train_schedules_from"
    )
    destination_station = models.ForeignKey(
        "cities.Station", on_delete=models.CASCADE, related_name="train_schedules_to"
    )
    travel_date = models.DateField()
    duration_minutes = models.PositiveIntegerField()
    running_days = models.CharField(max_length=30, default="1234567")
    base_fare = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    distance_km = models.FloatField(default=0)

    class Meta:
        ordering = ["travel_date"]

    def __str__(self):
        return f"{self.train.name} {self.travel_date}"


TRAIN_CLASSES = [
    ("SL", "Sleeper"),
    ("3A", "AC 3 Tier"),
    ("2A", "AC 2 Tier"),
    ("1A", "AC First Class"),
    ("CC", "AC Chair Car"),
    ("2S", "Second Sitting"),
]


class TrainCoach(models.Model):
    schedule = models.ForeignKey(TrainSchedule, on_delete=models.CASCADE, related_name="coaches")
    name = models.CharField(max_length=10)  # e.g. B1, S3, A1
    coach_class = models.CharField(max_length=4, choices=TRAIN_CLASSES)
    total_berths = models.PositiveIntegerField()
    class_fare = models.DecimalField(max_digits=10, decimal_places=2)
    available = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["name"]
        unique_together = [("schedule", "name")]

    def __str__(self):
        return f"{self.schedule} · {self.name} ({self.coach_class})"


class TrainBerth(models.Model):
    BERTH_STATES = [
        ("AVAILABLE", "Available"),
        ("HELD", "Held"),
        ("BOOKED", "Booked"),
        ("UNAVAILABLE", "Unavailable"),
    ]
    coach = models.ForeignKey(TrainCoach, on_delete=models.CASCADE, related_name="berths")
    berth_number = models.CharField(max_length=6)  # e.g. 52L, 3U, 27LB
    type = models.CharField(max_length=4, choices=TRAIN_CLASSES)
    state = models.CharField(max_length=12, choices=BERTH_STATES, default="AVAILABLE")
    gender = models.CharField(max_length=10, blank=True, choices=[("M", "Male"), ("F", "Female"), ("", "General")], default="")
    booked_by = models.ForeignKey(
        "accounts.User", null=True, blank=True, on_delete=models.SET_NULL, related_name="train_berths"
    )
    hold_expires_at = models.DateTimeField(null=True, blank=True)
    locked_booking = models.ForeignKey(
        "bookings.Booking", null=True, blank=True, on_delete=models.SET_NULL, related_name="locked_train_berths"
    )

    class Meta:
        ordering = ["berth_number"]
        unique_together = [("coach", "berth_number")]

    def __str__(self):
        return f"{self.coach.name}·{self.berth_number}"