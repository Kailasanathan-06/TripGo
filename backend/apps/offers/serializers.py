from rest_framework import serializers

from .models import Offer


class OfferSerializer(serializers.ModelSerializer):
    class Meta:
        model = Offer
        fields = ["id", "code", "title", "description", "discount_amount", "discount_percent", "min_fare", "transport_types", "active", "valid_from", "valid_to", "image_url"]


class CouponValidateSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=30)
    transport_type = serializers.CharField(required=False, default="bus")
    fare = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)