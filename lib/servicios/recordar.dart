import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// «Recordar usuario y contraseña»: se guardan cifrados con el almacén seguro de Android (Keystore), solo en este celular.
class DatosRecordados {
  DatosRecordados({FlutterSecureStorage? almacen}) : _almacen = almacen ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacen;
  static const _claveUsuario = 'recordar_usuario';
  static const _claveContrasena = 'recordar_contrasena';

  /// Los datos guardados, o null si no hay (o no se pudieron leer).
  Future<({String usuario, String contrasena})?> leer() async {
    try {
      final usuario = await _almacen.read(key: _claveUsuario);
      final contrasena = await _almacen.read(key: _claveContrasena);
      if (usuario == null || contrasena == null) return null;
      return (usuario: usuario, contrasena: contrasena);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardar(String usuario, String contrasena) async {
    try {
      await _almacen.write(key: _claveUsuario, value: usuario.trim());
      await _almacen.write(key: _claveContrasena, value: contrasena);
    } catch (_) {
      // si no se pudo guardar, solo habrá que escribirlos la próxima vez
    }
  }

  Future<void> borrar() async {
    try {
      await _almacen.delete(key: _claveUsuario);
      await _almacen.delete(key: _claveContrasena);
    } catch (_) {
      // nada guardado
    }
  }
}
