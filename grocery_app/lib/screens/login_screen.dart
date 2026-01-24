import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

//Clase que representa la pantalla de login
class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});

    @override
    State<LoginScreen> createState() => _LoginScreenState();
}

//Clase que representa el estado de la pantalla de login
class _LoginScreenState extends State<LoginScreen> {
    final _authService = AuthService();
    bool _isLoading = false;

    void _handleGoogleLogin() async {
        setState(() => _isLoading = true);
        
        final result = await _authService.signInWithGoogle();

        setState(() => _isLoading = false);

        if (!mounted) return;

        if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('¡Bienvenido! ${result['user']['name']}')),
            );

            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen())
            );
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.red,
                ),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grocery System')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart, size: 100, color: Colors.blue),
              const SizedBox(height: 30),
              
              const Text(
                "Bienvenido",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Gestiona tus compras de forma inteligente",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 60),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleGoogleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.g_mobiledata, size: 40, color: Colors.red), 
                            const SizedBox(width: 10),
                            const Text(
                              "Continuar con Google",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}