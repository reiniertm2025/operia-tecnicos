import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/inconclusas.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'detalle_orden.dart';
import 'diseno.dart';

/// Órdenes de trabajo › Inconclusas: las completadas que dejaron algo pendiente, con su semáforo (atrasadas, hoy,
/// próximas), como en la web. Tocar una abre su detalle, donde se cambia o se resuelve.
class PantallaInconclusas extends StatefulWidget {
  const PantallaInconclusas({super.key, required this.tecnico, required this.servicio, required this.nombresZonas});

  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaInconclusas> createState() => _PantallaInconclusasState();
}

class _PantallaInconclusasState extends State<PantallaInconclusas> {
  late final Stream<List<Orden>> _lista = widget.servicio.inconclusas(widget.tecnico);

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final hoy = textoDia(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(t.menuInconclusas)),
      body: StreamBuilder<List<Orden>>(
        stream: _lista,
        builder: (context, foto) {
          final cargando = cargaOError(t, foto);
          if (cargando != null) return cargando;
          final lista = ordenarInconclusas(foto.data!, hoy);
          if (lista.isEmpty) return AvisoCentral(icono: Icons.task_alt_rounded, texto: t.incVacio);
          final colores = Theme.of(context).colorScheme;
          var posicion = 0;
          return ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 32),
            children: [
              for (final (luz, titulo, color) in [
                (LuzInconclusa.atrasada, t.incAtrasadas, colores.error),
                (LuzInconclusa.hoy, t.hoy, null),
                (LuzInconclusa.proxima, t.incProximas, null),
              ])
                if (lista.where((o) => luzInconclusa(o, hoy) == luz).toList() case final grupo
                    when grupo.isNotEmpty) ...[
                  TituloSeccion(texto: titulo, cuantas: grupo.length, color: color),
                  for (final o in grupo) _tarjeta(t, o, posicion++),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _tarjeta(Textos t, Orden o, int posicion) {
    final hero = heroDe('inconclusas', o);
    return TarjetaOrden(
      key: ValueKey(o.id),
      orden: o,
      zona: widget.nombresZonas[o.zonaId] ?? o.zonaId,
      verTecnico: true,
      hero: hero,
      posicion: posicion,
      nota: [
        fechaRegreso(o).isEmpty ? t.incSinFecha : t.incVuelve(fechaCorta(context, fechaRegreso(o))),
        motivoInconclusa(o),
      ].where((x) => x.isNotEmpty).join(' · '),
      alTocar: () => abrirDetalle(
        context,
        o,
        hero: hero,
        tecnico: widget.tecnico,
        servicio: widget.servicio,
        zonas: widget.nombresZonas,
      ),
    );
  }
}

/// Ventana para marcar una orden completada como inconclusa (o cambiar su fecha y motivo), como `incModal` de la web.
/// Devuelve true si se guardó.
Future<bool> marcarInconclusa(BuildContext context, Orden o, ServicioOrdenes servicio, Tecnico tecnico) async {
  final guardado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _VentanaInconclusa(orden: o, servicio: servicio, tecnico: tecnico),
  );
  return guardado == true;
}

class _VentanaInconclusa extends StatefulWidget {
  const _VentanaInconclusa({required this.orden, required this.servicio, required this.tecnico});

  final Orden orden;
  final ServicioOrdenes servicio;
  final Tecnico tecnico;

  @override
  State<_VentanaInconclusa> createState() => _VentanaInconclusaState();
}

class _VentanaInconclusaState extends State<_VentanaInconclusa> with GuardarYCerrar {
  // como la web: si no tenía fecha, se propone pasado mañana
  late String _dia = fechaRegreso(widget.orden).isNotEmpty
      ? fechaRegreso(widget.orden)
      : textoDia(DateTime.now().add(const Duration(days: 2)));
  late final _motivo = TextEditingController(text: motivoInconclusa(widget.orden));

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _elegirDia() async {
    final hoy = DateTime.now();
    final actual = DateTime.tryParse(_dia);
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 1, 12, 31),
      initialDate: actual != null && !actual.isBefore(DateTime(hoy.year, hoy.month, hoy.day)) ? actual : hoy,
    );
    if (d != null) setState(() => _dia = textoDia(d));
  }

  /// Texto rápido: se agrega al final, como los botones de la web.
  void _agregar(String texto) {
    final actual = _motivo.text.trim();
    _motivo.text = actual.isEmpty ? texto : '$actual. $texto';
    setState(() => error = null);
  }

  Future<void> _guardar() async {
    final t = Textos.of(context);
    final motivo = _motivo.text.trim();
    if (_dia.isEmpty) return setState(() => error = t.incFaltaFecha);
    if (motivo.isEmpty) return setState(() => error = t.incFaltaMotivo);
    await guardarYCerrar(
      () => widget.servicio.marcarInconclusa(widget.orden, _dia, motivo, widget.tecnico),
      listo: () => t.incGuardada,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.incTitulo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(t.incExplica, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _elegirDia,
            icon: const Icon(Icons.event_rounded),
            label: Text(_dia.isEmpty ? t.incFecha : fechaCorta(context, _dia)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivo,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => error = null),
            decoration: InputDecoration(labelText: t.incMotivo),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final texto in [t.incChipModem, t.incChipMaterial, t.incChipTerminar, t.incChipSenal])
                ActionChip(label: Text(texto), onPressed: () => _agregar(texto)),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          BotonPrincipal(texto: t.incGuardar, icono: Icons.save_rounded, ocupado: guardando, alTocar: _guardar),
        ],
      ),
    );
  }
}
