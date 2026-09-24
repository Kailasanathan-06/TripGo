from django.contrib import admin

from .models import Bus, BusSchedule, BusSeat

admin.site.register(Bus)
admin.site.register(BusSchedule)
admin.site.register(BusSeat)