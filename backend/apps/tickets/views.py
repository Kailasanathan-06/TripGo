from django.http import JsonResponse
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Ticket
from .serializers import TicketSerializer


class TicketDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        ticket = Ticket.objects.select_related("booking").filter(pk=pk).first()
        if not ticket:
            return Response({"success": False, "error": "Ticket not found.", "data": None}, status=404)
        if ticket.booking.user_id != request.user.id:
            return Response({"success": False, "error": "Not allowed.", "data": None}, status=403)
        return Response({"success": True, "data": TicketSerializer(ticket).data})


class TicketPdfView(APIView):
    """Returns ticket payload; the mobile app renders the real PDF locally."""

    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        ticket = Ticket.objects.select_related("booking").filter(pk=pk).first()
        if not ticket:
            return JsonResponse({"success": False, "error": "Ticket not found."}, status=404)
        if ticket.booking.user_id != request.user.id:
            return JsonResponse({"success": False, "error": "Not allowed."}, status=403)
        return Response({"success": True, "data": ticket.payload})


class PNRLookupView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pnr):
        ticket = (
            Ticket.objects.select_related("booking__user", "booking")
            .filter(pnr__iexact=pnr)
            .first()
        )
        if not ticket:
            return Response(
                {"success": False, "error": "Invalid PNR. No booking was found.", "data": None},
                status=404,
            )
        return Response({"success": True, "data": TicketSerializer(ticket).data})