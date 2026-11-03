import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/fechas.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'diseno.dart';

/// Todas las órdenes (del técnico, o todas si es administrador), de la más nueva a la más vieja, por páginas.
/// Arriba se elige un rango de fechas (botones rápidos o calendario). Se lee solo al abrirla, al cambiar el rango y al
/// pedir «Ver más»; no se queda escuchando (cuidar lecturas).
class PestanaHistorial extends StatefulWidget {
  const PestanaHistorial({
    super.key,
    required this.tecnico,
    required this.servicio,
    required this.zona,
    required this.nombresZonas,
    required this.alAbrir,
    required this.rango,
    required this.alCambiarRango,
    this.buscar = '',
  });

  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final String? zona;
  final Map<String, String> nombresZonas;
  final ValueChanged<Orden> alAbrir;

  /// Días de creación a mostrar; null = todas las fechas.
  final RangoDias? rango;
  final ValueChanged<RangoDias?> alCambiarRango;

  /// Lo escrito en el buscador; filtra lo que ya se cargó.
  final String buscar;

  @override
  State<PestanaHistorial> createState() => _PestanaHistorialState();
}

class _PestanaHistorialState extends State<PestanaHistorial> {
  final _ordenes = <Orden>[];
  DocumentSnapshot<Map<String, dynamic>>? _ultima;
  bool _hayMas = true;
  bool _cargando = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar({bool desdeCero = false}) async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
      if (desdeCero) {
        _ordenes.clear();
        _ultima = null;
        _hayMas = true;
      }
    });
    try {
      final p = await widget.servicio.historial(
        widget.tecnico,
        zona: widget.zona,
        rango: widget.rango,
        despuesDe: _ultima,
      );
      if (!mounted) return;
      setState(() {
        _ordenes.addAll(p.ordenes);
        _ultima = p.ultima;
        _hayMas = p.hayMas;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotonesFechas(rango: widget.rango, alElegir: widget.alCambiarRango, conTodas: true),
        Expanded(child: _lista(t)),
      ],
    );
  }

  Widget _lista(Textos t) {
    // el técnico trae sus órdenes de todas sus localidades; el filtro se aplica aquí
    final zona = widget.zona;
    final visibles = [
      for (final o in _ordenes)
        if ((widget.tecnico.esAdmin || zona == null || o.zonaId == zona) &&
            coincideBusqueda(o, widget.buscar, zona: widget.nombresZonas[o.zonaId] ?? ''))
          o,
    ];
    if (_error != null && _ordenes.isEmpty) {
      return AvisoCentral(icono: Icons.cloud_off, texto: textoErrorCarga(t, _error!));
    }
    if (_ordenes.isEmpty && _cargando) return const ListaEsqueleto();
    if (visibles.isEmpty && !_hayMas && widget.buscar.trim().isNotEmpty) {
      return AvisoCentral(icono: Icons.search_off_rounded, texto: t.buscarSinResultados(widget.buscar.trim()));
    }
    if (visibles.isEmpty && !_hayMas) {
      return AvisoCentral(
        icono: widget.rango == null ? Icons.history : Icons.event_busy_rounded,
        texto: widget.rango == null ? t.vacioHistorial : t.histVacioRango,
      );
    }
    return RefreshIndicator(
      onRefresh: () => _cargar(desdeCero: true),
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        children: [
          for (var i = 0; i < visibles.length; i++)
            TarjetaOrden(
              key: ValueKey(visibles[i].id),
              orden: visibles[i],
              zona: widget.nombresZonas[visibles[i].zonaId] ?? visibles[i].zonaId,
              verTecnico: widget.tecnico.esAdmin,
              hero: heroDe('historial', visibles[i]),
              posicion: i % 25,
              alTocar: () => widget.alAbrir(visibles[i]),
            ),
          if (_hayMas)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _cargando
                    ? const CircularProgressIndicator()
                    : OutlinedButton.icon(
                        onPressed: _cargar,
                        icon: const Icon(Icons.expand_more),
                        label: Text(t.cargarMas),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
