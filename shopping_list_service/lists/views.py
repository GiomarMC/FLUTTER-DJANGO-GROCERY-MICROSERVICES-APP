from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import ShoppingList, ShoppingListItem
from .serializers import ShoppingListSerializer, ShoppingListItemSerializer
from django_filters.rest_framework import DjangoFilterBackend


class ShoppingListViewSet(viewsets.ModelViewSet):
    """
    Vista para gestionar las listas de compras.
    """
    serializer_class = ShoppingListSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """
        Este método filtra las listas para que el usuario
        solo vea las suyas.
        """
        user = self.request.user
        user_id = getattr(user, 'id', None)
        if not user_id and hasattr(user, 'token'):
            user_id = user.token.get('user_id')
            
        return ShoppingList.objects.filter(user_id=user_id)


class ShoppingListItemViewSet(viewsets.ModelViewSet):
    """
    Vista para gestionar los items de las listas de compras.
    """
    serializer_class = ShoppingListItemSerializer
    permission_classes = [IsAuthenticated]

    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['shopping_list']
    
    def get_queryset(self):
        """
        Este método filtra los items para que el usuario
        solo vea los suyos.
        """
        user = self.request.user
        user_id = getattr(user, 'id', None)
        if not user_id and hasattr(user, 'token'):
            user_id = user.token.get('user_id')
        
        return ShoppingListItem.objects.filter(
            shopping_list__user_id=user_id
        )
    
    def perform_update(self, serializer):
        """
        Este método se encarga de actualizar un item de la lista.
        """
        item = self.get_object()
        if item.shopping_list.status == 'closed':
            raise serializers.ValidationError(
                "No se puede modificar items de una lista cerrada."
            )
        serializer.save()
    
    def perform_destroy(self, instance):
        """
        Este método se encarga de eliminar un item de la lista.
        """
        if instance.shopping_list.status == 'closed':
            raise serializers.ValidationError(
                "No se puede eliminar items de una lista cerrada."
            )
        instance.delete()