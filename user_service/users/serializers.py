from rest_framework import serializers


class GoogleLoginSerializer(serializers.Serializer):
    google_token = serializers.CharField(required=True)
