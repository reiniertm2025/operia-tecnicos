import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/textos.dart';
import '../logica/fotos.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'campos.dart';
import 'comun.dart';
import 'diseno.dart';

/// «Fotos del trabajo» en el detalle de la orden: las mismas que la web (hasta 6). Quien puede cambiar la orden toma o
/// elige fotos y las quita; cada cambio se guarda al momento.
class FotosOrden extends StatefulWidget {
  const FotosOrden({
    super.key,
    required this.orden,
    required this.servicio,
    required this.tecnico,
    required this.puedeCambiar,
  });

  final Orden orden;
  final ServicioOrdenes servicio;
  final Tecnico tecnico;
  final bool puedeCambiar;

  @override
  State<FotosOrden> createState() => _FotosOrdenState();
}

class _FotosOrdenState extends State<FotosOrden> {
  /// Las fotos guardadas (null mientras se leen).
  List<String>? _fotos;
  Object? _errorAlLeer;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _leer();
  }

  Future<void> _leer() async {
    if (cuantasFotos(widget.orden) == 0) {
      setState(() => _fotos = const []);
      return;
    }
    try {
      final f = await widget.servicio.fotosDeOrden(widget.orden);
      if (mounted) setState(() => _fotos = f);
    } catch (e) {
      // sin poder leerlas no se dejan cambiar (para no borrar las que hay)
      if (mounted) setState(() => _errorAlLeer = e);
    }
  }

  Future<void> _guardar(List<String> nuevas) async {
    final t = Textos.of(context);
    final avisos = ScaffoldMessenger.of(context);
    final antes = _fotos ?? const <String>[];
    setState(() => _guardando = true);
    try {
      final enLinea = await widget.servicio.guardarFotos(widget.orden, antes, nuevas, widget.tecnico);
      if (mounted) setState(() => _fotos = nuevas);
      avisos.showSnackBar(SnackBar(content: Text(enLinea ? t.fotGuardadas : t.sinSenal)));
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(textoDeError(t, e))));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _agregar(ImageSource fuente) async {
    final t = Textos.of(context);
    final foto = await tomarFoto(fuente);
    if (!mounted || foto == '') return;
    if (foto == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.prosFotoError)));
      return;
    }
    await _guardar([...?_fotos, foto]);
  }

  Future<void> _quitar(int i) async {
    final t = Textos.of(context);
    final si = await confirmar(
      context,
      icono: Icons.delete_outline_rounded,
      titulo: t.fotQuitarPregunta,
      texto: t.fotQuitarTexto,
      boton: t.fotQuitar,
    );
    if (si && mounted) await _guardar([...?_fotos]..removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final fotos = _fotos;
    final lleno = (fotos?.length ?? 0) >= maxFotos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Superficie(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.fotTitulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (_guardando) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 12),
            if (_errorAlLeer != null)
              Text(textoErrorCarga(t, _errorAlLeer!), style: Theme.of(context).textTheme.bodySmall)
            else if (fotos == null)
              const LinearProgressIndicator()
            else if (fotos.isEmpty)
              Text(t.fotNinguna, style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < fotos.length; i++)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Miniatura(foto: fotos[i], tamano: 84),
                        if (widget.puedeCambiar && !_guardando)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              tooltip: t.fotQuitar,
                              onPressed: () => _quitar(i),
                              icon: const Icon(Icons.close_rounded, size: 16),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            if (widget.puedeCambiar && fotos != null) ...[
              const SizedBox(height: 12),
              if (lleno)
                Text(t.fotMax(maxFotos), style: Theme.of(context).textTheme.bodySmall)
              else
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _guardando ? null : () => _agregar(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: Text(t.prosTomarFoto),
                    ),
                    OutlinedButton.icon(
                      onPressed: _guardando ? null : () => _agregar(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(t.prosGaleria),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
