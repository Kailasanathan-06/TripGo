from django.db import models


class Ticket(models.Model):
    STATUSES = [
        ("PENDING", "Pending"),
        ("GENERATED", "Generated"),
        ("CANCELLED", "Cancelled"),
    ]
    booking = models.OneToOneField("bookings.Booking", on_delete=models.CASCADE, related_name="ticket")
    pnr = models.CharField(max_length=12, unique=True)
    ticket_number = models.CharField(max_length=30, unique=True)
    status = models.CharField(max_length=12, choices=STATUSES, default="PENDING")
    qr_data = models.CharField(max_length=120)
    pdf_url = models.URLField(blank=True)
    payload = models.JSONField(default=dict, blank=True)
    issued_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-issued_at"]

    def __str__(self):
        return f"{self.pnr} · {self.status}"