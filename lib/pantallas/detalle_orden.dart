import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/textos.dart';
import '../logica/cobro.dart';
import '../logica/inconclusas.dart';
import '../logica/materiales.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'cobro.dart';
import 'diseno.dart';
import 'form_orden.dart';
import 'fotos_orden.dart';
import 'inconclusas.dart';
import 'materiales.dart';

/// Todos los datos de una orden, en vivo, con lo que el técnico puede hacer: aceptarla, empezar, comentar y terminar.
/// El administrador además la edita o la elimina (a la Papelera de la web); el de consulta solo la ve.
/// Abre el detalle de una orden desde cualquier lista.
Future<void> abrirDetalle(
  BuildContext context,
  Orden o, {
  required String hero,
  required Tecnico tecnico,
  required ServicioOrdenes servicio,
  required Map<String, String> zonas,
}) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PantallaDetalleOrden(orden: o, zonas: zonas, tecnico: tecnico, servicio: servicio, hero: hero),
  ),
);

/// Lo que devuelve el detalle al cerrarse, para que la lista sepa qué pasó.
enum ResultadoDetalle { aceptada }

class PantallaDetalleOrden extends StatefulWidget {
  const PantallaDetalleOrden({
    super.key,
    required this.orden,
    required this.zonas,
    required this.tecnico,
    required this.servicio,
    required this.hero,
  });

  final Orden orden;
  final Map<String, String> zonas;
  final Tecnico tecnico;
  final ServicioOrdenes servicio;

  /// Etiqueta del Hero del ícono de la tarjeta de la que se vino.
  final String hero;

  @override
  State<PantallaDetalleOrden> createState() => _PantallaDetalleOrdenState();
}

class _PantallaDetalleOrdenState extends State<PantallaDetalleOrden> {
  late final Stream<Orden> _orden = widget.servicio.orden(widget.orden.id);
  late final _comentarios = TextEditingController(text: widget.orden.comentariosTecnico);
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    // la lista de materiales se pide desde ahora, para tenerla aunque luego se vaya la señal
    widget.servicio.materiales().ignore();
  }

  @override
  void dispose() {
    _comentarios.dispose();
    super.dispose();
  }

  void _avisar(String texto) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Corre una acción mostrando que está ocupada; la acción devuelve `false` si quedó guardada para cuando haya señal.
  /// Devuelve `true` si la acción salió bien.
  Future<bool> _hacer(Future<bool> Function() accion, String listo) async {
    if (_ocupado) return false;
    final t = Textos.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _ocupado = true);
    try {
      final enLinea = await accion();
      HapticFeedback.mediumImpact();
      _avisar(enLinea ? listo : t.sinSenal);
      return true;
    } on ErrorDeOrden catch (e) {
      _avisar(textoFalloOrden(t, e));
    } catch (e) {
      _avisar(t.errOtro('$e'));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
    return false;
  }

  Future<bool> _confirmar(IconData icono, String titulo, String texto, String boton) =>
      confirmar(context, icono: icono, titulo: titulo, texto: texto, boton: boton);

  Future<void> _aceptar(Orden o) async {
    final t = Textos.of(context);
    if (!await _confirmar(Icons.how_to_reg_rounded, t.aceptarPregunta, t.aceptarTexto, t.aceptar)) return;
    final tomada = await _hacer(() async {
      await widget.servicio.tomar(o.id, widget.tecnico);
      return true;
    }, t.ordenAceptada);
    // ya es suya: se cierra el detalle y la pantalla principal pasa a «En proceso»
    if (tomada && mounted) Navigator.pop(context, ResultadoDetalle.aceptada);
  }

  Future<void> _terminar(Orden o) async {
    final t = Textos.of(context);
    if (_ocupado) return;
    setState(() => _ocupado = true);
    Catalogos catalogos;
    try {
      catalogos = await widget.servicio.catalogos();
    } catch (e) {
      _avisar(t.errSinInternet);
      return;
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
    if (!mounted) return;
    // los comentarios escritos y sin guardar se mandan junto con el cobro
    final comentarios = _comentarios.text.trim() != o.comentariosTecnico ? _comentarios.text : null;
    final materiales = await _pedirMateriales(o, catalogos.servicios[o.datos['serviceType']]);
    if (materiales == null || !mounted) return;
    if (completaSinCobro(o, catalogos)) {
      if (!await _confirmar(Icons.task_alt_rounded, t.terminePregunta, t.terminarDirecto, t.siTermine)) return;
      await _hacer(
        () => widget.servicio.terminar(o, widget.tecnico, comentarios: comentarios, materiales: materiales),
        t.ordenCompletada,
      );
      if (mounted) Navigator.pop(context);
      return;
    }
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaCobro(
          orden: o,
          catalogos: catalogos,
          tecnico: widget.tecnico,
          servicio: widget.servicio,
          comentarios: comentarios,
          materiales: materiales,
        ),
      ),
    );
  }

  /// Si el servicio lleva materiales, la ventana de módem e insumos (como la web al completar). Devuelve lo que se guarda
  /// junto con la orden; sin materiales, solo quién la completó; null si se regresó sin continuar o no hubo señal.
  Future<Map<String, Object?>?> _pedirMateriales(Orden o, Map<String, dynamic>? servicio) async {
    final quien = datosMateriales(userId: widget.tecnico.userId, nombre: widget.tecnico.nombre);
    if (!pideMateriales(o, servicio)) return quien;
    final t = Textos.of(context);
    setState(() => _ocupado = true);
    CatalogoMateriales catalogo;
    try {
      catalogo = await widget.servicio.materiales();
    } catch (_) {
      // sin la lista (sin señal): se termina igual y la oficina anota el material en la web
      _avisar(t.matSinLista);
      return quien;
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
    if (!mounted) return null;
    return Navigator.push<Map<String, Object?>>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaMateriales(orden: o, servicio: servicio, catalogo: catalogo, tecnico: widget.tecnico),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return StreamBuilder<Orden>(
      stream: _orden,
      initialData: widget.orden,
      builder: (context, s) {
        final o = s.data!;
        final esMia = o.esDe(widget.tecnico.userId);
        final editable = esMia && !widget.tecnico.soloMirar && (o.estado == 'pendiente' || o.estado == 'en_proceso');
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _encabezado(t, o),
              SliverToBoxAdapter(child: _botonesRapidos(t, o)),
              SliverToBoxAdapter(child: _datos(t, o, esMia)),
              SliverToBoxAdapter(
                child: FotosOrden(
                  key: ValueKey('fotos-${o.id}'),
                  orden: o,
                  servicio: widget.servicio,
                  tecnico: widget.tecnico,
                  puedeCambiar: !widget.tecnico.soloMirar && (widget.tecnico.esAdmin || esMia),
                ),
              ),
              if (editable) SliverToBoxAdapter(child: _misComentarios(t, o)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          bottomNavigationBar: _barraAcciones(t, o),
        );
      },
    );
  }

  Widget _encabezado(Textos t, Orden o) {
    return encabezadoAzul(
      alto: 230,
      titulo: Text(o.folio.isEmpty ? t.orden : t.folio(o.folio)),
      acciones: widget.tecnico.esAdmin ? [_menuAdmin(t, o)] : null,
      relleno: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 22),
      contenido: [
        Row(
          children: [
            Hero(
              tag: widget.hero,
              child: IconoOrden(orden: o, tamano: 58, sobreOscuro: true),
            ),
            const Spacer(),
            EtiquetaEstado(orden: o, sobreOscuro: true),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          o.cliente.isEmpty ? t.sinNombre : o.cliente,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [o.servicio, widget.zonas[o.zonaId] ?? o.zonaId].where((x) => x.isNotEmpty).join(' · '),
          style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 15),
        ),
      ],
    );
  }

  /// Editar o eliminar: solo el administrador, en cualquier estado.
  Widget _menuAdmin(Textos t, Orden o) => PopupMenuButton<bool>(
    icon: const Icon(Icons.more_vert_rounded),
    enabled: !_ocupado,
    onSelected: (eliminar) => eliminar ? _eliminar(o) : _editar(o),
    itemBuilder: (context) => [
      PopupMenuItem(
        value: false,
        child: ListTile(leading: const Icon(Icons.edit_rounded), title: Text(t.menuEditar)),
      ),
      PopupMenuItem(
        value: true,
        child: ListTile(
          leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
          title: Text(t.menuEliminar, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ),
    ],
  );

  Future<void> _editar(Orden o) async {
    final t = Textos.of(context);
    final guardado = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PantallaFormOrden(tecnico: widget.tecnico, servicio: widget.servicio, nombresZonas: widget.zonas, orden: o),
      ),
    );
    if (guardado == true) _avisar(t.ordenGuardada);
  }

  Future<void> _eliminar(Orden o) async {
    final t = Textos.of(context);
    final si = await confirmar(
      context,
      icono: Icons.delete_outline_rounded,
      titulo: t.eliminarPregunta(o.folio.isEmpty ? o.cliente : o.folio),
      texto: t.eliminarTexto,
      boton: t.menuEliminar,
    );
    if (!si || !mounted) return;
    final avisos = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    setState(() => _ocupado = true);
    try {
      await widget.servicio.eliminar(o, widget.tecnico);
      navegador.pop();
      avisos.showSnackBar(SnackBar(content: Text(t.ordenEliminada)));
    } on ErrorDeOrden catch (e) {
      _avisar(textoFalloOrden(t, e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Widget _botonesRapidos(Textos t, Orden o) {
    final telefono = llamarA(o), mapa = mapaDe(o);
    return Aparecer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: _BotonRapido(
                icono: Icons.phone_rounded,
                texto: t.llamar,
                color: const Color(0xFF10B981),
                alTocar: telefono == null ? null : () => abrirFuera(context, telefono),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BotonRapido(
                icono: Icons.near_me_rounded,
                texto: t.verEnMapa,
                color: Marca.azul,
                alTocar: mapa == null ? null : () => abrirFuera(context, mapa),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datos(Textos t, Orden o, bool esMia) {
    final cuando = [fechaCorta(context, o.dia), o.hora].where((x) => x.isNotEmpty).join(' · ');
    final completada = o.completadaEn;
    final filas = [
      (Icons.phone_outlined, t.telefono, o.telefono),
      (Icons.place_outlined, t.direccion, o.direccion),
      (Icons.map_outlined, t.localidad, widget.zonas[o.zonaId] ?? o.zonaId),
      (Icons.handyman_outlined, t.servicio, o.servicio),
      (Icons.event_outlined, t.diaServicio, cuando),
      if (!esMia) (Icons.engineering_outlined, t.tecnico, o.tecnicoNombre),
      if (completada != null && o.estado == 'completada')
        (Icons.check_circle_outline, t.estCompletada, fechaHora(context, completada)),
    ].where((f) => f.$3.isNotEmpty).toList();
    final colores = Theme.of(context).colorScheme;
    return Column(
      children: [
        Aparecer(
          orden: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Superficie(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < filas.length; i++) ...[
                    if (i > 0) Divider(height: 1, indent: 60, color: colores.outlineVariant.withValues(alpha: 0.5)),
                    _Fila(icono: filas[i].$1, titulo: filas[i].$2, valor: filas[i].$3),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (o.notaOficina.isNotEmpty)
          _Bloque(
            orden: 2,
            icono: Icons.sticky_note_2_outlined,
            titulo: t.notaOficina,
            texto: o.notaOficina,
            color: const Color(0xFFF59E0B),
          ),
        if (o.descripcion.isNotEmpty)
          _Bloque(
            orden: 3,
            icono: Icons.description_outlined,
            titulo: t.descripcion,
            texto: o.descripcion,
            color: colores.primary,
          ),
        // los comentarios propios se editan abajo
        if ((!esMia || o.estado == 'completada') && o.comentariosTecnico.isNotEmpty)
          _Bloque(
            orden: 4,
            icono: Icons.forum_outlined,
            titulo: t.comentariosTecnico,
            texto: o.comentariosTecnico,
            color: const Color(0xFF6366F1),
          ),
      ],
    );
  }

  Widget _misComentarios(Textos t, Orden o) {
    final yo = widget.tecnico;
    return Aparecer(
      orden: 5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Superficie(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Encabezadito(
                icono: Icons.edit_note_rounded,
                texto: t.misComentarios,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextField(
                  controller: _comentarios,
                  minLines: 3,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  onPressed: _ocupado
                      ? null
                      : () => _hacer(
                          () => widget.servicio.guardarComentarios(o, _comentarios.text, yo),
                          t.comentariosGuardados,
                        ),
                  label: Text(t.guardarComentarios),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Completada: se puede marcar inconclusa (si quedó algo pendiente); si ya lo está, su fecha de regreso y motivo, con
  /// «Cambiar» y «Resolver». Lo hacen los que procesan órdenes (no los de consulta), como en la web.
  Widget _barraCompletada(Textos t, Orden o) {
    final yo = widget.tecnico;
    // como `incCanEdit` de la web: cualquiera que procese órdenes (no los de consulta)
    final puede = !yo.soloMirar;
    void marcar() => marcarInconclusa(context, o, widget.servicio, yo);
    if (!esInconclusa(o)) {
      return Row(
        children: [
          Expanded(
            child: _Info(icono: Icons.verified_rounded, texto: t.msgCompletada, color: const Color(0xFF10B981)),
          ),
          if (puede)
            TextButton.icon(
              onPressed: _ocupado ? null : marcar,
              icon: const Icon(Icons.flag_outlined),
              label: Text(t.incMarcar),
            ),
        ],
      );
    }
    final dia = fechaRegreso(o);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Info(
          icono: Icons.flag_rounded,
          texto: [
            dia.isEmpty ? t.incSinFecha : t.incVuelve(fechaCorta(context, dia)),
            motivoInconclusa(o),
          ].where((x) => x.isNotEmpty).join(' · '),
          color: const Color(0xFFEA580C),
        ),
        if (puede) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  onPressed: _ocupado ? null : marcar,
                  child: Text(t.incCambiar),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: BotonPrincipal(
                  icono: Icons.task_alt_rounded,
                  texto: t.incResolver,
                  ocupado: _ocupado,
                  alTocar: () => _resolverInconclusa(o),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _resolverInconclusa(Orden o) async {
    final t = Textos.of(context);
    final si = await confirmar(
      context,
      icono: Icons.task_alt_rounded,
      titulo: t.incResolverPregunta,
      texto: t.incResolverTexto(o.folio.isEmpty ? o.cliente : o.folio),
      boton: t.incResolver,
    );
    if (si && mounted) await _hacer(() => widget.servicio.resolverInconclusa(o, widget.tecnico), t.incResuelta);
  }

  /// Barra fija de abajo con la acción que toca según el estado de la orden.
  Widget? _barraAcciones(Textos t, Orden o) {
    final abierta = o.estado == 'pendiente' || o.estado == 'en_proceso';
    final yo = widget.tecnico;
    final Widget contenido;
    if (o.estado == 'cancelada') {
      contenido = _Info(icono: Icons.block_rounded, texto: t.msgCancelada, color: const Color(0xFFF43F5E));
    } else if (o.estado == 'completada') {
      contenido = _barraCompletada(t, o);
    } else if (yo.soloMirar) {
      contenido = _Info(icono: Icons.visibility_rounded, texto: t.msgSoloConsulta, color: const Color(0xFF64748B));
    } else if (!o.tieneTecnico && abierta) {
      contenido = BotonPrincipal(
        icono: Icons.how_to_reg_rounded,
        texto: t.aceptarOrden,
        ocupado: _ocupado,
        alTocar: () => _aceptar(o),
      );
    } else if (!o.esDe(yo.userId)) {
      contenido = _Info(
        icono: Icons.engineering_rounded,
        texto: t.msgOtroTecnico(o.tecnicoNombre.isEmpty ? t.otroTecnicoSinNombre : o.tecnicoNombre),
        color: const Color(0xFF6366F1),
      );
    } else if (o.esperaAutorizacion) {
      contenido = _Info(icono: Icons.hourglass_top_rounded, texto: t.msgPorAutorizar, color: const Color(0xFFF59E0B));
    } else if (o.avisoTerminada) {
      contenido = _Info(
        icono: Icons.account_balance_rounded,
        texto: t.msgTransferencia,
        color: const Color(0xFF0D9488),
      );
    } else {
      contenido = Row(
        children: [
          if (!o.iniciada) ...[
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(t.empezar),
                onPressed: _ocupado ? null : () => _hacer(() => widget.servicio.empezar(o, yo), t.marcasteInicio),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: BotonPrincipal(
              icono: Icons.task_alt_rounded,
              texto: t.termine,
              ocupado: _ocupado,
              alTocar: () => _terminar(o),
            ),
          ),
        ],
      );
    }
    return BarraInferior(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey('${o.estado}${o.avisoTerminada}${o.iniciada}${o.esperaAutorizacion}${esInconclusa(o)}'),
          child: contenido,
        ),
      ),
    );
  }
}

/// Botón cuadrado elevado (Llamar, Ver en mapa).
class _BotonRapido extends StatelessWidget {
  const _BotonRapido({required this.icono, required this.texto, required this.color, required this.alTocar});

  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final activo = alTocar != null;
    return Opacity(
      opacity: activo ? 1 : 0.45,
      child: Superficie(
        nivel: 2,
        child: Presionable(
          alTocar: alTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.9), color]),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Icon(icono, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 8),
                Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.icono, required this.titulo, required this.valor});

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colores.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 18, color: colores.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colores.onSurfaceVariant)),
                const SizedBox(height: 1),
                SelectableText(
                  valor,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Encabezadito extends StatelessWidget {
  const _Encabezadito({required this.icono, required this.texto, required this.color});

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
        ),
      ],
    );
  }
}

/// Bloque de texto con una franja de color (nota de la oficina, descripción, comentarios).
class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.orden,
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.color,
  });

  final int orden;
  final IconData icono;
  final String titulo;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Aparecer(
      orden: orden,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Superficie(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Encabezadito(icono: icono, texto: titulo, color: color),
                          const SizedBox(height: 8),
                          SelectableText(texto, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso en la barra de abajo cuando no hay nada que hacer.
class _Info extends StatelessWidget {
  const _Info({required this.icono, required this.texto, required this.color});

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
