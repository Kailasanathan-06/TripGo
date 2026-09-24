from django.contrib import admin

from .models import Train, TrainBerth, TrainCoach, TrainSchedule, TrainStation

admin.site.register(Train)
admin.site.register(TrainStation)
admin.site.register(TrainSchedule)
admin.site.register(TrainCoach)
admin.site.register(TrainBerth)