from django.db import models


class Offer(models.Model):
    code = models.CharField(max_length=30, unique=True)
    title = models.CharField(max_length=160)
    description = models.TextField(blank=True)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    discount_percent = models.PositiveIntegerField(default=0)
    min_fare = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    transport_types = models.CharField(max_length=30, blank=True, default="bus,train")
    active = models.BooleanField(default=True)
    valid_from = models.DateField(null=True, blank=True)
    valid_to = models.DateField(null=True, blank=True)
    image_url = models.URLField(blank=True)

    class Meta:
        ordering = ["-discount_amount"]

    def __str__(self):
        return f"{self.code} · {self.title}"

    def is_valid_today(self):
        from django.utils import timezone

        today = timezone.localdate()
        if self.valid_from and today < self.valid_from:
            return False
        if self.valid_to and today > self.valid_to:
            return False
        return True


class Coupon(models.Model):
    code = models.CharField(max_length=30, unique=True)
    offer = models.ForeignKey(Offer, on_delete=models.CASCADE, related_name="coupons")
    used_count = models.PositiveIntegerField(default=0)
    max_uses = models.PositiveIntegerField(default=1000)

    def __str__(self):
        return self.code