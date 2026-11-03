import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/errores.dart';

void main() {
  test('usuario o contraseña mal dan el mismo error (no se dice cuál falló)', () {
    for (final c in ['invalid-credential', 'wrong-password', 'user-not-found', 'invalid-login-credentials']) {
      expect(falloDeCodigo(c), FalloSesion.datosIncorrectos);
    }
  });

  test('sin internet y sin permiso tienen su propio error', () {
    expect(falloDeCodigo('network-request-failed'), FalloSesion.sinInternet);
    expect(falloDeCodigo('permission-denied'), FalloSesion.sinAccesoApp);
  });

  test('un código desconocido queda como «otro»', () {
    expect(falloDeCodigo('algo-raro'), FalloSesion.otro);
  });
}
