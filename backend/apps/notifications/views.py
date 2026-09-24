from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = request.user.notifications.all()
        return Response({"success": True, "data": NotificationSerializer(notifications, many=True).data})


class NotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        request.user.notifications.filter(pk=pk).update(read=True)
        return Response({"success": True, "data": None})


class NotificationReadAllView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        request.user.notifications.update(read=True)
        return Response({"success": True, "data": None})