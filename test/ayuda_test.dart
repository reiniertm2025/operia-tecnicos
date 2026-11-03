import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/ayuda/contenido.dart';

void main() {
  ContenidoAyuda leer(String idioma) =>
      ContenidoAyuda.deJson(jsonDecode(File('assets/ayuda/$idioma.json').readAsStringSync()) as Map<String, dynamic>);

  test('el manual en español y en inglés tienen los mismos temas y versiones', () {
    final es = leer('es'), en = leer('en');
    expect(es.manual, isNotEmpty);
    expect(en.manual.length, es.manual.length);
    for (var i = 0; i < es.manual.length; i++) {
      expect(en.manual[i].pasos.length, es.manual[i].pasos.length, reason: 'tema ${es.manual[i].titulo}');
      expect(en.manual[i].soloAdmin, es.manual[i].soloAdmin);
    }
    expect(en.novedades.map((v) => v.numero), es.novedades.map((v) => v.numero));
  });

  test('la novedad más reciente es la versión de pubspec.yaml', () {
    final version = RegExp(r'^version:\s*([\d.]+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())![1];
    expect(leer('es').novedades.first.numero, version);
  });
}
