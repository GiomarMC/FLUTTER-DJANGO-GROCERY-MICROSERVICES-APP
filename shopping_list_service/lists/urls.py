from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ShoppingListViewSet, ShoppingListItemViewSet

router = DefaultRouter()
router.register(r'shopping-lists', ShoppingListViewSet, basename='shopping-list')
router.register(r'items', ShoppingListItemViewSet, basename='shopping-list-item')

urlpatterns = [
    path('', include(router.urls)),
]
