import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/modems.dart';
import '../logica/nueva_orden.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'diseno.dart';

/// Recuperar Módem › Definitivos de la web, en el teléfono: clientes que cancelaron y el módem que hay que traer.
/// El técnico ve los de sus localidades y los que le asignaron; toca «Me lo llevo» y, al traerlo, «Ya lo recuperé»
/// (la web le cuenta su comisión al momento). El administrador además asigna a quien quiera; el de consulta solo ve.
class PantallaModems extends StatefulWidget {
  const PantallaModems({
    super.key,
    required this.tecnico,
    required this.servicio,
    required this.nombresZonas,
    required this.doblePlay,
  });

  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  /// Recuperar Módem › Doble Play (true) o › Internet (false), como los dos submenús de la web.
  final bool doblePlay;

  @override
  State<PantallaModems> createState() => _PantallaModemsState();
}

enum _Ver { sinAsignar, asignados, todos }

class _PantallaModemsState extends State<PantallaModems> {
  // la misma escucha de siempre, separada por tipo de equipo en el teléfono (no cuesta lecturas de más)
  late final Stream<List<Orden>> _modems = widget.servicio
      .modemsPorRecuperar(widget.tecnico)
      .map((l) => l.where((o) => esDoblePlay(o) == widget.doblePlay).toList());
  List<Map<String, dynamic>> _comisiones = const [];
  final _enCurso = <String>{};
  String? _zona;
  _Ver _ver = _Ver.todos;

  Tecnico get _yo => widget.tecnico;

  @override
  void initState() {
    super.initState();
    widget.servicio
        .comisiones()
        .then((c) {
          if (mounted) setState(() => _comisiones = c);
        })
        .catchError((_) {
          // sin catálogo solo no se ve cuánto se gana
        });
  }

  bool _entra(Orden o, _Ver v) => switch (v) {
    _Ver.sinAsignar => estadoModem(o) == EstadoModem.sinAsignar,
    _Ver.asignados => estadoModem(o) == EstadoModem.asignado,
    _Ver.todos => true,
  };

  Future<void> _hacer(Orden o, Future<Object?> Function() accion, String listo) async {
    final t = Textos.of(context);
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _enCurso.add(o.id));
    try {
      final r = await accion();
      avisos.showSnackBar(SnackBar(content: Text(r == false ? t.sinSenal : listo)));
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(textoDeError(t, e))));
    } finally {
      if (mounted) setState(() => _enCurso.remove(o.id));
    }
  }

  void _soltar(Orden o) =>
      _hacer(o, () => widget.servicio.asignarModem(o, '', '', _yo), Textos.of(context).modemSoltado);

  Future<void> _recuperado(Orden o) async {
    final t = Textos.of(context);
    final gana = comisionDeModem(o, _comisiones);
    final si = await confirmar(
      context,
      icono: Icons.inventory_2_rounded,
      titulo: t.modemRecuperadoPregunta,
      texto: [
        t.modemRecuperadoTexto(o.cliente.isEmpty ? t.sinNombre : o.cliente),
        if (gana != null) t.modemGanas(dinero(context, gana)),
      ].join('\n\n'),
      boton: t.modemYaLoRecupere,
    );
    if (si && mounted) _hacer(o, () => widget.servicio.recuperarModem(o, _yo), t.modemRecuperadoOk);
  }

  /// El administrador elige qué comisionista va por el módem (Sistema › Comisionistas de esa localidad): él cobra la
  /// comisión, como en Recuperar Módem › Definitivos de la web.
  Future<void> _asignar(Orden o) async {
    final t = Textos.of(context);
    final List<Comisionista> comisionistas;
    try {
      comisionistas =
          (await widget.servicio.catalogosOrden())
              // sin localidad en la orden, todos (como cmrRecFor de la web); sin nombre no se listan
              .comisionistas
              .where((c) => c.nombre.isNotEmpty && c.atiende(o.zonaId.isEmpty ? null : o.zonaId))
              .toList()
            ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(textoDeError(t, e))));
      return;
    }
    if (!mounted) return;
    final elegido = await showModalBottomSheet<Comisionista?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(t.modemQuienRecupera, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (recuperaId(o).isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.person_off_outlined),
                  title: Text(t.modemSinAsignar),
                  onTap: () => Navigator.pop(context, const Comisionista('', '', [], [])),
                ),
              for (final u in comisionistas)
                ListTile(
                  leading: CircleAvatar(child: Text(u.nombre.isEmpty ? '?' : u.nombre.characters.first.toUpperCase())),
                  title: Text(u.nombre.isEmpty ? u.id : u.nombre),
                  trailing: u.id == recuperaId(o) ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.pop(context, u),
                ),
            ],
          ),
        ),
      ),
    );
    if (elegido == null || !mounted) return;
    _hacer(
      o,
      () => widget.servicio.asignarModem(o, elegido.id, elegido.nombre, _yo),
      elegido.id.isEmpty ? t.modemSoltado : t.modemAsignadoA(elegido.nombre),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return StreamBuilder<List<Orden>>(
      stream: _modems,
      builder: (context, foto) {
        final orden = widget.nombresZonas.keys.toList();
        int lugar(String id) => orden.contains(id) ? orden.indexOf(id) : orden.length;
        final todos = [...?foto.data]
          ..sort((a, b) {
            final z = lugar(a.zonaId).compareTo(lugar(b.zonaId));
            return z != 0 ? z : b.dia.compareTo(a.dia);
          });
        final zonas = [
          for (final z in orden)
            if (todos.any((o) => o.zonaId == z)) z,
        ];
        final zona = zonas.contains(_zona) ? _zona : null;
        final deZona = [
          for (final o in todos)
            if (zona == null || o.zonaId == zona) o,
        ];
        final lista = [
          for (final o in deZona)
            if (_entra(o, _ver)) o,
        ];
        final Widget cuerpo;
        final cargando = cargaOError(t, foto);
        if (cargando != null) {
          cuerpo = cargando;
        } else if (lista.isEmpty) {
          cuerpo = AvisoCentral(
            icono: Icons.inventory_2_outlined,
            texto: todos.isEmpty ? t.modemVacio : t.modemVacioFiltro,
          );
        } else {
          cuerpo = ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 32),
            itemCount: lista.length,
            itemBuilder: (context, i) => _tarjeta(t, lista[i], i, verZona: zona == null && zonas.length > 1),
          );
        }
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [_encabezado(t, deZona, zonas, zona)],
            body: cuerpo,
          ),
        );
      },
    );
  }

  Widget _encabezado(Textos t, List<Orden> deZona, List<String> zonas, String? zona) {
    final conFiltro = zonas.length > 1;
    int cuantos(_Ver v) => deZona.where((o) => _entra(o, v)).length;
    Widget total(String texto, _Ver v, Color color) => TotalCristal(
      texto: texto,
      cuantas: cuantos(v),
      color: color,
      elegido: _ver == v,
      alTocar: () => setState(() => _ver = v),
    );
    return encabezadoAzul(
      alto: 236 + (conFiltro ? 56 : 0),
      titulo: Text(widget.doblePlay ? t.modemTituloDoblePlay : t.modemTituloInternet),
      abajo: filtroSiHayVarias(
        t,
        zonas: zonas,
        nombres: widget.nombresZonas,
        elegida: zona,
        alElegir: (z) => setState(() => _zona = z),
      ),
      relleno: EdgeInsets.fromLTRB(20, kToolbarHeight + 4, 20, conFiltro ? 64 : 18),
      contenido: [
        Text(t.modemDescripcion, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3)),
        const SizedBox(height: 14),
        Row(
          children: [
            total(t.modemSinAsignar, _Ver.sinAsignar, const Color(0xFFFBBF24)),
            const SizedBox(width: 8),
            total(t.modemAsignados, _Ver.asignados, const Color(0xFF818CF8)),
            const SizedBox(width: 8),
            total(t.ipsTodas, _Ver.todos, Colors.white),
          ],
        ),
      ],
    );
  }

  Widget _tarjeta(Textos t, Orden o, int posicion, {required bool verZona}) {
    final colores = Theme.of(context).colorScheme;
    final st = estadoModem(o);
    final doble = esDoblePlay(o);
    final color = doble ? const Color(0xFF7C3AED) : const Color(0xFF0284C7);
    final gana = comisionDeModem(o, _comisiones);
    final mio = recuperaId(o) == _yo.userId;
    final ocupado = _enCurso.contains(o.id);
    final telefono = llamarA(o), mapa = mapaDe(o);
    final motivo = motivoBaja(o);
    final estado = switch (st) {
      EstadoModem.sinAsignar => (t.modemSinAsignar, const Color(0xFF64748B), Icons.radio_button_unchecked_rounded),
      _ when mio => (t.modemLoRecuperasTu, const Color(0xFF0EA5E9), Icons.directions_run_rounded),
      _ => (t.modemLoRecupera(recuperaNombre(o)), const Color(0xFFD97706), Icons.hourglass_top_rounded),
    };
    return Aparecer(
      orden: posicion,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Superficie(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(colors: [color.withValues(alpha: 0.85), color]),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: -3)],
                    ),
                    child: Icon(doble ? Icons.tv_rounded : Icons.router_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClienteYDetalle(
                      orden: o,
                      tamano: 16,
                      detalle: [
                        doble ? t.modemDoblePlay : t.modemInternet,
                        if (o.folio.isNotEmpty) o.folio,
                        if (verZona) widget.nombresZonas[o.zonaId] ?? o.zonaId,
                      ].join(' · '),
                    ),
                  ),
                ],
              ),
              if (o.direccion.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined, size: 18, color: colores.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(o.direccion, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ],
              if (motivo.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: colores.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(motivo, style: TextStyle(fontSize: 13.5, color: colores.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Pildora(icono: estado.$3, texto: estado.$1, color: estado.$2),
                  if (gana != null)
                    _Pildora(
                      icono: Icons.payments_rounded,
                      texto: t.modemComision(dinero(context, gana)),
                      color: const Color(0xFF059669),
                    ),
                ],
              ),
              const Divider(height: 22),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: t.llamar,
                    onPressed: telefono == null ? null : () => abrirFuera(context, telefono),
                    icon: const Icon(Icons.phone_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: t.verEnMapa,
                    onPressed: mapa == null ? null : () => abrirFuera(context, mapa),
                    icon: const Icon(Icons.near_me_rounded),
                  ),
                  const Spacer(),
                  if (ocupado)
                    const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5))
                  else
                    ..._acciones(t, o, st, mio),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _acciones(Textos t, Orden o, EstadoModem st, bool mio) {
    if (_yo.soloMirar) return const [];
    final asignar = _yo.esAdmin
        ? IconButton(
            tooltip: t.modemAsignar,
            onPressed: () => _asignar(o),
            icon: const Icon(Icons.person_add_alt_rounded),
          )
        : null;
    // sin asignar: solo el administrador elige al comisionista; las que quedaron a nombre de un técnico (de antes) las
    // puede soltar o marcar él mismo
    if (st == EstadoModem.sinAsignar) return [?asignar];
    if (!mio && !_yo.esAdmin) return const [];
    return [
      if (asignar != null) asignar else TextButton(onPressed: () => _soltar(o), child: Text(t.modemSoltar)),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
        onPressed: () => _recuperado(o),
        icon: const Icon(Icons.inventory_2_rounded, size: 18),
        label: Text(t.modemYaLoRecupere),
      ),
    ];
  }
}

class _Pildora extends StatelessWidget {
  const _Pildora({required this.icono, required this.texto, required this.color});

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
