class ShoppingList {
    final int id;
    final String dateOfPurchase;
    final String status;
    final double? totalSpent;

    ShoppingList({
        required this.id,
        required this.dateOfPurchase,
        required this.status,
        this.totalSpent,
    });

    factory ShoppingList.fromJson(Map<String, dynamic> json) {
        return ShoppingList(
            id: json['id'],
            dateOfPurchase: json['date_of_purchase'],
            status: json['status'],
            totalSpent: json['total_spent'] != null
                ? double.tryParse(json['total_spent'].toString())
                : null,
        );
    }
}