import 'dart:convert';

import 'package:flutter/services.dart';

// El manual y las novedades están en assets/ayuda/es.json y en.json (texto, no código).
// ACTUALIZARLOS EN CADA VERSIÓN, junto con `version` en pubspec.yaml.

class TemaManual {
  const TemaManual(this.titulo, this.pasos, {this.soloAdmin = false});
  final String titulo;
  final List<String> pasos;
  final bool soloAdmin;
}

class Version {
  const Version(this.numero, this.fecha, this.cambios);
  final String numero;
  final String fecha;
  final List<String> cambios;
}

class ContenidoAyuda {
  const ContenidoAyuda(this.manual, this.novedades);
  final List<TemaManual> manual;

  /// La más nueva primero.
  final List<Version> novedades;

  factory ContenidoAyuda.deJson(Map<String, dynamic> j) {
    List<String> textos(Object? v) => [for (final x in (v as List? ?? const [])) '$x'];
    return ContenidoAyuda(
      [
        for (final m in (j['manual'] as List? ?? const []).cast<Map<String, dynamic>>())
          TemaManual('${m['titulo'] ?? ''}', textos(m['pasos']), soloAdmin: m['soloAdmin'] == true),
      ],
      [
        for (final v in (j['novedades'] as List? ?? const []).cast<Map<String, dynamic>>())
          Version('${v['version'] ?? ''}', '${v['fecha'] ?? ''}', textos(v['cambios'])),
      ],
    );
  }
}

/// Lee un archivo de texto de `assets/<carpeta>/<idioma>.json`; si no existe ese idioma, el de español.
Future<Map<String, dynamic>> leerJsonDeIdioma(String carpeta, String idioma, {AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  String texto;
  try {
    texto = await b.loadString('assets/$carpeta/$idioma.json');
  } catch (_) {
    texto = await b.loadString('assets/$carpeta/es.json');
  }
  return jsonDecode(texto) as Map<String, dynamic>;
}

/// El manual y las novedades en el idioma pedido.
Future<ContenidoAyuda> cargarAyuda(String idioma, {AssetBundle? bundle}) async =>
    ContenidoAyuda.deJson(await leerJsonDeIdioma('ayuda', idioma, bundle: bundle));
