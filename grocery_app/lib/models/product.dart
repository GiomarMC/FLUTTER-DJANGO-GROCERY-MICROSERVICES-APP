// Clase que representa un producto
class Product {
    final int id;
    final String name;
    final String category;

    Product({
        required this.id,
        required this.name,
        required this.category,
    });

    factory Product.fromJson(Map<String, dynamic> json) {
        return Product(
            id: json['id'],
            name: json['name'],
            category: json['category'],
        );
    } 
}