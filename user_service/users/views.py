from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from .serializers import GoogleLoginSerializer
import uuid
import os
from dotenv import load_dotenv

load_dotenv()

User = get_user_model()
GOOGLE_CLIENT_ID = os.getenv('GOOGLE_CLIENT_ID')

class GoogleLoginView(APIView):
    def post(self, request):
        serializer = GoogleLoginSerializer(data=request.data)
        if serializer.is_valid():
            token = serializer.validated_data['google_token']

            try:
                idinfo = id_token.verify_oauth2_token(
                    token,
                    google_requests.Request(),
                    GOOGLE_CLIENT_ID
                )
                email = idinfo['email']
                first_name = idinfo.get('given_name', '')
                last_name = idinfo.get('family_name', '')

                user, created = User.objects.get_or_create(
                    email=email,
                    defaults={
                        'username': email,
                        'first_name': first_name,
                        'last_name': last_name,
                    }
                )

                if created:
                    user.set_unusable_password()
                    user.save()

                refresh = RefreshToken.for_user(user)
                
                return Response({
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                    'user': {
                        'id': user.id,
                        'email': user.email,
                        'name': user.first_name
                    }
                }, status=status.HTTP_200_OK)

            except ValueError:
                return Response({
                    'error': 'Token de Google invalido'},
                    status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
