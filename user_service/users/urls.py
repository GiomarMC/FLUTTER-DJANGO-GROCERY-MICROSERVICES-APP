from django.urls import path
from .views import GoogleLoginView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('auth/google/', GoogleLoginView.as_view(), name='google_login'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
