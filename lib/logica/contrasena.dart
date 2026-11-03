import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Vueltas que usa la web Torrexi al cifrar las contraseñas de la app (APP_PASS_ITERATIONS).
const vueltasPorDefecto = 100000;

/// Mismo cálculo que la web (`hashPassword` en src/legacy/app.js): PBKDF2-SHA256 de la contraseña,
/// con la sal como texto UTF-8, 32 bytes, en hexadecimal. Ese resultado es la contraseña de Firebase Auth.
String cifrarContrasena(String contrasena, String sal, {int vueltas = vueltasPorDefecto}) {
  return _hex(pbkdf2Sha256(utf8.encode(contrasena), utf8.encode(sal), vueltas, 32));
}

/// PBKDF2 con HMAC-SHA256 (RFC 8018).
Uint8List pbkdf2Sha256(List<int> clave, List<int> sal, int vueltas, int largo) {
  final hmac = Hmac(sha256, clave);
  final salida = Uint8List(largo);
  var hecho = 0;
  for (var bloque = 1; hecho < largo; bloque++) {
    var u = hmac.convert([...sal, bloque >> 24 & 0xff, bloque >> 16 & 0xff, bloque >> 8 & 0xff, bloque & 0xff]).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < vueltas; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    final n = (largo - hecho).clamp(0, t.length);
    salida.setRange(hecho, hecho + n, t);
    hecho += n;
  }
  return salida;
}

/// Como la web guarda el usuario: sin espacios y en minúsculas.
String normalizarUsuario(String usuario) => usuario.trim().toLowerCase();

String _hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
