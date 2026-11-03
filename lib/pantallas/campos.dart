import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../ayuda/contenido.dart';
import '../l10n/textos.dart';
import '../logica/nueva_orden.dart';
import '../logica/orden.dart';
import '../logica/telefono.dart';
import '../servicios/ubicacion.dart';
import 'diseno.dart';

/// Campos que comparten los formularios (orden y prospecto): teléfono con país y ubicación con GPS.

final _paises = <String, Future<Map<String, String>>>{};

/// Nombre de cada país (ISO → nombre) en el idioma de la app, de assets/paises; se lee una vez.
Future<Map<String, String>> nombresDePaises(String idioma) => _paises.putIfAbsent(
  idioma,
  () async => {for (final e in (await leerJsonDeIdioma('paises', idioma)).entries) e.key: '${e.value}'},
);

/// Teléfono con el país (bandera y lada) a la izquierda; no es obligatorio.
class CampoTelefono extends StatefulWidget {
  const CampoTelefono({super.key, required this.controller, required this.pais, required this.alCambiarPais});

  final TextEditingController controller;
  final String pais;
  final ValueChanged<String> alCambiarPais;

  @override
  State<CampoTelefono> createState() => _CampoTelefonoState();
}

class _CampoTelefonoState extends State<CampoTelefono> {
  Future<void> _elegirPais() async {
    final t = Textos.of(context);
    final nombres = await nombresDePaises(Localizations.localeOf(context).languageCode);
    if (!mounted) return;
    final paises = [
      for (final e in nombres.entries)
        if (ladaDe(e.key).isNotEmpty) (iso: e.key, nombre: e.value, lada: ladaDe(e.key)),
    ]..sort((a, b) => plano(a.nombre).compareTo(plano(b.nombre)));
    var buscar = '';
    final elegido = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, actualizar) {
          final q = plano(buscar.trim());
          final lista = [
            for (final p in paises)
              if (q.isEmpty || plano('${p.nombre} +${p.lada} ${p.iso}').contains(q)) p,
          ];
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => actualizar(() => buscar = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: t.foBuscarPais,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: Text(bandera(lista[i].iso), style: const TextStyle(fontSize: 26)),
                        title: Text(lista[i].nombre),
                        trailing: Text('+${lista[i].lada}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        selected: lista[i].iso == widget.pais,
                        onTap: () => Navigator.pop(context, lista[i].iso),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (elegido != null) widget.alCambiarPais(elegido);
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final colores = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Presionable(
          radio: 14,
          alTocar: _elegirPais,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colores.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(bandera(widget.pais), style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text('+${ladaDe(widget.pais)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: t.telefono, helperText: t.foOpcional),
          ),
        ),
      ],
    );
  }
}

/// Coordenadas (o enlace de Google Maps) con el botón «Usar mi ubicación».
class CampoUbicacion extends StatefulWidget {
  const CampoUbicacion({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<CampoUbicacion> createState() => _CampoUbicacionState();
}

class _CampoUbicacionState extends State<CampoUbicacion> {
  bool _buscando = false;

  Future<void> _usarMiUbicacion() async {
    final t = Textos.of(context);
    setState(() => _buscando = true);
    try {
      final u = await miUbicacion();
      if (mounted) widget.controller.text = textoCoordenadas(u.lat, u.lng);
    } on ErrorDeUbicacion catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(switch (e.fallo) {
              FalloUbicacion.apagada => t.errUbicacionApagada,
              FalloUbicacion.sinPermiso => t.errUbicacionPermiso,
              FalloUbicacion.otro => t.errUbicacionOtro,
            }),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: t.foCoordenadas, prefixIcon: const Icon(Icons.pin_drop_outlined)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _buscando ? null : _usarMiUbicacion,
          icon: _buscando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.gps_fixed_rounded),
          label: Text(t.foMiUbicacion),
        ),
      ],
    );
  }
}

/// Toma una foto con la cámara o de la galería, reducida como la web (hasta 1000 px, JPEG): `data:image/jpeg;base64,…`.
/// Devuelve '' si no eligió ninguna, o null si no se pudo usar.
Future<String?> tomarFoto(ImageSource fuente) async {
  try {
    final x = await ImagePicker().pickImage(source: fuente, maxWidth: 1000, maxHeight: 1000, imageQuality: 70);
    if (x == null) return '';
    final texto = 'data:image/jpeg;base64,${base64Encode(await x.readAsBytes())}';
    // cabe de sobra en un documento de Firebase (máximo 1 MB)
    return texto.length > 700000 ? null : texto;
  } catch (_) {
    return null;
  }
}

/// La imagen de una foto guardada como la web (`data:image/jpeg;base64,…`); null si no se puede leer.
MemoryImage? imagenDeFoto(String foto) {
  final i = foto.indexOf('base64,');
  try {
    return MemoryImage(base64Decode(i < 0 ? foto : foto.substring(i + 7)));
  } catch (_) {
    return null;
  }
}

/// Foto chica; tocarla la abre en grande.
class Miniatura extends StatelessWidget {
  const Miniatura({super.key, required this.foto, this.tamano = 64});

  final String foto;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final img = imagenDeFoto(foto);
    if (img == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(child: Image(image: img)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(image: img, width: tamano, height: tamano, fit: BoxFit.cover),
      ),
    );
  }
}
