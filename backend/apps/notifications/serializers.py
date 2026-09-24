from rest_framework import serializers

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    time = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ["id", "type", "title", "message", "read", "created_at", "time"]

    def get_time(self, obj):
        from django.utils import timesince

        return timesince.timesince(obj.created_at) + " ago"