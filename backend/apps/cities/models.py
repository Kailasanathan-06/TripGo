from django.db import models


class City(models.Model):
    name = models.CharField(max_length=120, unique=True)
    state = models.CharField(max_length=120, blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    is_popular = models.BooleanField(default=False)

    class Meta:
        verbose_name_plural = "cities"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Station(models.Model):
    name = models.CharField(max_length=160)
    code = models.CharField(max_length=10, blank=True)
    city = models.ForeignKey(City, on_delete=models.CASCADE, related_name="stations")
    kind = models.CharField(
        max_length=10,
        choices=[("train", "Railway"), ("bus", "Bus stop"), ("both", "Both")],
        default="both",
    )
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.code})"