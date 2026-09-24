from decimal import Decimal

from django.db import models

from apps.accounts.models import User


class Payment(models.Model):
    STATUSES = [
        ("INITIATED", "Initiated"),
        ("PROCESSING", "Processing"),
        ("SUCCESS", "Success"),
        ("FAILED", "Failed"),
        ("CANCELLED", "Cancelled"),
    ]
    METHODS = [("app", "Payment App"), ("qr", "QR Payment"), ("web", "Demo Webpage")]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="payments")
    booking = models.ForeignKey("bookings.Booking", on_delete=models.CASCADE, related_name="payments")
    method = models.CharField(max_length=10, choices=METHODS, default="app")
    status = models.CharField(max_length=12, choices=STATUSES, default="INITIATED")
    reference = models.CharField(max_length=40, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    gateway_response = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.reference} · {self.status}"

    @classmethod
    def make_reference(cls, booking_id):
        import random
        import string

        suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
        return f"TGPAY{booking_id}{suffix}"