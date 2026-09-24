from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=15, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(
        max_length=10,
        blank=True,
        choices=[("M", "Male"), ("F", "Female"), ("O", "Other")],
    )
    profile_image = models.URLField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    def __str__(self):
        return self.email


class SavedPassenger(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="saved_passengers")
    full_name = models.CharField(max_length=120)
    age = models.PositiveIntegerField()
    gender = models.CharField(max_length=10, choices=[("M", "Male"), ("F", "Female"), ("O", "Other")])
    id_type = models.CharField(max_length=30, blank=True)
    id_number = models.CharField(max_length=40, blank=True)
    mobile = models.CharField(max_length=15, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.full_name} ({self.user.email})"