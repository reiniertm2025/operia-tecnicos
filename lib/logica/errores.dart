/// Por qué no se pudo iniciar sesión. La pantalla lo convierte en un mensaje en el idioma del técnico.
enum FalloSesion {
  faltanDatos,
  datosIncorrectos,
  tipoDesconocido,
  sinAccesoApp,
  cuentaDesactivada,
  demasiadosIntentos,
  sinInternet,
  otro,
}

/// Error de inicio de sesión; `detalle` es el código o dato extra para revisarlo (p. ej. el código de Firebase).
class ErrorDeSesion implements Exception {
  const ErrorDeSesion(this.fallo, [this.detalle = '']);
  final FalloSesion fallo;
  final String detalle;

  @override
  String toString() => detalle.isEmpty ? fallo.name : '${fallo.name} ($detalle)';
}

/// Qué significa cada código de error de Firebase (Auth y Firestore) al iniciar sesión.
FalloSesion falloDeCodigo(String codigo) {
  switch (codigo) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
    case 'invalid-login-credentials':
    case 'invalid-email':
      return FalloSesion.datosIncorrectos;
    case 'user-disabled':
      return FalloSesion.cuentaDesactivada;
    case 'too-many-requests':
      return FalloSesion.demasiadosIntentos;
    case 'network-request-failed':
    case 'unavailable':
      return FalloSesion.sinInternet;
    case 'permission-denied':
      return FalloSesion.sinAccesoApp;
    default:
      return FalloSesion.otro;
  }
}
