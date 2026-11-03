import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/contrasena.dart';

String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('PBKDF2-SHA256 da los valores de referencia (RFC 7914)', () {
    expect(
      hex(pbkdf2Sha256(utf8.encode('passwd'), utf8.encode('salt'), 1, 64)),
      '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
      '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
    );
  });

  test('cifra igual que la web (crypto.subtle con 100 000 vueltas)', () {
    // calculado con el mismo código de hashPassword de src/legacy/app.js
    expect(cifrarContrasena('Técnico 123', 'a1b2c3d4e5f6'), '111e1ea18634a18a1c59466bc038d511cb6069b2f86ea955f7cc81a36899a157');
  });

  test('el usuario se busca sin espacios y en minúsculas', () {
    expect(normalizarUsuario('  Pedro.Lopez '), 'pedro.lopez');
  });
}
