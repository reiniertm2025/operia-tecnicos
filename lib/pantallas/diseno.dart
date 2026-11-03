import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logica/orden.dart';

/// Diseño de la app: colores de la marca (los del logo y el login de la web), sombras por nivel y animaciones comunes.

class Marca {
  static const azul = Color(0xFF2563EB);
  static const cielo = Color(0xFF38BDF8);
  static const marino = Color(0xFF060D20);

  /// Fondo de los encabezados: el azul marino del logo, con un brillo azul arriba a la derecha.
  static const degradado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF14254F), Color(0xFF070F24)],
    stops: [0, 0.5, 1],
  );
  static const brillo = RadialGradient(
    center: Alignment(0.9, -0.8),
    radius: 1.1,
    colors: [Color(0x5538BDF8), Color(0x0038BDF8)],
  );
}

/// Color de cada estado (los mismos de la web).
Color colorEstado(Orden o) => switch (o.estado) {
  _ when o.esperaAutorizacion && o.estado == 'en_proceso' => const Color(0xFFD97706),
  _ when o.avisoTerminada && o.estado == 'en_proceso' => const Color(0xFF0D9488),
  'pendiente' => const Color(0xFFF59E0B),
  'en_proceso' => const Color(0xFF6366F1),
  'completada' => const Color(0xFF10B981),
  'cancelada' => const Color(0xFFF43F5E),
  _ => Colors.blueGrey,
};

/// Ícono según el tipo de servicio.
IconData iconoServicio(Orden o) {
  final s = o.servicio.toLowerCase();
  if (o.sinCobro && (s.contains('falla') || s.contains('repar') || o.datos['serviceType'] == 'falla')) {
    return Icons.build_rounded;
  }
  if (o.sinCobro) return Icons.power_off_rounded;
  if (s.contains('instal') || s.contains('nuev')) return Icons.router_rounded;
  if (s.contains('cambio') || s.contains('domicilio')) return Icons.swap_horiz_rounded;
  return Icons.handyman_rounded;
}

/// Sombras por nivel de elevación (1 = tarjeta, 2 = flotante, 3 = destacada). En modo oscuro casi no se ven,
/// así que ahí la profundidad la da el borde y el color de la superficie.
List<BoxShadow> sombra(BuildContext context, int nivel) {
  final oscuro = Theme.of(context).brightness == Brightness.dark;
  final base = oscuro ? const Color(0xFF000000) : const Color(0xFF0F1E46);
  final f = oscuro ? 2.2 : 1.0;
  return switch (nivel) {
    1 => [
      BoxShadow(
        color: base.withValues(alpha: 0.05 * f),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: base.withValues(alpha: 0.07 * f),
        blurRadius: 14,
        offset: const Offset(0, 6),
        spreadRadius: -4,
      ),
    ],
    2 => [
      BoxShadow(
        color: base.withValues(alpha: 0.06 * f),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: base.withValues(alpha: 0.12 * f),
        blurRadius: 28,
        offset: const Offset(0, 14),
        spreadRadius: -8,
      ),
    ],
    _ => [
      BoxShadow(
        color: base.withValues(alpha: 0.08 * f),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
      BoxShadow(
        color: base.withValues(alpha: 0.2 * f),
        blurRadius: 44,
        offset: const Offset(0, 24),
        spreadRadius: -12,
      ),
    ],
  };
}

/// Encabezado azul de la marca que se encoge al bajar: al expandirse muestra `contenido`; encogido queda `titulo`.
SliverAppBar encabezadoAzul({
  required double alto,
  required Widget titulo,
  required EdgeInsets relleno,
  required List<Widget> contenido,
  List<Widget>? acciones,
  PreferredSizeWidget? abajo,
}) {
  return SliverAppBar(
    pinned: true,
    expandedHeight: alto,
    backgroundColor: const Color(0xFF0B1834),
    foregroundColor: Colors.white,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))),
    clipBehavior: Clip.antiAlias,
    title: DefaultTextStyle.merge(
      style: const TextStyle(fontWeight: FontWeight.w700),
      child: titulo,
    ),
    actions: acciones,
    bottom: abajo,
    flexibleSpace: FlexibleSpaceBar(
      collapseMode: CollapseMode.parallax,
      background: DecoratedBox(
        decoration: const BoxDecoration(gradient: Marca.degradado),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: Marca.brillo),
          child: SafeArea(
            bottom: false,
            child: _Desvanecer(
              child: Padding(
                padding: relleno,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contenido,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Se desvanece mientras el encabezado se encoge: a la mitad del camino ya no se ve (no se encima con los chips).
class _Desvanecer extends StatelessWidget {
  const _Desvanecer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final e = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    if (e == null || e.maxExtent <= e.minExtent) return child;
    final abierto = ((e.currentExtent - e.minExtent) / (e.maxExtent - e.minExtent)).clamp(0.0, 1.0);
    final opacidad = const Interval(0.5, 1, curve: Curves.easeOut).transform(abierto);
    return IgnorePointer(
      ignoring: opacidad < 0.5,
      child: Opacity(opacity: opacidad, child: child),
    );
  }
}

/// Superficie elevada: fondo, esquinas redondeadas, borde fino y sombra del nivel pedido.
class Superficie extends StatelessWidget {
  const Superficie({super.key, required this.child, this.nivel = 1, this.radio = 20, this.padding, this.color});

  final Widget child;
  final int nivel;
  final double radio;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final esquinas = BorderRadius.circular(radio);
    return Container(
      decoration: BoxDecoration(
        color: color ?? (oscuro ? colores.surfaceContainer : colores.surface),
        borderRadius: esquinas,
        border: Border.all(color: oscuro ? Colors.white.withValues(alpha: 0.06) : const Color(0x0F0F1E46)),
        boxShadow: sombra(context, nivel),
      ),
      // el efecto de toque de lo que va adentro (filas, secciones que se abren) respeta las esquinas redondeadas
      child: Material(
        type: MaterialType.transparency,
        borderRadius: esquinas,
        clipBehavior: Clip.antiAlias,
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
  }
}

/// Aparece subiendo y haciéndose visible; con `orden` se escalonan las tarjetas de una lista.
class Aparecer extends StatefulWidget {
  const Aparecer({super.key, required this.child, this.orden = 0, this.desde = 18});

  final Widget child;
  final int orden;
  final double desde;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _curva = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _espera;

  @override
  void initState() {
    super.initState();
    // las primeras tarjetas se escalonan; las que siguen ya no esperan más
    _espera = Timer(Duration(milliseconds: 45 * widget.orden.clamp(0, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _espera?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _curva,
      builder: (context, hijo) => Opacity(
        opacity: _curva.value,
        child: Transform.translate(offset: Offset(0, widget.desde * (1 - _curva.value)), child: hijo),
      ),
      child: widget.child,
    );
  }
}

/// Se hunde un poco al tocarlo (sensación de botón físico).
class Presionable extends StatefulWidget {
  const Presionable({super.key, required this.child, required this.alTocar, this.radio = 20});

  final Widget child;
  final VoidCallback? alTocar;
  final double radio;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable> {
  bool _abajo = false;

  void _poner(bool v) {
    if (_abajo != v) setState(() => _abajo = v);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _abajo ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radio),
          onTap: widget.alTocar,
          onTapDown: (_) => _poner(true),
          onTapUp: (_) => _poner(false),
          onTapCancel: () => _poner(false),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Número que cambia contando (para los totales).
class NumeroAnimado extends StatelessWidget {
  const NumeroAnimado(this.valor, {super.key, this.estilo});

  final int valor;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: valor.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: estilo),
    );
  }
}

/// Tarjetas grises con un brillo que pasa, mientras cargan las órdenes.
class ListaEsqueleto extends StatefulWidget {
  const ListaEsqueleto({super.key});

  @override
  State<ListaEsqueleto> createState() => _ListaEsqueletoState();
}

class _ListaEsqueletoState extends State<ListaEsqueleto> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final gris = colores.onSurface.withValues(alpha: 0.07);
    Widget barra(double ancho, double alto) => Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(color: gris, borderRadius: BorderRadius.circular(8)),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, hijo) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment(-1 + 3 * _c.value - 1, 0),
          end: Alignment(3 * _c.value - 1, 0),
          colors: [Colors.transparent, colores.surface.withValues(alpha: 0.6), Colors.transparent],
        ).createShader(r),
        child: hijo,
      ),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Superficie(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: gris, borderRadius: BorderRadius.circular(14)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          barra(160, 14),
                          const SizedBox(height: 10),
                          barra(220, 10),
                          const SizedBox(height: 8),
                          barra(120, 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón azul grande con degradado y sombra de color.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.icono,
    required this.texto,
    required this.ocupado,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final bool ocupado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Presionable(
      radio: 16,
      alTocar: ocupado ? null : alTocar,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: ocupado ? 0.6 : 1,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Marca.azul, Color(0xFF1D4ED8)]),
            boxShadow: [
              BoxShadow(
                color: Marca.azul.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -6,
              ),
            ],
          ),
          child: ocupado
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      texto,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Barra fija de abajo con esquinas redondeadas y sombra, para la acción principal de la pantalla.
class BarraInferior extends StatelessWidget {
  const BarraInferior({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: oscuro ? const Color(0xFF0E1628) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: sombra(context, 3),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 12), child: child),
      ),
    );
  }
}

/// Total de cristal sobre el encabezado azul (número animado y nombre); al tocarlo elige esa lista.
class TotalCristal extends StatelessWidget {
  const TotalCristal({
    super.key,
    required this.texto,
    required this.cuantas,
    required this.color,
    required this.elegido,
    required this.alTocar,
  });

  final String texto;
  final int cuantas;
  final Color color;
  final bool elegido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Presionable(
        radio: 18,
        alTocar: alTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: elegido ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: elegido ? color.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.12)),
            boxShadow: elegido
                ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -6)]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: NumeroAnimado(
                  cuantas,
                  estilo: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
                ),
              ),
              Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip del filtro, sobre el encabezado azul.
class ChipFiltro extends StatelessWidget {
  const ChipFiltro({super.key, required this.texto, required this.elegido, required this.alTocar});

  final String texto;
  final bool elegido;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Presionable(
      radio: 20,
      alTocar: alTocar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: elegido ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: elegido ? 1 : 0.18)),
          boxShadow: elegido
              ? [BoxShadow(color: Marca.cielo.withValues(alpha: 0.35), blurRadius: 14, spreadRadius: -4)]
              : null,
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: elegido ? const Color(0xFF0B1834) : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
