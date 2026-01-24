from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Product
from .serializers import ProductSerializer
from django.db import IntegrityError
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.response import Response
from rest_framework import status


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [IsAuthenticated]

    filter_backends = [DjangoFilterBackend]
    filterset_fields = {
        'name': ['exact'],
    }

    def create(self, request, *args, **kwargs):
        name = request.data.get('name', '').strip().title()
        category = request.data.get('category', 'General')

        if not name:
            return Response(
                {"name": "El nombre del producto es obligatorio."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            product = Product.objects.create(
                name=name,
                category=category
            )
            serializer = self.get_serializer(product)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except IntegrityError:
            product = Product.objects.get(name=name)
            serializer = self.get_serializer(product)
            return Response(serializer.data, status=status.HTTP_200_OK)
