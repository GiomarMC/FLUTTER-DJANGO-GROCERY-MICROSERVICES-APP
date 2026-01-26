import 'package:flutter/material.dart';
import '../services/grocery_service.dart';
import '../models/shopping_list.dart';
import 'list_detail_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

// Pantalla principal que muestra las listas de compras del usuario
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Estado de la pantalla principal
class _HomeScreenState extends State<HomeScreen> {
  final _groceryService = GroceryService();
  final _authService = AuthService();
  late Future<List<ShoppingList>> _listsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLists();
  }

  // Método que actualiza la lista de compras
  void _refreshLists() {
    setState(() {
      _listsFuture = _groceryService.getMyLists();
    });
  }

  // Método que crea una nueva lista de compras
  Future<void> _createList() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate == null) return;

    final dateStr =
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}";

    try {
        await _groceryService.createList(dateStr);
        _refreshLists();
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al crear lista: $e")));
    }
  }

  // Método que edita la fecha de una lista de compras
  Future<void> _editListDate(ShoppingList list) async {
      if (list.status == 'closed') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se puede editar una lista cerrada")));
          return;
      }
      final current = DateTime.parse(list.dateOfPurchase);
      final selectedDate = await showDatePicker(
        context: context,
        initialDate: current.isBefore(DateTime.now()) ? DateTime.now() : current,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );

      if (selectedDate == null) return;

      final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}";
      
      try {
          await _groceryService.updateList(list.id, date: dateStr);
          _refreshLists();
      } catch(e) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error actualizando fecha: $e")));
      }
  }

  // Método que elimina una lista de compras
  Future<void> _deleteList(ShoppingList list) async {
      final confirm = await showDialog<bool>(
          context: context, 
          builder: (ctx) => AlertDialog(
              title: const Text("Eliminar Lista"),
              content: const Text("¿Estás seguro de que quieres eliminar esta lista?"),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
              ],
          )
      );

      if (confirm == true) {
          try {
              await _groceryService.deleteList(list.id);
              _refreshLists();
          } catch(e) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error eliminando lista: $e")));
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Cerrar Sesión",
            onPressed: () async {
              await _authService.logout();
              if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: FutureBuilder<List<ShoppingList>>(
        future: _listsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                   const SizedBox(height: 16),
                   Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                   TextButton(onPressed: _refreshLists, child: const Text("Reintentar"))
                 ],
               ),
             );
          }
          
          final lists = snapshot.data ?? [];
          if (lists.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                   const SizedBox(height: 24),
                   Text(
                     "No tienes listas aún",
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       color: Colors.grey.shade600,
                       fontWeight: FontWeight.bold
                     ),
                   ),
                   const SizedBox(height: 8),
                   const Text("Toca el botón + para crear tu primera lista", style: TextStyle(color: Colors.grey)),
                 ],
               ),
             );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              final isClosed = list.status == 'closed';
              return Card(
                elevation: 0, 
                color: isClosed ? Colors.grey.shade100 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isClosed ? Colors.grey.shade300 : Theme.of(context).primaryColor.withOpacity(0.2)
                  )
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListDetailScreen(shoppingList: list),
                      ),
                    ).then((_) => _refreshLists());
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isClosed ? Colors.grey.shade200 : Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isClosed ? Icons.check : Icons.shopping_cart,
                            color: isClosed ? Colors.grey : Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Compra del ${list.dateOfPurchase}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isClosed ? Colors.green.shade100 : Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isClosed ? "Completada" : "En curso",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isClosed ? Colors.green.shade800 : Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  if (isClosed && list.totalSpent != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      "\$${list.totalSpent}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700
                                      ),
                                    )
                                  ]
                                ],
                              )
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                          onSelected: (value) {
                               if (value == 'edit') _editListDate(list);
                               if (value == 'delete') _deleteList(list);
                          },
                          itemBuilder: (BuildContext context) {
                              return [
                                  const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 18),
                                          SizedBox(width: 8),
                                          Text("Editar Fecha")
                                        ],
                                      ),
                                  ),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text("Eliminar", style: TextStyle(color: Colors.red))
                                        ],
                                      ),
                                  ),
                              ];
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}