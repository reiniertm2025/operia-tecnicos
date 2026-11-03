import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/cobro.dart';
import '../logica/modems.dart';
import '../logica/nuevos_cancelados.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'detalle_orden.dart';
import 'diseno.dart';

/// Pantallas de los menús «Nuevos Servicios» y «Cancelados» de la web (solo el administrador).

/// Qué lista de órdenes por fechas es.
enum ListaPorDia { nsHistorico, ncNuevos, tvCable, tvDoblePlay, definitivos }

/// Qué lista de órdenes abiertas es.
enum ListaAbiertas { futuro, nsPendientes }

/// El texto de «cuándo toca» (`npAlert`): atrasada, hoy o en cuántos días.
String textoCuando(Textos t, ({CuandoToca cuando, int dias}) c) => switch (c.cuando) {
  CuandoToca.atrasada => c.dias == 1 ? t.nsAtrasado1 : t.nsAtrasadoN(c.dias),
  CuandoToca.hoy => t.nsTocaHoy,
  CuandoToca.futura => c.dias == 1 ? t.nsManana : t.nsEnDias(c.dias),
};

/// Tarjetas de estas listas (con quién entró, el servicio y las localidades); tocar una abre su detalle.
class _Tarjetas {
  const _Tarjetas(this.tecnico, this.servicio, this.zonas);
  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> zonas;

  Widget de(BuildContext context, Orden o, int posicion, String lugar, {String nota = ''}) {
    final hero = heroDe(lugar, o);
    return TarjetaOrden(
      key: ValueKey('$lugar-${o.id}'),
      orden: o,
      zona: zonas[o.zonaId] ?? o.zonaId,
      verTecnico: true,
      hero: hero,
      posicion: posicion,
      nota: nota,
      alTocar: () => abrirDetalle(context, o, hero: hero, tecnico: tecnico, servicio: servicio, zonas: zonas),
    );
  }
}

/// Histórico de servicios nuevos, Cancelados › Nuevos Servicios / TV Cable / TV Doble Play / Definitivos: las órdenes
/// de esos días (por su día de servicio), del más nuevo al más viejo.
class PantallaListaPorDia extends StatefulWidget {
  const PantallaListaPorDia({
    super.key,
    required this.lista,
    required this.tecnico,
    required this.servicio,
    required this.nombresZonas,
  });

  final ListaPorDia lista;
  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaListaPorDia> createState() => _PantallaListaPorDiaState();
}

class _PantallaListaPorDiaState extends State<PantallaListaPorDia>
    with
        LecturaPorPeriodo<PantallaListaPorDia, ({List<Orden> ordenes, Catalogos cat})>,
        FiltroDeZona<PantallaListaPorDia> {
  late final _tarjetas = _Tarjetas(widget.tecnico, widget.servicio, widget.nombresZonas);

  @override
  Future<({List<Orden> ordenes, Catalogos cat})> leer({bool recargar = false}) async {
    fijarRango(cortarEnHoy: false);
    final r = await Future.wait<Object>([
      // como la web: Cancelados › Nuevos Servicios va por la fecha de cancelación y Definitivos por la de registro
      switch (widget.lista) {
        ListaPorDia.ncNuevos => widget.servicio.ordenesPorFecha('cancelledAt', periodo, recargar: recargar),
        ListaPorDia.definitivos => widget.servicio.ordenesPorFecha('createdAt', periodo, recargar: recargar),
        _ => widget.servicio.ordenesPorDia(periodo, recargar: recargar),
      },
      widget.servicio.catalogos(),
    ]);
    return (ordenes: r[0] as List<Orden>, cat: r[1] as Catalogos);
  }

  bool _entra(Orden o, Catalogos cat) => switch (widget.lista) {
    ListaPorDia.nsHistorico => esNuevoHistorico(o, cat),
    ListaPorDia.ncNuevos => esNuevoCancelado(o, cat),
    ListaPorDia.tvCable => cancelacionTv(o, cat) == CancelTv.cable,
    ListaPorDia.tvDoblePlay => cancelacionTv(o, cat) == CancelTv.fibra,
    ListaPorDia.definitivos => esBajaDefinitiva(o, cat),
  };

  /// En Definitivos, cómo va su módem; en las demás, nada.
  String _nota(Textos t, Orden o) {
    if (widget.lista != ListaPorDia.definitivos || !esBajaConModem(o)) return '';
    return switch (estadoModem(o)) {
      EstadoModem.recuperado => t.defModemRecuperado,
      EstadoModem.asignado => t.modemLoRecupera(recuperaNombre(o)),
      EstadoModem.sinAsignar => t.modemSinAsignar,
    };
  }

  String _titulo(Textos t) => switch (widget.lista) {
    ListaPorDia.nsHistorico => '${t.menuNuevosServicios} › ${t.menuNsHistorico}',
    ListaPorDia.ncNuevos => '${t.menuCancelados} › ${t.menuNcNuevos}',
    ListaPorDia.tvCable => '${t.menuCancelados} › ${t.menuTvCable}',
    ListaPorDia.tvDoblePlay => '${t.menuCancelados} › ${t.menuTvDoblePlay}',
    ListaPorDia.definitivos => '${t.menuCancelados} › ${t.menuDefinitivos}',
  };

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_titulo(t))),
      body: conDatos(t, (d) {
        final elegidas = d.ordenes.where((o) => _entra(o, d.cat));
        final todas = switch (widget.lista) {
          ListaPorDia.ncNuevos => masNuevasPor(elegidas, 'cancelledAt'),
          ListaPorDia.definitivos => masNuevasPor(elegidas, 'createdAt'),
          _ => masNuevasPrimero(elegidas),
        };
        final lista = todas.where((o) => enZona(o.zonaId)).toList();
        return listaDelPeriodo(t, [
          ...encabezadoDeZona(
            t,
            todas: todas.map((o) => o.zonaId),
            nombres: widget.nombresZonas,
            vacia: lista.isEmpty,
            icono: Icons.inbox_rounded,
            textoVacio: t.listaVacia,
          ),
          TituloSeccion(texto: _titulo(t), cuantas: lista.length),
          for (var i = 0; i < lista.length; i++)
            _tarjetas.de(context, lista[i], i, widget.lista.name, nota: _nota(t, lista[i])),
        ]);
      }),
    );
  }
}

/// Nuevos Servicios › Futuro y › Pendientes: de las órdenes abiertas (en vivo), con cuándo tocan.
class PantallaListaAbiertas extends StatefulWidget {
  const PantallaListaAbiertas({
    super.key,
    required this.lista,
    required this.tecnico,
    required this.servicio,
    required this.nombresZonas,
  });

  final ListaAbiertas lista;
  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaListaAbiertas> createState() => _PantallaListaAbiertasState();
}

class _PantallaListaAbiertasState extends State<PantallaListaAbiertas> with FiltroDeZona<PantallaListaAbiertas> {
  late final _tarjetas = _Tarjetas(widget.tecnico, widget.servicio, widget.nombresZonas);
  late final Stream<List<Orden>> _abiertas = widget.servicio.abiertas(widget.tecnico);
  late final Future<Catalogos> _cat = widget.servicio.catalogos();

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final hoy = textoDia(DateTime.now());
    final futuro = widget.lista == ListaAbiertas.futuro;
    return Scaffold(
      appBar: AppBar(title: Text('${t.menuNuevosServicios} › ${futuro ? t.menuFuturo : t.menuNsPendientes}')),
      body: FutureBuilder<Catalogos>(
        future: _cat,
        builder: (context, cat) => StreamBuilder<List<Orden>>(
          stream: _abiertas,
          builder: (context, foto) {
            final cargando = cargaOError(t, foto) ?? (cat.hasError ? cargaOError(t, cat) : null);
            if (cargando != null) return cargando;
            if (!cat.hasData) return const ListaEsqueleto();
            final todas = porDiaYHora([
              for (final o in foto.data!)
                if (futuro ? esFutura(o, hoy) : esNuevoPendiente(o, cat.data!)) o,
            ]);
            final lista = todas.where((o) => enZona(o.zonaId)).toList();
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ...encabezadoDeZona(
                  t,
                  todas: todas.map((o) => o.zonaId),
                  nombres: widget.nombresZonas,
                  vacia: lista.isEmpty,
                  icono: Icons.inbox_rounded,
                  textoVacio: futuro ? t.futVacio : t.npVacio,
                ),
                for (var i = 0; i < lista.length; i++)
                  _tarjetas.de(
                    context,
                    lista[i],
                    i,
                    widget.lista.name,
                    nota: textoCuando(t, cuandoToca(lista[i], hoy)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Cancelados › Temporales: los registros de esos días, con su regreso y el módem a recoger.
class PantallaTemporales extends StatefulWidget {
  const PantallaTemporales({super.key, required this.servicio, required this.nombresZonas});

  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaTemporales> createState() => _PantallaTemporalesState();
}

class _PantallaTemporalesState extends State<PantallaTemporales>
    with LecturaPorPeriodo<PantallaTemporales, List<Temporal>>, FiltroDeZona<PantallaTemporales> {
  @override
  Future<List<Temporal>> leer({bool recargar = false}) {
    fijarRango(cortarEnHoy: false);
    return widget.servicio.temporales(periodo, recargar: recargar);
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final hoy = textoDia(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text('${t.menuCancelados} › ${t.menuTemporales}')),
      body: conDatos(t, (todas) {
        final lista = todas.where((r) => enZona(r.zonaId)).toList();
        return listaDelPeriodo(t, [
          ...encabezadoDeZona(
            t,
            todas: todas.map((r) => r.zonaId),
            nombres: widget.nombresZonas,
            vacia: lista.isEmpty,
            icono: Icons.pause_circle_outline_rounded,
            textoVacio: t.tcVacio,
          ),
          for (var i = 0; i < lista.length; i++) _fila(t, lista[i], hoy, i),
        ]);
      }),
    );
  }

  Widget _fila(Textos t, Temporal r, String hoy, int posicion) {
    final colores = Theme.of(context).colorScheme;
    final luz = luzTemporal(r, hoy);
    final o = r.comoOrden;
    final lineas = [
      [
        r.estado == 'activo' ? t.tcActiva : (r.estado == 'reactivado' ? t.tcReactivada : r.estado),
        if (r.folio.isNotEmpty) r.folio,
        widget.nombresZonas[r.zonaId] ?? r.zonaId,
        if (r.dia.isNotEmpty) fechaCorta(context, r.dia),
      ].where((x) => x.isNotEmpty).join(' · '),
      if (r.regreso.isNotEmpty) t.tcRegresa(fechaCorta(context, r.regreso)),
      if (r.recogeModem) r.estadoModem == 'recuperado' ? t.defModemRecuperado : t.tcRecogerModem(r.modem),
      if (r.motivo.isNotEmpty) r.motivo,
    ];
    return Aparecer(
      orden: posicion,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Superficie(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.nombre.isEmpty ? t.sinNombre : r.nombre,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              for (final l in lineas) Text(l, style: Theme.of(context).textTheme.bodySmall),
              if (luz != LuzTemporal.ninguna)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: luz == LuzTemporal.vencida ? colores.error : colores.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        luz == LuzTemporal.vencida ? t.tcVencida : t.tcPronto,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: luz == LuzTemporal.vencida ? colores.error : colores.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(children: [...botonesLlamarYMapa(context, o)]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nuevos Servicios › Eliminar factura del ISP: servicios nuevos instalados esos días que ya pagaron al instalarse; se
/// marca cuando ya se eliminó en el ISP la factura de su primer pago (y se puede deshacer).
class PantallaFacturaIsp extends StatefulWidget {
  const PantallaFacturaIsp({super.key, required this.tecnico, required this.servicio, required this.nombresZonas});

  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaFacturaIsp> createState() => _PantallaFacturaIspState();
}

class _PantallaFacturaIspState extends State<PantallaFacturaIsp>
    with
        LecturaPorPeriodo<PantallaFacturaIsp, ({List<Orden> ordenes, List<FechaPago> fechas, Catalogos cat})>,
        FiltroDeZona<PantallaFacturaIsp> {
  late final _tarjetas = _Tarjetas(widget.tecnico, widget.servicio, widget.nombresZonas);
  bool _hechas = false;
  final _enCurso = <String>{};

  @override
  void initState() {
    super.initState();
    // como la web (`ifaMonthStart`): de entrada, las instaladas desde el día 1 del mes pasado hasta hoy
    final hoy = DateTime.now();
    periodo = (desde: DateTime(hoy.year, hoy.month - 1), hasta: DateTime(hoy.year, hoy.month, hoy.day));
  }

  @override
  Future<({List<Orden> ordenes, List<FechaPago> fechas, Catalogos cat})> leer({bool recargar = false}) async {
    final r = await Future.wait<Object>([
      widget.servicio.ordenesPorFecha('completedAt', periodo, recargar: recargar),
      widget.servicio.fechasDePago(recargar: recargar),
      widget.servicio.catalogos(),
    ]);
    return (ordenes: r[0] as List<Orden>, fechas: r[1] as List<FechaPago>, cat: r[2] as Catalogos);
  }

  Future<void> _marcar(FilaFactura f, bool hecha) async {
    final t = Textos.of(context);
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _enCurso.add(f.orden.id));
    try {
      final enLinea = await widget.servicio.marcarFacturaIsp(f, widget.tecnico, hecha: hecha);
      if (!enLinea || hecha) avisos.showSnackBar(SnackBar(content: Text(enLinea ? t.ifaGuardada : t.sinSenal)));
      // solo cambia esa fila en lo ya leído (no se vuelve a leer todo el periodo)
      if (mounted) {
        setState(() => hecha ? f.orden.datos['ispInvoice'] = {'done': true} : f.orden.datos.remove('ispInvoice'));
      }
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(textoDeError(t, e))));
    } finally {
      if (mounted) setState(() => _enCurso.remove(f.orden.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${t.menuNuevosServicios} › ${t.menuFacturaIsp}')),
      body: conDatos(t, (d) {
        final todas = filasFactura(d.ordenes, d.fechas, d.cat);
        final lista = [
          for (final f in todas)
            if (f.hecha == _hechas && enZona(f.orden.zonaId)) f,
        ];
        return listaDelPeriodo(t, [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(t.ifaExplica, style: Theme.of(context).textTheme.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(t.ifaPendientes)),
                ButtonSegment(value: true, label: Text(t.ifaHechas)),
              ],
              selected: {_hechas},
              onSelectionChanged: (s) => setState(() => _hechas = s.first),
            ),
          ),
          ...encabezadoDeZona(
            t,
            todas: todas.map((f) => f.orden.zonaId),
            nombres: widget.nombresZonas,
            vacia: d.fechas.isEmpty || lista.isEmpty,
            icono: d.fechas.isEmpty ? Icons.event_busy_rounded : Icons.receipt_long_rounded,
            textoVacio: d.fechas.isEmpty ? t.ifaSinFechas : t.ifaVacio,
          ),
          for (var i = 0; i < lista.length; i++) _fila(t, lista[i], i),
        ]);
      }),
    );
  }

  Widget _fila(Textos t, FilaFactura f, int posicion) {
    final ocupado = _enCurso.contains(f.orden.id);
    return Column(
      children: [
        _tarjetas.de(
          context,
          f.orden,
          posicion,
          'factura',
          nota: [
            t.ifaFactura(fechaCorta(context, f.ciclo.factura)),
            t.ifaPago(fechaCorta(context, f.ciclo.pagoInicio), fechaCorta(context, f.ciclo.pagoFin)),
          ].join(' · '),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: ocupado
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : f.hecha
                ? TextButton.icon(
                    onPressed: () => _marcar(f, false),
                    icon: const Icon(Icons.undo_rounded),
                    label: Text(t.ifaDeshacer),
                  )
                : FilledButton.icon(
                    onPressed: () => _marcar(f, true),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: Text(t.ifaMarcar),
                  ),
          ),
        ),
      ],
    );
  }
}
