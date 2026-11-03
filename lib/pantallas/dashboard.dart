import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/textos.dart';
import '../logica/cobro.dart';
import '../logica/fechas.dart';
import '../logica/metricas.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import 'comun.dart';
import 'diseno.dart';

/// Dashboard del administrador (solo ver): cómo va el negocio en el periodo, con los mismos números que el Dashboard de
/// la web. Lee una vez las órdenes del periodo y del anterior (para las flechas), no en vivo; jalar hacia abajo recarga.
class PantallaDashboard extends StatefulWidget {
  const PantallaDashboard({super.key, required this.servicio, required this.nombresZonas});

  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaDashboard> createState() => _PantallaDashboardState();
}

typedef _Datos = ({List<Orden> ordenes, Catalogos cat, Map<String, String> tecnicos, Map<String, String> correos});

// recibidas y completadas: pareja revisada para daltonismo (scripts/validate_palette.js de la guía de gráficas)
const _azul = Color(0xFF4F46E5);
const _verde = Color(0xFF10B981);

class _PantallaDashboardState extends State<PantallaDashboard> with LecturaPorPeriodo<PantallaDashboard, _Datos> {
  String? _zona;
  int? _tramoElegido;

  @override
  Future<_Datos> leer({bool recargar = false}) async {
    final r = fijarRango();
    final antes = periodoAnterior(r.desde, r.hastaExclusivo);
    final todo = await Future.wait<Object>([
      widget.servicio.ordenesDelPeriodo(antes.desde, r.desde, r.hastaExclusivo, recargar: recargar),
      widget.servicio.catalogos(),
      widget.servicio.usuarios(),
    ]);
    final usuarios = todo[2] as List<UsuarioAsignable>;
    return (
      ordenes: todo[0] as List<Orden>,
      cat: todo[1] as Catalogos,
      tecnicos: {for (final u in usuarios) u.id: u.nombre},
      correos: {
        for (final u in usuarios)
          if (u.email.isNotEmpty) u.email.toLowerCase(): u.id,
      },
    );
  }

  @override
  void elegirPeriodo(RangoDias? r) {
    _tramoElegido = null;
    super.elegirPeriodo(r);
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Scaffold(
      body: FutureBuilder(
        future: carga,
        builder: (context, foto) {
          final d = foto.data;
          final r = rango;
          final antes = periodoAnterior(r.desde, r.hastaExclusivo);
          final base = d == null
              ? const <Orden>[]
              : d.ordenes.where((o) => _zona == null || o.zonaId == _zona).toList();
          final ahora = d == null ? null : Resumen(base, r.desde, r.hastaExclusivo, d.cat);
          final previo = d == null ? null : Resumen(base, antes.desde, antes.hastaExclusivo, d.cat);
          final Widget cuerpo;
          if (foto.hasError) {
            cuerpo = errorDelPeriodo(t, foto.error!);
          } else if (d == null || ahora == null || previo == null) {
            cuerpo = const ListaEsqueleto();
          } else {
            final dias = r.hastaExclusivo.difference(r.desde).inHours ~/ 24;
            cuerpo = listaDelPeriodo(t, [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(t.dashVsAnterior(dias), style: Theme.of(context).textTheme.bodySmall),
              ),
              _tarjetas(t, ahora, previo),
              if (ahora.total == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: AvisoCentral(icono: Icons.insights_rounded, texto: t.dashSinDatos),
                )
              else ...[
                _tendencia(t, tramos(base, r.desde, r.hastaExclusivo)),
                _estados(t, ahora),
                _localidades(t, porLocalidad(ahora, d.cat)),
              ],
              _tecnicos(t, porTecnico(base, r.desde, r.hastaExclusivo, d.tecnicos, idPorCorreo: d.correos)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(t.dashNota, style: Theme.of(context).textTheme.bodySmall),
              ),
            ]);
          }
          return NestedScrollView(headerSliverBuilder: (context, _) => [_encabezado(t, ahora)], body: cuerpo);
        },
      ),
    );
  }

  Widget _encabezado(Textos t, Resumen? r) {
    final zonas = widget.nombresZonas.keys.toList();
    return encabezadoAzul(
      alto: 226 + 56,
      titulo: Text(t.menuDashboard),
      abajo: filtroZonas(
        t,
        zonas: zonas,
        nombres: widget.nombresZonas,
        elegida: _zona,
        alElegir: (z) => setState(() {
          _zona = z;
          _tramoElegido = null;
        }),
      ),
      relleno: const EdgeInsets.fromLTRB(20, kToolbarHeight + 4, 20, 64),
      contenido: importeConDatos(
        t.dashIngresos,
        r?.ingresos ?? 0,
        DatoCristal(texto: t.dashRecibidas, valor: '${r?.total ?? 0}', color: const Color(0xFFA5B4FC)),
        DatoCristal(texto: t.dashCompletadas, valor: '${r?.completadas ?? 0}', color: const Color(0xFF34D399)),
      ),
    );
  }

  /// Horas en el texto más cómodo: minutos, horas o días.
  String _tiempo(Textos t, double? horas) {
    if (horas == null) return t.dashSinDato;
    final uno = NumberFormat('0.#', Localizations.localeOf(context).toLanguageTag());
    if (horas < 1) return t.dashMinutos((horas * 60).round());
    if (horas < 48) return t.dashHoras(uno.format(horas));
    return t.dashDias(uno.format(horas / 24));
  }

  Widget _tarjetas(Textos t, Resumen a, Resumen b) {
    int pct(int n) => a.total == 0 ? 0 : (n / a.total * 100).round();
    final tarjetas = [
      _Kpi(Icons.inbox_rounded, _azul, t.dashRecibidas, '${a.total}', t.dashRecibidasSub, cambio(a.total, b.total), 1),
      _Kpi(
        Icons.check_circle_rounded,
        _verde,
        t.dashCompletadas,
        '${a.completadas}',
        t.dashCumplimiento(a.cumplimiento.round()),
        b.total == 0 ? null : a.cumplimiento - b.cumplimiento,
        1,
        puntos: true,
      ),
      _Kpi(
        Icons.folder_open_rounded,
        const Color(0xFFD97706),
        t.dashAbiertas,
        '${a.abiertas}',
        t.dashAbiertasSub(a.pendientes, a.enProceso),
        cambio(a.abiertas, b.abiertas),
        -1,
      ),
      _Kpi(
        Icons.timer_rounded,
        const Color(0xFF0891B2),
        t.dashTiempo,
        _tiempo(t, a.horasPromedio),
        t.dashTiempoSub(a.medidas),
        a.horasPromedio == null ? null : cambio(a.horasPromedio!, b.horasPromedio),
        -1,
      ),
      _Kpi(
        Icons.house_rounded,
        const Color(0xFF7C3AED),
        t.dashNuevos,
        '${a.nuevos}',
        t.dashNuevosSub,
        cambio(a.nuevos, b.nuevos),
        1,
      ),
      _Kpi(
        Icons.payments_rounded,
        _verde,
        t.dashIngresos,
        dinero(context, a.ingresos),
        t.dashIngresosSub(a.cobros),
        cambio(a.ingresos, b.ingresos),
        1,
      ),
      _Kpi(
        Icons.hourglass_bottom_rounded,
        const Color(0xFFEA580C),
        t.dashPorCobrar,
        dinero(context, a.porCobrar),
        t.dashPorCobrarSub,
        cambio(a.porCobrar, b.porCobrar),
        -1,
      ),
      _Kpi(
        Icons.event_busy_rounded,
        const Color(0xFFE11D48),
        t.dashPospuestas,
        '${a.pospuestas}',
        t.dashDeLasSolicitudes(pct(a.pospuestas)),
        cambio(a.pospuestas, b.pospuestas),
        -1,
      ),
      _Kpi(
        Icons.block_rounded,
        const Color(0xFFE11D48),
        t.dashCanceladas,
        '${a.canceladas}',
        t.dashDeLasSolicitudes(pct(a.canceladas)),
        cambio(a.canceladas, b.canceladas),
        -1,
      ),
    ];
    return LayoutBuilder(
      builder: (context, medidas) {
        final ancho = (medidas.maxWidth - 32 - 10) / 2;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < tarjetas.length; i++)
                SizedBox(
                  width: ancho,
                  child: Aparecer(orden: i, child: tarjetas[i]),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _caja(String titulo, List<Widget> hijos) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Superficie(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...hijos,
        ],
      ),
    ),
  );

  /// Recibidas y completadas por día (o semana, o mes): barras finas en pareja; tocar una muestra sus números.
  Widget _tendencia(Textos t, List<Tramo> lista) {
    final colores = Theme.of(context).colorScheme;
    final idioma = Localizations.localeOf(context).toLanguageTag();
    final maximo = lista.fold<int>(1, (m, x) => [m, x.recibidas, x.completadas].reduce((a, b) => a > b ? a : b));
    final unidad = lista.isEmpty ? UnidadTramo.dia : unidadDe(lista.first.desde, lista.last.hastaExclusivo);
    String nombre(Tramo x) =>
        unidad == UnidadTramo.mes ? DateFormat.yMMM(idioma).format(x.desde) : DateFormat.MMMd(idioma).format(x.desde);
    final elegido = _tramoElegido != null && _tramoElegido! < lista.length ? lista[_tramoElegido!] : null;
    Widget barra(int n, Color color) => Expanded(
      child: Container(
        height: 140 * n / maximo,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
    return _caja(t.dashTendencia, [
      Wrap(
        spacing: 16,
        children: [
          _Leyenda(color: _azul, texto: t.dashRecibidas),
          _Leyenda(color: _verde, texto: t.dashCompletadas),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 148,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < lista.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _tramoElegido = _tramoElegido == i ? null : i),
                  child: Container(
                    height: 148,
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _tramoElegido == i ? colores.primary.withValues(alpha: 0.08) : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    // barras finas: con pocos días no se estiran a todo lo ancho
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 28),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [barra(lista[i].recibidas, _azul), barra(lista[i].completadas, _verde)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      Divider(height: 1, color: colores.outlineVariant),
      const SizedBox(height: 6),
      if (lista.isNotEmpty)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nombre(lista.first), style: Theme.of(context).textTheme.bodySmall),
            if (lista.length > 1) Text(nombre(lista.last), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      const SizedBox(height: 8),
      Text(
        elegido == null ? t.dashToca : t.dashTramo(nombre(elegido), elegido.recibidas, elegido.completadas),
        style: TextStyle(
          fontWeight: elegido == null ? FontWeight.w400 : FontWeight.w600,
          color: elegido == null ? colores.onSurfaceVariant : null,
        ),
      ),
    ]);
  }

  /// Cuántas pendientes, en proceso, completadas y canceladas: cada una con su nombre y su número.
  Widget _estados(Textos t, Resumen r) {
    final filas = [
      (t.estPendiente, r.pendientes, const Color(0xFFF59E0B)),
      (t.estEnProceso, r.enProceso, const Color(0xFF6366F1)),
      (t.estCompletada, r.completadas, _verde),
      (t.estCancelada, r.canceladas, const Color(0xFFF43F5E)),
    ];
    return _caja(t.dashEstados, [
      for (final (nombre, n, color) in filas) _FilaBarra(texto: nombre, valor: '$n', parte: n / r.total, color: color),
    ]);
  }

  Widget _localidades(Textos t, List<FilaLocalidad> filas) => _caja(t.dashPorLocalidad, [
    for (final f in filas)
      _FilaDato(
        titulo: f.zonaId.isEmpty ? t.dashSinLocalidad : (widget.nombresZonas[f.zonaId] ?? f.zonaId),
        detalle: t.dashLocalidadDetalle(f.recibidas, f.completadas),
        valor: dinero(context, f.ingresos),
        abajo: _tiempo(t, f.horasPromedio),
      ),
  ]);

  Widget _tecnicos(Textos t, List<FilaTecnico> filas) {
    if (filas.isEmpty) return const SizedBox.shrink();
    final maximo = filas.first.completadas;
    return _caja(t.dashPorTecnico, [
      for (final f in filas)
        _FilaBarra(
          texto: f.nombre.isEmpty ? t.tecnico : f.nombre,
          valor: '${f.completadas}',
          parte: f.completadas / maximo,
          color: _azul,
          detalle: t.dashTecnicoDetalle(f.completadas, _tiempo(t, f.horasPromedio)),
        ),
    ]);
  }
}

/// Tarjeta de un número del periodo, con la flecha del cambio contra el periodo anterior.
/// `mejor`: 1 si subir es bueno, -1 si bajar es bueno, 0 si da igual.
class _Kpi extends StatelessWidget {
  const _Kpi(this.icono, this.color, this.titulo, this.valor, this.sub, this.cambio, this.mejor, {this.puntos = false});

  final IconData icono;
  final Color color;
  final String titulo;
  final String valor;
  final String sub;
  final double? cambio;
  final int mejor;

  /// El cambio va en puntos de porcentaje (cumplimiento), no en %.
  final bool puntos;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final c = cambio;
    return Superficie(
      radio: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colores.onSurfaceVariant),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                child: Icon(icono, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          ),
          Text(
            sub,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: colores.onSurfaceVariant),
          ),
          if (c != null) ...[const SizedBox(height: 6), _Flecha(cambio: c, mejor: mejor, puntos: puntos)],
        ],
      ),
    );
  }
}

class _Flecha extends StatelessWidget {
  const _Flecha({required this.cambio, required this.mejor, required this.puntos});

  /// En %, o en puntos; infinito si antes era 0 (la web dice «Nuevo»).
  final double cambio;
  final int mejor;
  final bool puntos;

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final colores = Theme.of(context).colorScheme;
    final igual = cambio.abs() < 0.5;
    final numero = '${cambio > 0 ? '+' : ''}${cambio.isInfinite ? 0 : cambio.round()}';
    final sube = cambio > 0;
    final bueno = mejor == 0 || igual ? null : (sube == (mejor > 0));
    final color = switch (bueno) {
      true => const Color(0xFF059669),
      false => colores.error,
      null => colores.onSurfaceVariant,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          igual ? Icons.drag_handle_rounded : (sube ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
          size: 14,
          color: color,
        ),
        if (!igual)
          Text(
            cambio.isInfinite ? t.dashNuevo : (puntos ? t.dashPuntos(numero) : '$numero%'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 6,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(texto, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Nombre y número arriba, barra de su parte abajo (y un detalle opcional).
class _FilaBarra extends StatelessWidget {
  const _FilaBarra({required this.texto, required this.valor, required this.parte, required this.color, this.detalle});

  final String texto;
  final String valor;
  final double parte;
  final Color color;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: parte.isFinite ? parte.clamp(0, 1) : 0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: color,
                backgroundColor: colores.surfaceContainerHighest,
              ),
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 4),
            Text(detalle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Fila de una tabla corta: título y detalle a la izquierda, valor y nota a la derecha.
class _FilaDato extends StatelessWidget {
  const _FilaDato({required this.titulo, required this.detalle, required this.valor, required this.abajo});

  final String titulo;
  final String detalle;
  final String valor;
  final String abajo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(detalle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(valor, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(abajo, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    ),
  );
}
