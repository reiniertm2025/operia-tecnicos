import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/textos.dart';
import '../logica/errores.dart';
import '../logica/fechas.dart';
import '../logica/orden.dart';
import '../servicios/sesion.dart';
import '../logica/tablero.dart';
import '../servicios/ordenes.dart';
import 'diseno.dart';

/// Piezas que usan varias pantallas: etiqueta de estado, fechas, mensajes de error, tarjeta de orden y avisos.

/// Nombre del estado en el idioma de la app.
String nombreEstado(Textos t, Orden o) => switch (o.estado) {
  _ when o.esperaAutorizacion && o.estado == 'en_proceso' => t.estPorAutorizar,
  _ when o.avisoTerminada && o.estado == 'en_proceso' => t.estFaltaCobro,
  'pendiente' => t.estPendiente,
  'en_proceso' => t.estEnProceso,
  'completada' => t.estCompletada,
  'cancelada' => t.estCancelada,
  final otro => otro,
};

/// Etiqueta de color con el estado de la orden (mismos colores que la web), con un punto que late si está en proceso.
class EtiquetaEstado extends StatelessWidget {
  const EtiquetaEstado({super.key, required this.orden, this.sobreOscuro = false});

  final Orden orden;

  /// En los encabezados azules: fondo blanco translúcido.
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(orden);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: sobreOscuro ? Colors.white.withValues(alpha: 0.14) : color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: sobreOscuro ? 0.7 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Punto(color: color, late: orden.estado == 'en_proceso'),
          const SizedBox(width: 6),
          Text(
            nombreEstado(Textos.of(context), orden),
            style: TextStyle(color: sobreOscuro ? Colors.white : color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Punto extends StatefulWidget {
  const _Punto({required this.color, required this.late});
  final Color color;
  final bool late;

  @override
  State<_Punto> createState() => _PuntoState();
}

class _PuntoState extends State<_Punto> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.late) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Punto viejo) {
    super.didUpdateWidget(viejo);
    if (widget.late && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.late && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6 * _c.value),
              blurRadius: 6,
              spreadRadius: 2 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ventana para confirmar una acción; devuelve true si se tocó `boton`.
Future<bool> confirmar(
  BuildContext context, {
  required IconData icono,
  required String titulo,
  required String texto,
  required String boton,
}) async {
  final t = Textos.of(context);
  final si = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(icono),
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancelar)),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(boton),
        ),
      ],
    ),
  );
  return si == true;
}

/// «2026-11-02» → «2 nov» (o «Nov 2» en inglés).
String fechaCorta(BuildContext context, String dia) {
  final d = DateTime.tryParse(dia);
  if (d == null) return dia;
  return DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(d);
}

/// Fecha y hora cortas en el idioma de la app.
String fechaHora(BuildContext context, DateTime d) =>
    DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(d);

String textoFalloSesion(Textos t, ErrorDeSesion e) => switch (e.fallo) {
  FalloSesion.faltanDatos => t.errFaltanDatos,
  FalloSesion.datosIncorrectos => t.errDatosIncorrectos,
  FalloSesion.tipoDesconocido => t.errTipoDesconocido(e.detalle),
  FalloSesion.sinAccesoApp => t.errSinAccesoApp,
  FalloSesion.cuentaDesactivada => t.errCuentaDesactivada,
  FalloSesion.demasiadosIntentos => t.errDemasiadosIntentos,
  FalloSesion.sinInternet => t.errSinInternet,
  FalloSesion.otro => t.errOtro(e.detalle),
};

String textoFalloOrden(Textos t, ErrorDeOrden e) => switch (e.fallo) {
  FalloOrden.yaTomada => t.errYaTomada,
  FalloOrden.ipOcupada => t.errIpOcupada,
  FalloOrden.sinInternet => t.errSinInternet,
  FalloOrden.sinPermiso => t.errSinPermiso,
  FalloOrden.otro => t.errOtro(e.detalle),
};

/// Importe en pesos en el idioma de la app («$1,250.00»).
String dinero(BuildContext context, double v) =>
    NumberFormat.currency(locale: Localizations.localeOf(context).toLanguageTag(), symbol: r'$').format(v);

/// Marcar al cliente; null si la orden no trae teléfono.
Uri? llamarA(Orden o) {
  final tel = o.telefono.replaceAll(RegExp(r'[^\d+]'), '');
  return tel.isEmpty ? null : Uri(scheme: 'tel', path: tel);
}

/// Google Maps en las coordenadas (o la dirección); null si no hay ninguna.
Uri? mapaDe(Orden o) {
  final u = o.ubicacion;
  final destino = u != null ? '${u.lat},${u.lng}' : o.direccion;
  return destino.isEmpty ? null : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': destino});
}

/// Abre el enlace en otra app (teléfono, mapas); si no se puede, lo avisa.
Future<void> abrirFuera(BuildContext context, Uri direccion) async {
  final t = Textos.of(context);
  final avisos = ScaffoldMessenger.of(context);
  var abierto = false;
  try {
    abierto = await launchUrl(direccion, mode: LaunchMode.externalApplication);
  } catch (_) {
    // se avisa abajo
  }
  if (!abierto) avisos.showSnackBar(SnackBar(content: Text(t.noSePudoAbrir)));
}

/// Mensaje de cualquier error al guardar: los de Firebase en palabras claras; lo demás, con su detalle.
String textoDeError(Textos t, Object e) => switch (e) {
  ErrorDeOrden() => textoFalloOrden(t, e),
  FirebaseException(code: 'permission-denied') => t.errSinPermiso,
  FirebaseException(code: 'unavailable' || 'network-request-failed') => t.errSinInternet,
  _ => t.errOtro('$e'),
};

/// Error al cargar una lista: sin permiso o sin internet en palabras claras; lo demás, con su detalle.
String textoErrorCarga(Textos t, Object error) => switch (error) {
  FirebaseException(code: 'permission-denied') => t.errSinPermiso,
  FirebaseException(code: 'unavailable' || 'network-request-failed') => t.errSinInternet,
  _ => t.errorCargar('$error'),
};

/// Ícono del servicio en un cuadro del color del estado. Viaja (Hero) de la tarjeta al encabezado del detalle.
class IconoOrden extends StatelessWidget {
  const IconoOrden({super.key, required this.orden, this.tamano = 46, this.sobreOscuro = false});

  final Orden orden;
  final double tamano;
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(orden);
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamano * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: sobreOscuro
              ? [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.08)]
              : [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
        ),
        border: Border.all(color: sobreOscuro ? Colors.white24 : color.withValues(alpha: 0.25)),
      ),
      child: Icon(iconoServicio(orden), color: sobreOscuro ? Colors.white : color, size: tamano * 0.5),
    );
  }
}

/// Etiqueta para el Hero del ícono (incluye la pestaña: la misma orden no puede estar dos veces en pantalla).
String heroDe(String lugar, Orden o) => 'orden-$lugar-${o.id}';

/// Tarjeta de una orden en las listas.
class TarjetaOrden extends StatelessWidget {
  const TarjetaOrden({
    super.key,
    required this.orden,
    required this.zona,
    required this.alTocar,
    required this.hero,
    this.verTecnico = false,
    this.posicion = 0,
    this.nota = '',
  });

  final Orden orden;
  final String zona;
  final VoidCallback alTocar;
  final String hero;

  /// Una línea de aviso arriba del folio (por ejemplo, cuándo se regresa a una inconclusa).
  final String nota;

  /// El administrador ve de quién es cada orden.
  final bool verTecnico;

  /// Lugar en la lista, para escalonar la entrada.
  final int posicion;

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final textos = Theme.of(context).textTheme;
    final colores = Theme.of(context).colorScheme;
    final completada = orden.completadaEn;
    final cuando = completada != null && orden.estado == 'completada'
        ? fechaHora(context, completada)
        : [fechaCorta(context, orden.dia), orden.hora].where((x) => x.isNotEmpty).join(' · ');
    final tecnico = orden.tecnicoNombre.isNotEmpty ? orden.tecnicoNombre : (orden.tieneTecnico ? '' : t.sinTecnico);
    final suave = colores.onSurfaceVariant;
    return Aparecer(
      orden: posicion,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Superficie(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Presionable(
              alTocar: alTocar,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: colorEstado(orden)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: hero,
                                  child: IconoOrden(orden: orden),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orden.cliente.isEmpty ? t.sinNombre : orden.cliente,
                                        style: textos.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [orden.servicio, zona].where((x) => x.isNotEmpty).join(' · '),
                                        style: textos.bodyMedium?.copyWith(color: suave),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                EtiquetaEstado(orden: orden),
                              ],
                            ),
                            if (orden.direccion.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.place_outlined, size: 16, color: suave),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      orden.direccion,
                                      style: textos.bodySmall?.copyWith(color: suave),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (nota.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.flag_outlined, size: 16, color: colores.tertiary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      nota,
                                      style: textos.bodySmall?.copyWith(
                                        color: colores.tertiary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (orden.folio.isNotEmpty) ...[
                                  _Pastilla(texto: orden.folio, color: colores.primary),
                                  const SizedBox(width: 8),
                                ],
                                if (cuando.isNotEmpty) ...[
                                  Icon(
                                    orden.estado == 'completada' ? Icons.check_circle_outline : Icons.schedule,
                                    size: 15,
                                    color: suave,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      cuando,
                                      style: textos.labelMedium?.copyWith(color: suave),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                if (verTecnico && tecnico.isNotEmpty) ...[
                                  Icon(Icons.engineering_outlined, size: 16, color: suave),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 110),
                                    child: Text(
                                      tecnico,
                                      style: textos.labelMedium?.copyWith(color: suave),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
      ),
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({required this.texto, required this.color});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.3),
      ),
    );
  }
}

/// Mensaje grande en medio de la pantalla (lista vacía, error).
class AvisoCentral extends StatelessWidget {
  const AvisoCentral({super.key, required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Aparecer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colores.primary.withValues(alpha: 0.18), colores.primary.withValues(alpha: 0.04)],
                  ),
                ),
                child: Icon(icono, size: 44, color: colores.primary),
              ),
              const SizedBox(height: 20),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colores.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de localidades bajo el encabezado azul: «Todas» y cada una por su nombre.
PreferredSizeWidget filtroZonas(
  Textos t, {
  required List<String> zonas,
  required Map<String, String> nombres,
  required String? elegida,
  required ValueChanged<String?> alElegir,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(56),
    child: SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        children: [
          for (final id in <String?>[null, ...zonas])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChipFiltro(
                texto: id == null ? t.todas : (nombres[id] ?? id),
                elegido: elegida == id,
                alTocar: () => alElegir(id),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Fila de fechas que se desliza: Hoy, Esta semana, Este mes, Mes anterior y «Elegir fechas» (desde y hasta en el
/// calendario). Con `conTodas`, también «Todas las fechas» (rango null).
class BotonesFechas extends StatelessWidget {
  const BotonesFechas({super.key, required this.rango, required this.alElegir, this.conTodas = false});

  final RangoDias? rango;
  final ValueChanged<RangoDias?> alElegir;
  final bool conTodas;

  Future<void> _elegirFechas(BuildContext context) async {
    final hoy = DateTime.now();
    final actual = rango;
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoy.year + 1, 12, 31),
      initialDateRange: actual == null ? null : DateTimeRange(start: actual.desde, end: actual.hasta),
      helpText: Textos.of(context).histElegirFechas,
    );
    if (elegido != null) alElegir((desde: elegido.start, hasta: elegido.end));
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final ahora = DateTime.now();
    final r = rango;
    final rapido = rapidoDe(r, ahora);
    final aMano = r != null && rapido == null;
    final nombres = {
      RangoRapido.hoy: t.hoy,
      RangoRapido.semana: t.histSemana,
      RangoRapido.mes: t.histMes,
      RangoRapido.mesAnterior: t.histMesAnterior,
    };
    Widget chip(String texto, bool elegido, VoidCallback alTocar, {IconData? icono}) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: icono == null ? null : Icon(icono, size: 18),
        label: Text(texto),
        selected: elegido,
        onSelected: (_) => alTocar(),
      ),
    );
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
        children: [
          if (conTodas) chip(t.histTodasFechas, r == null, () => alElegir(null)),
          for (final MapEntry(key: q, value: texto) in nombres.entries)
            chip(texto, rapido == q, () => alElegir(rangoRapido(q, ahora))),
          chip(
            aMano
                ? {fechaCorta(context, textoDia(r.desde)), fechaCorta(context, textoDia(r.hasta))}.join(' – ')
                : t.histElegirFechas,
            aMano,
            () => _elegirFechas(context),
            icono: Icons.date_range_rounded,
          ),
        ],
      ),
    );
  }
}

/// Título de sección con su cantidad.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion({super.key, required this.texto, required this.cuantas, this.color});

  final String texto;
  final int cuantas;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          Flexible(
            child: Text(
              texto.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.1),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(
              '$cuantas',
              style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: c.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}

/// Mientras carga, tarjetas de muestra; si falló, el aviso; null cuando ya hay datos.
Widget? cargaOError(Textos t, AsyncSnapshot<Object?> foto) => foto.hasError
    ? AvisoCentral(icono: Icons.cloud_off_rounded, texto: textoErrorCarga(t, foto.error!))
    : (foto.data == null ? const ListaEsqueleto() : null);

/// Nombre del cliente en negritas y debajo una línea de detalle.
class ClienteYDetalle extends StatelessWidget {
  const ClienteYDetalle({super.key, required this.orden, required this.detalle, this.tamano = 15});

  final Orden orden;
  final String detalle;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          orden.cliente.isEmpty ? t.sinNombre : orden.cliente,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: tamano),
        ),
        Text(detalle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
      ],
    );
  }
}

/// Dato sobre el encabezado azul: valor grande de color y su nombre abajo.
class DatoCristal extends StatelessWidget {
  const DatoCristal({super.key, required this.texto, required this.valor, required this.color});

  final String texto;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valor,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
            Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Contenido del encabezado azul con un importe grande (que sube animado) y dos datos abajo.
List<Widget> importeConDatos(String titulo, double importe, DatoCristal izquierda, DatoCristal derecha) => [
  Text(titulo, style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 14)),
  TweenAnimationBuilder<double>(
    tween: Tween(end: importe),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        dinero(context, v),
        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
      ),
    ),
  ),
  const SizedBox(height: 12),
  Row(children: [izquierda, const SizedBox(width: 10), derecha]),
];

/// Lista que se recarga al jalarla hacia abajo.
Widget listaRecargable({required Future<void> Function() alRecargar, required List<Widget> children}) =>
    RefreshIndicator(
      onRefresh: alRecargar,
      child: ListView(padding: const EdgeInsets.only(bottom: 32), children: children),
    );

/// Formularios que guardan y se cierran: muestran «guardando» en el botón, avisan si no hubo señal (queda guardado en
/// el celular y se sube después) o el aviso de `listo`, y si algo falla dejan el error en pantalla sin cerrarse.
mixin GuardarYCerrar<W extends StatefulWidget> on State<W> {
  bool guardando = false;
  String? error;

  Future<void> guardarYCerrar(Future<bool> Function() accion, {String? Function()? listo}) async {
    if (guardando) return;
    final t = Textos.of(context);
    setState(() {
      guardando = true;
      error = null;
    });
    final navegador = Navigator.of(context);
    final avisos = ScaffoldMessenger.of(context);
    try {
      final enLinea = await accion();
      HapticFeedback.mediumImpact();
      final texto = enLinea ? listo?.call() : t.sinSenal;
      if (texto != null) avisos.showSnackBar(SnackBar(content: Text(texto)));
      // si ya salió del formulario mientras se guardaba, no se cierra la pantalla de abajo
      if (mounted) navegador.pop(true);
    } catch (e) {
      if (mounted) setState(() => error = textoDeError(t, e));
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }
}

/// Pantallas que leen una vez lo de un periodo (Hoy, Esta semana, Este mes, Mes anterior o las fechas que se elijan): al
/// cambiar el periodo vuelven a leer, y jalar la lista hacia abajo pide los datos otra vez.
mixin LecturaPorPeriodo<W extends StatefulWidget, D> on State<W> {
  RangoDias periodo = rangoRapido(RangoRapido.mes, DateTime.now());

  /// Lo que se leyó para el periodo; se fija al leer (no en cada dibujo, por si pasa la medianoche).
  late ({DateTime desde, DateTime hastaExclusivo}) rango;
  late Future<D> carga = leer();

  Future<D> leer({bool recargar = false});

  /// Fija `rango` con el periodo elegido; con `cortarEnHoy`, termina hoy (como el Dashboard de la web).
  ({DateTime desde, DateTime hastaExclusivo}) fijarRango({bool cortarEnHoy = true}) {
    final dias = cortarEnHoy ? hastaHoy(periodo, DateTime.now()) : periodo;
    return rango = (desde: dias.desde, hastaExclusivo: finDeRango(dias));
  }

  void elegirPeriodo(RangoDias? r) => setState(() {
    periodo = r ?? periodo;
    carga = leer();
  });

  /// Lo leído: si falló, el aviso (con los botones de fechas); mientras lee, el esqueleto.
  Widget conDatos(Textos t, Widget Function(D datos) hecho) => FutureBuilder<D>(
    future: carga,
    builder: (context, foto) {
      if (foto.hasError) return errorDelPeriodo(t, foto.error!);
      final d = foto.data;
      return d == null ? const ListaEsqueleto() : hecho(d);
    },
  );

  /// Si falló la lectura: el aviso, sin perder los botones de fechas ni el jalar para recargar.
  Widget errorDelPeriodo(Textos t, Object error) => listaDelPeriodo(t, [
    Padding(
      padding: const EdgeInsets.only(top: 40),
      child: AvisoCentral(icono: Icons.cloud_off_rounded, texto: textoErrorCarga(t, error)),
    ),
  ]);

  /// La lista con los botones de periodo arriba.
  Widget listaDelPeriodo(Textos t, List<Widget> children) => listaRecargable(
    alRecargar: () async {
      setState(() => carga = leer(recargar: true));
      await carga;
    },
    children: [
      BotonesFechas(rango: periodo, alElegir: elegirPeriodo),
      ...children,
    ],
  );
}

/// Filtro de localidades del encabezado azul, solo si hay más de una (null si no).
PreferredSizeWidget? filtroSiHayVarias(
  Textos t, {
  required List<String> zonas,
  required Map<String, String> nombres,
  required String? elegida,
  required ValueChanged<String?> alElegir,
}) => zonas.length > 1 ? filtroZonas(t, zonas: zonas, nombres: nombres, elegida: elegida, alElegir: alElegir) : null;

/// Escucha las órdenes abiertas y las culminadas de hoy, y arma el tablero con lo que le toca a quien entró.
class EscuchaTablero extends StatelessWidget {
  const EscuchaTablero({
    super.key,
    required this.tecnico,
    required this.abiertas,
    required this.culminadas,
    required this.builder,
    this.zona,
  });

  final Tecnico tecnico;
  final Stream<List<Orden>> abiertas;
  final Stream<List<Orden>> culminadas;
  final String? zona;
  final Widget Function(BuildContext context, Tablero tablero, ({bool cargando, Object? error}) estado) builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Orden>>(
    stream: abiertas,
    builder: (context, a) => StreamBuilder<List<Orden>>(
      stream: culminadas,
      builder: (context, c) => builder(
        context,
        Tablero(quien: tecnico, abiertas: a.data ?? const [], culminadasHoy: c.data ?? const [], zona: zona),
        (cargando: a.data == null || c.data == null, error: a.error ?? c.error),
      ),
    ),
  );
}

/// Chips de localidad sobre la lista: «Todas» y las que aparecen en ella.
Widget chipsZonas(
  Textos t, {
  required Iterable<String> deLaLista,
  required Map<String, String> nombres,
  required String? elegida,
  required ValueChanged<String?> alElegir,
}) {
  final zonas = [
    for (final z in nombres.keys)
      if (deLaLista.contains(z)) z,
  ];
  if (zonas.length < 2) return const SizedBox.shrink();
  return SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      children: [
        for (final z in <String?>[null, ...zonas])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(z == null ? t.todas : (nombres[z] ?? z)),
              selected: elegida == z,
              onSelected: (_) => alElegir(z),
            ),
          ),
      ],
    ),
  );
}

/// Llamar y Ver en mapa de un cliente (sin teléfono o sin ubicación, el botón queda apagado).
List<Widget> botonesLlamarYMapa(BuildContext context, Orden o) {
  final t = Textos.of(context);
  final telefono = llamarA(o), mapa = mapaDe(o);
  return [
    IconButton(
      tooltip: t.llamar,
      onPressed: telefono == null ? null : () => abrirFuera(context, telefono),
      icon: const Icon(Icons.phone_rounded),
    ),
    IconButton(
      tooltip: t.verEnMapa,
      onPressed: mapa == null ? null : () => abrirFuera(context, mapa),
      icon: const Icon(Icons.near_me_rounded),
    ),
  ];
}

/// Listas con chips de localidad arriba: la localidad elegida (null = todas).
mixin FiltroDeZona<W extends StatefulWidget> on State<W> {
  String? zona;

  bool enZona(String zonaId) => zona == null || zonaId == zona;

  /// Los chips (con las localidades de `todas`) y, si no queda nada, el aviso.
  List<Widget> encabezadoDeZona(
    Textos t, {
    required Iterable<String> todas,
    required Map<String, String> nombres,
    required bool vacia,
    required IconData icono,
    required String textoVacio,
  }) => [
    chipsZonas(t, deLaLista: todas, nombres: nombres, elegida: zona, alElegir: (z) => setState(() => zona = z)),
    if (vacia)
      Padding(
        padding: const EdgeInsets.only(top: 40),
        child: AvisoCentral(icono: icono, texto: textoVacio),
      ),
  ];
}

/// El nombre de un permiso de rol (`PERMS` de la web) en el idioma de la app.
String nombrePermiso(Textos t, String p) => switch (p) {
  'admin' => t.permisoAdmin,
  'consultor' => t.permisoConsultor,
  'tecnico' => t.permisoTecnico,
  _ => p,
};
