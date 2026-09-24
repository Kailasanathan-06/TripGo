from django.contrib import admin

from .models import Booking, BookingPassenger, BookingSeat

admin.site.register(Booking)
admin.site.register(BookingPassenger)
admin.site.register(BookingSeat)