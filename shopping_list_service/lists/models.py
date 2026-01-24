from django.db import models
from django.utils import timezone

class ShoppingList(models.Model):
    STATUS_CHOICES = [
        ('open', 'Abierta'),
        ('closed', 'Cerrada'),
    ]

    user_id = models.IntegerField(db_index=True)

    date_of_purchase = models.DateField(default=timezone.now)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='open')
    
    total_spent = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Lista {self.date_of_purchase} (User {self.user_id})"

    class Meta:
        ordering = ['-date_of_purchase']


class ShoppingListItem(models.Model):
    UNIT_CHOICES = [
        ('unit', 'Unidad'),
        ('kg', 'Kilogramo'),
        ('g', 'Gramo'),
        ('l', 'Litro'),
        ('ml', 'Mililitro'),
    ]

    shopping_list = models.ForeignKey(
        ShoppingList, related_name='items', on_delete=models.CASCADE
    )
    product_id = models.IntegerField(null=True, blank=True)
    product_name = models.CharField(max_length=200)
    quantity = models.DecimalField(max_digits=10, decimal_places=2)
    unit = models.CharField(max_length=5, choices=UNIT_CHOICES, default='unit')
    is_bought = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.product_name} ({self.quantity} {self.unit})"
