from rest_framework import serializers
from .models import ShoppingList, ShoppingListItem
from django.utils import timezone
import requests
from dotenv import load_dotenv
import os

load_dotenv()

PRODUCT_SERVICE_URL = os.getenv("PRODUCT_SERVICE_URL")

class ShoppingListSerializer(serializers.ModelSerializer):
    """
    Serializador para las listas de compras.
    """
    class Meta:
        model = ShoppingList
        fields = ['id', 'date_of_purchase', 'status', 'total_spent', 'created_at']
        read_only_fields = ['created_at']

    def create(self, validated_data):
        """
        Crea una lista de compras y le asigna el usuario propietario.
        """
        user = self.context['request'].user
        user_id = getattr(user, 'id', None)
        if not user_id and hasattr(user, 'token'):
             user_id = user.token.get('user_id')
        
        if not user_id:
            raise serializers.ValidationError("No se pudo identificar al usuario propietario de la lista.")

        validated_data['user_id'] = user_id
        
        return super().create(validated_data)

    def validate(self, data):
        """
        Valida que el total gastado sea ingresado
        cuando se cierra la lista.
        """
        if self.instance:
            current_status = self.instance.status
            current_total = self.instance.total_spent

            if current_status == 'closed':
                if 'status' in data and data['status'] != 'closed':
                    raise serializers.ValidationError(
                        "Una lista cerrada no puede reabrirse."
                    )
                if 'date_of_purchase' in data:
                    raise serializers.ValidationError(
                        "Una lista cerrada no puede modificar su fecha de compra."
                    )
        else:
            current_status = 'open'
            current_total = None

        new_status = data.get('status', current_status)
        new_total = data.get('total_spent', current_total)

        if new_status == 'closed' and new_total is None:
            raise serializers.ValidationError(
                "Para cerrar la lista, es obligatorio ingresar el monto total gastado."
            )
        
        return data
    
    def validate_date_of_purchase(self, value):
        """
        Valida que la fecha de compra sea una fecha valida.
        """
        today = timezone.now().date()
        if value < today:
            raise serializers.ValidationError(
                "La fecha de compra no puede anterior a la fecha actual."
            )
        return value


class ShoppingListItemSerializer(serializers.ModelSerializer):
    """
    Serializador para los items de la lista de compras.
    """
    product_name = serializers.CharField(required=False)
    product_category = serializers.CharField(required=False)
    shopping_list = serializers.PrimaryKeyRelatedField(
        queryset=ShoppingList.objects.all()
    )
    
    class Meta:
        model = ShoppingListItem
        fields = [
            'id',
            'shopping_list',
            'product_id',
            'product_name',
            'product_category',
            'quantity',
            'unit',
            'is_bought'
        ]
    
    def validate(self, data):
        """
        Valida el ID y obtiene el nombre
        del producto para guardarlo.
        """
        if self.instance and 'product_id' not in data:
            return data

        request = self.context.get('request')
        token = request.META.get('HTTP_AUTHORIZATION')
        
        if not token:
            raise serializers.ValidationError("No se pudo autenticar para verificar el producto.")

        headers = {
            "Authorization": token,
            "Content-Type": "application/json"
        }
        
        url = PRODUCT_SERVICE_URL + '/api/products/'
        
        product_id = data.get('product_id')
        product_name = data.get('product_name')

        if product_id:
            self._validate_product_id(data, product_id, url, headers)
        elif product_name:
            product_category = data.get('product_category', 'General')
            self._validate_product_name(data, product_name, product_category, url, headers)
        else:
            raise serializers.ValidationError(
                "Debes enviar llenar los campos del producto. (product_id o product_name)"
            )

        if 'product_category' in data:
            del data['product_category']
        
        return data

    def _validate_product_id(self, data, product_id, url, headers):
        """
        Valida el ID del producto y obtiene el nombre
        del producto para guardarlo.
        """
        try:
            check_res = requests.get(f"{url}{product_id}/", headers=headers)
            if check_res.status_code == 200:
                real_data = check_res.json()
                data['product_name'] = real_data['name']
            else:
                raise serializers.ValidationError({"product_id": "El producto seleccionado no existe"})
        except requests.exceptions.RequestException:
            raise serializers.ValidationError({"Error de conexion con el microservicio"})

    def _validate_product_name(self, data, product_name, product_category, url, headers):
        """
        Valida el nombre del producto y lo crea si no existe.
        """
        clean_name = product_name.strip().title()
        
        try:
            search_res = requests.get(
                url,
                headers=headers,
                params={
                    'name': clean_name
                }
            )
            if search_res.status_code != 200:
                raise serializers.ValidationError("Error al buscar producto.")

            existing_products = search_res.json()

            if len(existing_products) == 1:
                found = existing_products[0]
                if found['name'] == clean_name:
                    data['product_id'] = found['id']
                    data['product_name'] = found['name']
                    return
            
            payload = {
                'name': clean_name,
                'category': product_category
            }
            
            create_res = requests.post(url, headers=headers, json=payload)

            if create_res.status_code not in [200, 201]:
                raise serializers.ValidationError({
                    "El servicio de productos no pudo crear el producto."
                })
            
            new_product = create_res.json()
            data['product_id'] = new_product['id']
            data['product_name'] = new_product['name']
        except requests.exceptions.RequestException:
            raise serializers.ValidationError("Error de conexion al intentar buscar/crear producto.")
        
    def validate_quantity(self, value):
        if value <= 0:
            raise serializers.ValidationError(
                "La cantidad debe ser mayor a 0."
            )
        return value
