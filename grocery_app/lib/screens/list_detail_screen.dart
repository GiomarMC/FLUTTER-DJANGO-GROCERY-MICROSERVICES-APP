import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../models/list_item.dart';
import '../models/product.dart';
import '../services/grocery_service.dart';

// Pantalla que muestra los detalles de una lista de compras
class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ListDetailScreen({super.key, required this.shoppingList});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

// Estado de la pantalla de detalles de la lista de compras
class _ListDetailScreenState extends State<ListDetailScreen> {
  final _groceryService = GroceryService();
  late Future<List<ListItem>> _itemsFuture;
  List<Product> _availableProducts = [];

  // Categorías de productos
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
    if (widget.shoppingList.status == 'closed') {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se puede modificar una lista cerrada")));
         return;
    }
    try {
      await _groceryService.toggleItemStatus(item.id, !item.isBought);
      _refreshItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar")));
    }
  }

  // Método que cierra la lista de compras
  Future<void> _closeList() async {
      double total = 0.0;
      final confirm = await showDialog<bool>(
          context: context, 
          builder: (ctx) {
              return AlertDialog(
                  title: const Text("Cerrar Lista"),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          const Text("Para cerrar la lista, ingresa el monto total gastado:"),
                          const SizedBox(height: 10),
                          TextField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: "Total Gastado", prefixText: "S/. "),
                              onChanged: (val) => total = double.tryParse(val) ?? 0.0,
                          )
                      ],
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                      ElevatedButton(
                          onPressed: () {
                              if (total <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa un monto válido")));
                                  return;
                              }
                              Navigator.pop(ctx, true);
                          }, 
                          child: const Text("Cerrar Lista"),
                      ),
                  ],
              );
          }
      );

      if (confirm == true) {
          try {
              await _groceryService.updateList(widget.shoppingList.id, status: 'closed', total: total);
              setState(() {
                  widget.shoppingList.status = 'closed';
                  widget.shoppingList.totalSpent = total;
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Lista cerrada con éxito!")));
          } catch(e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cerrando lista: $e")));
          }
      }
  }

  // Método que elimina un item de la lista de compras
  void _deleteItem(ListItem item) async {
       if (widget.shoppingList.status == 'closed') return;
       final confirm = await showDialog<bool>(
          context: context, 
          builder: (ctx) => AlertDialog(
              title: const Text("Eliminar Item"),
              content: const Text("¿Eliminar este producto de la lista?"),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
              ],
          )
      );

      if (confirm == true) {
          try {
              await _groceryService.deleteItem(item.id);
              _refreshItems();
          } catch(e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error eliminando item: $e")));
          }
      }
  }

  // Método que edita un item de la lista de compras
  void _editItem(ListItem item) {
       if (widget.shoppingList.status == 'closed') return;
       double quantity = item.quantity;
       String unit = item.unit;
       
       showDialog(
           context: context,
           builder: (ctx) {
               return AlertDialog(
                   title: Text("Editar ${item.productName}"),
                   content: StatefulBuilder(
                       builder: (context, setDialogState) {
                           return Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                   TextField(
                                     controller: TextEditingController(text: quantity.toString()),
                                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                     decoration: const InputDecoration(labelText: "Cantidad"),
                                     onChanged: (val) => quantity = double.tryParse(val) ?? 1.0,
                                   ),
                                   const SizedBox(height: 10),
                                   DropdownButtonFormField<String>(
                                      value: unit,
                                      items: const [
                                        DropdownMenuItem(value: 'unit', child: Text('Unidad')),
                                        DropdownMenuItem(value: 'kg', child: Text('Kilogramo')),
                                        DropdownMenuItem(value: 'g', child: Text('Gramo')),
                                        DropdownMenuItem(value: 'l', child: Text('Litro')),
                                        DropdownMenuItem(value: 'ml', child: Text('Mililitro')),
                                      ],
                                      onChanged: (val) {
                                          if (val != null) setDialogState(() => unit = val);
                                      },
                                   )
                               ],
                           );
                       }
                   ),
                   actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                        ElevatedButton(
                            onPressed: () async {
                                try {
                                    await _groceryService.updateItem(item.id, quantity, unit);
                                    Navigator.pop(ctx);
                                    _refreshItems();
                                } catch(e) {
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error actualizando: $e")));
                                }
                            },
                            child: const Text("Guardar"),
                        )
                   ],
               );
           }
       );
  }

  // Método que muestra el bottom sheet para agregar un item
  void _showAddItemBottomSheet() {
    int? selectedProductId;
    String currentText = "";
    double quantity = 1.0;
    String selectedUnit = 'unit';
    String selectedCategory = "General";
    
    // Controlador para resetear el campo de texto si es necesario
    final TextEditingController _typeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, 
                right: 24, 
                top: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Text(
                     "Agregar Producto", 
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 24),
                    Autocomplete<Product>(
                      displayStringForOption: (Product option) => option.name,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        return _availableProducts.where((Product option) {
                           return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (Product selection) {
                        setSheetState(() {
                          selectedProductId = selection.id;
                          currentText = selection.name;
                        });
                      },
                      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                        if (_typeController.text.isNotEmpty && textController.text.isEmpty) {
                            textController.text = _typeController.text;
                        }
                        
                        return TextField(
                          controller: textController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Nombre del producto",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            suffixIcon: selectedProductId != null 
                              ? const Icon(Icons.check_circle, color: Colors.green) 
                              : (currentText.isNotEmpty ? IconButton(
                                  icon: const Icon(Icons.clear), 
                                  onPressed: () {
                                     setSheetState(() {
                                        currentText = "";
                                        selectedProductId = null;
                                        textController.clear();
                                        _typeController.clear();
                                     });
                                  }
                                ) : null)
                          ),
                          onChanged: (text) {
                             currentText = text;
                             _typeController.text = text;
                             
                             if (selectedProductId != null) {
                               final match = _availableProducts.where((p) => p.name == text);
                               if (match.isEmpty) {
                                  selectedProductId = null;
                               }
                             }
                             setSheetState(() {});
                          },
                        );
                      },
                    ),

                    if (selectedProductId == null) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedCategory,
                        decoration: const InputDecoration(
                           labelText: "Categoría (Nuevo Producto)",
                           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                        ),
                        items: _categories.map((String cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedCategory = val);
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Cantidad'),
                            onChanged: (val) {
                              quantity = double.tryParse(val) ?? 1.0;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            decoration: const InputDecoration(labelText: 'Unidad'),
                            items: const [
                              DropdownMenuItem(value: 'unit', child: Text('Unidad')),
                              DropdownMenuItem(value: 'kg', child: Text('Kg')),
                              DropdownMenuItem(value: 'g', child: Text('Gr')),
                              DropdownMenuItem(value: 'l', child: Text('Lt')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
                            ],
                            onChanged: (value) {
                              if (value != null) setSheetState(() => selectedUnit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        try {
                           if (currentText.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa un nombre de producto")));
                              return;
                           }

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
                      child: const Text("AGREGAR A LA LISTA"),
                    ),
                    const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      }
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
        title: Column(
          children: [
            const Text("Lista de Compras", style: TextStyle(fontSize: 16)),
            Text(
              widget.shoppingList.dateOfPurchase, 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)
            ),
          ],
        ),
        actions: [
            if (widget.shoppingList.status == 'open')
                FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).primaryColor,
                    ),
                    icon: const Icon(Icons.lock_clock),
                    label: const Text("CERRAR"),
                    onPressed: _closeList,
                )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("ESTADO", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.shoppingList.status == 'closed' ? "CERRADA" : "ABIERTA",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                Column(
                  children: [
                    const Text("TOTAL", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      widget.shoppingList.totalSpent != null 
                        ? "S/.${widget.shoppingList.totalSpent}" 
                        : "--",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    )
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<ListItem>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                }
                
                final items = snapshot.data ?? [];
                
                if (items.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade300),
                         const SizedBox(height: 16),
                         Text("Tu lista está vacía", style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                         const SizedBox(height: 8),
                         const Text("Agrega productos para comenzar", style: TextStyle(color: Colors.grey)),
                       ],
                     ),
                   );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Checkbox(
                          value: item.isBought,
                          activeColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (_) => _toggleItem(item),
                        ),
                        title: Text(
                          item.productName,
                          style: TextStyle(
                            decoration: item.isBought ? TextDecoration.lineThrough : null,
                            color: item.isBought ? Colors.grey : Colors.black87,
                            fontWeight: item.isBought ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text("${item.quantity} ${_formatUnit(item.unit)}", style: TextStyle(color: Colors.grey.shade600)),
                             Text(
                                item.isBought ? "Comprado" : "Pendiente",
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold,
                                  color: item.isBought ? Colors.green : Colors.orange
                                )
                             )
                          ],
                        ),
                        trailing: widget.shoppingList.status == 'open'
                          ? PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                              padding: EdgeInsets.zero,
                              onSelected: (val) {
                                  if (val == 'edit') _editItem(item);
                                  if (val == 'delete') _deleteItem(item);
                              },
                              itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Editar")])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text("Eliminar", style: TextStyle(color: Colors.red))])),
                              ],
                            )
                          : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.shoppingList.status == 'open' 
        ? FloatingActionButton.extended(
            onPressed: _showAddItemBottomSheet,
            icon: const Icon(Icons.add),
            label: const Text("Agregar Producto"),
          )
        : null,
    );
  }
}