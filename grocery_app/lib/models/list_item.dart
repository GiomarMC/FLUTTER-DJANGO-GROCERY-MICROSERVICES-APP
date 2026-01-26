// Clase que representa un item de la lista de compras
class ListItem {
    final int id;
    final int shoppingListId;
    final int? productId;
    final String productName;
    final double quantity;
    final String unit;
    final bool isBought;

    ListItem({
        required this.id,
        required this.shoppingListId,
        this.productId,
        required this.productName,
        required this.quantity,
        required this.unit,
        required this.isBought,
    });

    factory ListItem.fromJson(Map<String, dynamic> json) {
        return ListItem(
            id: json['id'],
            shoppingListId: json['shopping_list'],
            productId: json['product_id'],
            productName: json['product_name'] ?? 'Cargando...',
            quantity: double.parse(json['quantity'].toString()),
            unit: json['unit'],
            isBought: json['is_bought'],
        );
    }
}