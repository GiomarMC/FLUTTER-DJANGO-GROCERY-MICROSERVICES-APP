import 'dart:io';

//Clase que contiene la url de la api
class Environment {
  static const String androidLocal = 'http://10.0.2.2:80';
  static const String iosLocal = 'http://localhost:80';
  
  // URL del Gateway en producción (Cloud Run)
  static const String production = 'https://grocery-gateway-752369547432.us-central1.run.app';

  //Metodo que retorna la url de la api
  static String get apiUrl {
    // Detectar si estamos en modo release (producción)
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    
    if (isProduction) {
      return production;
    }
    
    // Modo desarrollo
    if (Platform.isAndroid) {
        return androidLocal;
    } else {
        return iosLocal;
    }
  }
}