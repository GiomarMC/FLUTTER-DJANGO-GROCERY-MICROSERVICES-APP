import 'package:flutter/material.dart';
import '../services/grocery_service.dart';
import '../models/shopping_list.dart';
import 'list_detail_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _groceryService = GroceryService();
  final _authService = AuthService();
  late Future<List<ShoppingList>> _listsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLists();
  }

  void _refreshLists() {
    setState(() {
      _listsFuture = _groceryService.getMyLists();
    });
  }

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

    await _groceryService.createList(dateStr);
    _refreshLists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          
          final lists = snapshot.data ?? [];
          if (lists.isEmpty) return const Center(child: Text("No tienes listas. Toca + para crear una."));

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(
                    list.status == 'open' ? Icons.shopping_cart_outlined : Icons.check_circle,
                    color: list.status == 'open' ? Colors.blue : Colors.green,
                  ),
                  title: Text("Compra del ${list.dateOfPurchase}"),
                  subtitle: Text("Estado: ${list.status}"),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListDetailScreen(shoppingList: list),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        child: const Icon(Icons.add),
      ),
    );
  }
}