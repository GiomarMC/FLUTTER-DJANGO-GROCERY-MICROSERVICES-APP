import 'dart:io';

//Clase que contiene la url de la api
class Environment {
  static const String androidLocal = 'http://10.0.2.2:80';
  static const String iosLocal = 'http://localhost:80';

  //Metodo que retorna la url de la api
  static String get apiUrl {
    if (Platform.isAndroid) {
        return androidLocal;
    } else {
        return iosLocal;
    }
  }
}