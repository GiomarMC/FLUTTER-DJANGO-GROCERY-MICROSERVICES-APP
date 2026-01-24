import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../models/list_item.dart';
import '../models/product.dart';
import '../services/grocery_service.dart';

class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ListDetailScreen({super.key, required this.shoppingList});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final _groceryService = GroceryService();
  late Future<List<ListItem>> _itemsFuture;
  List<Product> _availableProducts = [];

  final List<String> _categories = [
    'General',
    'Frutas',
    'Verduras',
    'Lacteos',
    'Carnes',
    'Pescados',
    'Aseo Personal',
    'Bebidas',
    'Snacks',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _refreshItems();
    _loadProducts();
  }

  void _refreshItems() {
    setState(() {
      _itemsFuture = _groceryService.getItems(widget.shoppingList.id);
    });
  }

  void _loadProducts() async {
    try {
      final products = await _groceryService.getProducts();
      setState(() => _availableProducts = products);
    } catch (e) {
      print("Error cargando productos: $e");
    }
  }

  void _toggleItem(ListItem item) async {
    try {
      await _groceryService.toggleItemStatus(item.id, !item.isBought);
      _refreshItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar")));
    }
  }

  void _showAddItemDialog() {
    int? selectedProductId;
    String currentText = "";
    double quantity = 1.0;
    String selectedUnit = 'unit';
    String selectedCategory = "General";

    final units = const [
      {'value': 'unit', 'label': 'unidad'},
      {'value': 'kg', 'label': 'Kg'},
      {'value': 'g', 'label': 'Gramos'},
      {'value': 'l', 'label': 'Litros'},
      {'value': 'ml', 'label': 'Mililitros'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Agregar Producto"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Producto:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Autocomplete<Product>(
                      displayStringForOption: (Product option) => option.name,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Product>.empty();
                        }
                        return _availableProducts.where((Product option) {
                          return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (Product selection) {
                        setStateDialog(() {
                          selectedProductId = selection.id;
                          currentText = selection.name;
                        });
                      },
                      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                        textController.addListener(() {
                           currentText = textController.text;
                           if (selectedProductId != null) {
                             final match = _availableProducts.where((p) => p.name == currentText);
                             if (match.isEmpty) {
                               selectedProductId = null;
                             }
                           }
                           setStateDialog((){}); 
                        });

                        return TextField(
                          controller: textController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            hintText: "Ej. Arroz, Manzanas...",
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 15),

                    if (selectedProductId == null && currentText.isNotEmpty) ...[
                      const Text("Es un producto nuevo. Elige categoría:", 
                        style: TextStyle(fontSize: 12, color: Colors.blue)),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCategory,
                        items: _categories.map((String cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setStateDialog(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 15),
                    ],

                    const Text("Cantidad:", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        hintText: 'Ej: 1, 1.5, 2.5'
                      ),
                      onChanged: (val) {
                        setState(() {
                          quantity = double.tryParse(val) ?? 1.0;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'unit', child: Text('Unidad')),
                        DropdownMenuItem(value: 'kg', child: Text('Kilogramo')),
                        DropdownMenuItem(value: 'g', child: Text('Gramo')),
                        DropdownMenuItem(value: 'l', child: Text('Litro')),
                        DropdownMenuItem(value: 'ml', child: Text('Mililitro')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedUnit = value;
                          });
                        }
                      },
                    )
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Cancelar")
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final Product? newProduct = await _groceryService.addItem(
                    listId: widget.shoppingList.id,
                    quantity: quantity,
                    unit: selectedUnit,
                    productId: selectedProductId,
                    productName: currentText,
                    productCategory: selectedCategory,
                  );

                  if (newProduct != null) {
                    setState(() {
                      _availableProducts.add(newProduct);
                    });
                  }

                  Navigator.pop(context);
                  _refreshItems();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text("Agregar"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String _formatUnit(String unit) {
      switch (unit) {
        case 'kg': return 'kg';
        case 'g': return 'g';
        case 'l': return 'l';
        case 'ml': return 'ml';
        default: return 'unid.';
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista: ${widget.shoppingList.dateOfPurchase}"),
      ),
      body: FutureBuilder<List<ListItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final items = snapshot.data ?? [];
          
          if (items.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: const [
                   Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey),
                   SizedBox(height: 10),
                   Text("Lista vacía. ¡Agrega cosas!"),
                 ],
               ),
             );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: CheckboxListTile(
                  title: Text(
                    item.productName,
                    style: TextStyle(
                      decoration: item.isBought ? TextDecoration.lineThrough : null,
                      color: item.isBought ? Colors.grey : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    "Cantidad: ${item.quantity} ${_formatUnit(item.unit)}",
                  ),
                  value: item.isBought,
                  activeColor: Colors.green,
                  onChanged: (val) => _toggleItem(item),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}