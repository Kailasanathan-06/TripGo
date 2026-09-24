from decimal import Decimal

from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Offer
from .serializers import CouponValidateSerializer, OfferSerializer


class OfferListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        transport = request.query_params.get("transport_type", "")
        offers = Offer.objects.filter(active=True)
        if transport:
            offers = offers.filter(transport_types__contains=transport)
        return Response({"success": True, "data": OfferSerializer(offers, many=True).data})


class CouponValidateView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = CouponValidateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        code = serializer.validated_data["code"]
        transport = serializer.validated_data.get("transport_type", "bus")
        fare = serializer.validated_data["fare"]

        offer = Offer.objects.filter(code__iexact=code, active=True).first()
        if not offer or not offer.is_valid_today():
            return Response({"success": False, "error": "Invalid or inactive coupon code.", "data": None}, status=400)
        if transport not in (offer.transport_types or "bus,train").split(","):
            return Response({"success": False, "error": "This coupon is not valid for the selected transport.", "data": None}, status=400)

        discount = offer.discount_amount
        if offer.discount_percent:
            discount = (Decimal(fare) * offer.discount_percent / 100).quantize(Decimal("1.00"))
        return Response({"success": True, "data": {"code": offer.code, "title": offer.title, "discount": str(discount)}})