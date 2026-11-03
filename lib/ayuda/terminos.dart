import 'package:flutter/services.dart';

import 'contenido.dart';

// Los términos y condiciones están en assets/terminos/es.json y en.json (texto, no código).
// Al cambiar el texto, cambiar también `version` en los dos: la app se los vuelve a pedir a todos.

class SeccionTerminos {
  const SeccionTerminos(this.icono, this.titulo, this.texto);

  /// Clave del ícono («cuenta», «datos»…); la pantalla la cambia por el dibujo.
  final String icono;
  final String titulo;
  final String texto;
}

class Terminos {
  const Terminos({required this.version, required this.intro, required this.secciones, required this.cierre});

  /// Fecha de la redacción (AAAA-MM-DD). Se guarda en la ficha del usuario al aceptar.
  final String version;
  final String intro;
  final List<SeccionTerminos> secciones;
  final String cierre;

  factory Terminos.deJson(Map<String, dynamic> j) => Terminos(
    version: '${j['version'] ?? ''}',
    intro: '${j['intro'] ?? ''}',
    secciones: [
      for (final s in (j['secciones'] as List? ?? const []).cast<Map<String, dynamic>>())
        SeccionTerminos('${s['icono'] ?? ''}', '${s['titulo'] ?? ''}', '${s['texto'] ?? ''}'),
    ],
    cierre: '${j['cierre'] ?? ''}',
  );
}

/// Los términos en el idioma pedido.
Future<Terminos> cargarTerminos(String idioma, {AssetBundle? bundle}) async =>
    Terminos.deJson(await leerJsonDeIdioma('terminos', idioma, bundle: bundle));
