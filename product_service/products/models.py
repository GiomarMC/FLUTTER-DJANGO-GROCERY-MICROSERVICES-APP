from django.db import models

class Product(models.Model):
    name = models.CharField(max_length=200, unique=True)
    category = models.CharField(max_length=100, default='General')

    def __str__(self):
        return f"{self.name}"
