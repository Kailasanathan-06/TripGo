from django.db import models

from apps.accounts.models import User


class Notification(models.Model):
    TYPES = [
        ("BOOKING_CONFIRMED", "Booking Confirmed"),
        ("PAYMENT", "Payment"),
        ("TICKET", "Ticket"),
        ("REMINDER", "Reminder"),
        ("CANCELLATION", "Cancellation"),
        ("OFFER", "Offer"),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="notifications")
    type = models.CharField(max_length=25, choices=TYPES)
    title = models.CharField(max_length=160)
    message = models.TextField()
    read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    related_booking = models.ForeignKey(
        "bookings.Booking", null=True, blank=True, on_delete=models.SET_NULL
    )

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} · {self.title}"