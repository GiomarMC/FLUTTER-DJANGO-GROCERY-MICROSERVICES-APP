import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';
import '../models/shopping_list.dart';
import '../models/list_item.dart';
import '../models/product.dart';
import 'auth_service.dart';

class GroceryService {
    final _storage = const FlutterSecureStorage();
    final AuthService authService = AuthService();

    Future<Map<String, String>> _getHeaders() async {
        final token = await _storage.read(key: 'access_token');
        return {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
        };
    }

    Future<List<ShoppingList>> getMyLists() async {
        final url = Uri.parse('${Environment.apiUrl}/api/shopping-lists/');
        final headers = await _getHeaders();

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            return data.map((json) => ShoppingList.fromJson(json)).toList();
        }
        if (response.statusCode == 401) {
            await authService.refreshToken();
            return getMyLists();
        }else {
            throw Exception('Error cargando listas: ${response.statusCode}');
        }
    }

    Future<ShoppingList> createList(String date) async {
        final url = Uri.parse('${Environment.apiUrl}/api/shopping-lists/');
        final headers = await _getHeaders();

        final response = await http.post(
            url,
            headers: headers,
            body: jsonEncode({
                'date_of_purchase': date,
                'status': 'open',
            }),
        );

        if (response.statusCode == 201) {
            final data = jsonDecode(response.body);
            return ShoppingList.fromJson(data);
        }
        if (response.statusCode == 401) {
            await authService.refreshToken();
            return createList(date);
        } else {
            throw Exception('Error creando lista: ${response.body}');
        }
    }

    Future<List<ListItem>> getItems(int listId) async {
        final url = Uri.parse('${Environment.apiUrl}/api/items/?shopping_list=$listId');
        final headers = await _getHeaders();

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            
            return data.map((json) => ListItem.fromJson(json)).toList();
        }
        if (response.statusCode == 401) {
            await authService.refreshToken();
            return getItems(listId);
        } else {
            throw Exception('Error cargando items: ${response.body}');
        }
    }
    
    Future<Product?> addItem({
        required int listId,
        required double quantity,
        required String unit,
        int? productId,
        String? productName,
        String? productCategory,
    }) async {
        final url = Uri.parse('${Environment.apiUrl}/api/items/');
        final headers = await _getHeaders();

        final Map<String, dynamic> bodyData = {
            'shopping_list': listId,
            'quantity': quantity,
            'unit': unit,
            'is_bought': false,
        };

        if (productId != null) {
            bodyData['product_id'] = productId;
        } else if (productName != null && productName.trim().isNotEmpty) {
            bodyData['product_name'] = productName.trim();
            bodyData['product_category'] = productCategory ?? 'General';
        } else {
            throw Exception('Debe proporcionar un producto o nombre de producto');
        }

        print('BODY ENVIADO: ${jsonEncode(bodyData)}');
        final response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(bodyData),
        );

        if (response.statusCode >= 400) {
            throw Exception('Error agregando item: ${response.body}/');
        }

        if (response.statusCode == 401) {
            await authService.refreshToken();
            return addItem(listId: listId, quantity: quantity, unit: unit, productId: productId, productName: productName, productCategory: productCategory);
        }

        if (productId == null && productName != null) {
            final decodedProductId = jsonDecode(response.body)['product_id'];
            
            return Product(
                id: decodedProductId,
                name: productName.trim(),
                category: productCategory ?? 'General',
            );
        }

        return null;
    }

    Future<int> createProduct(String name, String category) async {
        final headers = await _getHeaders();
        final response = await http.post(
            Uri.parse('${Environment.apiUrl}/api/products/'),
            headers: headers,
            body: jsonEncode({
                'name': name,
                'category': category,
            }),
        );

        if (response.statusCode == 201) {
            final body = jsonDecode(response.body);
            return body['id'];
        }
        if (response.statusCode == 401) {
            await authService.refreshToken();
            return createProduct(name, category);
        } else {
            throw Exception('Error creando producto: ${response.body}/');
        }
    }

    Future<void> toggleItemStatus(int itemId, bool isBought) async {
        final url = Uri.parse('${Environment.apiUrl}/api/items/$itemId/');
        final headers = await _getHeaders();

        final response = await http.patch(
            url,
            headers: headers,
            body: jsonEncode({
                'is_bought': isBought,
            }),
        );

        if (response.statusCode != 200) {
            throw Exception('Error actualizando item: ${response.body}/');
        }

        if (response.statusCode == 401) {
            await authService.refreshToken();
            return toggleItemStatus(itemId, isBought);
        }
    }

    Future<List<Product>> getProducts() async {
        final url = Uri.parse('${Environment.apiUrl}/api/products/');
        final headers = await _getHeaders();

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            return data.map((json) => Product.fromJson(json)).toList();
        }
        if (response.statusCode == 401) {
            await authService.refreshToken();
            return getProducts();
        } else {
            throw Exception('Error cargando productos');
        }
    }
}