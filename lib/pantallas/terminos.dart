import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../ayuda/terminos.dart';
import '../l10n/textos.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'diseno.dart';
import 'fondo_login.dart';

/// Términos y condiciones sobre el fondo animado del login. La primera vez (o si cambian) hay que leerlos hasta el final,
/// marcar «Leí y acepto» y tocar «Aceptar y entrar»; sin aceptar no se entra. Desde el menú se abren solo para leer.
class PantallaTerminos extends StatefulWidget {
  const PantallaTerminos({super.key, required this.tecnico, this.alAceptar, this.alRechazar, this.terminos});

  final Tecnico tecnico;

  /// Guarda la aceptación de esa versión; null = solo leer.
  final Future<void> Function(String version)? alAceptar;
  final VoidCallback? alRechazar;

  /// Para pruebas; si no, se leen de assets/terminos.
  final Terminos? terminos;

  @override
  State<PantallaTerminos> createState() => _PantallaTerminosState();
}

class _PantallaTerminosState extends State<PantallaTerminos> {
  final _scroll = ScrollController();
  Future<Terminos>? _carga;
  double _avance = 0;
  bool _alFinal = false;
  bool _marcado = false;
  bool _guardando = false;

  bool get _soloLeer => widget.alAceptar == null;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_medir);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final idioma = Localizations.localeOf(context).languageCode;
    _carga ??= widget.terminos != null ? Future.value(widget.terminos) : cargarTerminos(idioma);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _medir() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final avance = p.maxScrollExtent <= 0 ? 1.0 : (p.pixels / p.maxScrollExtent).clamp(0.0, 1.0);
    final alFinal = _alFinal || p.pixels >= p.maxScrollExtent - 24;
    if (avance != _avance || alFinal != _alFinal) {
      setState(() {
        _avance = avance;
        _alFinal = alFinal;
      });
    }
  }

  Future<void> _aceptar(Terminos terminos) async {
    final t = Textos.of(context);
    final avisos = ScaffoldMessenger.of(context);
    setState(() => _guardando = true);
    try {
      await widget.alAceptar!(terminos.version);
    } on ErrorDeOrden catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(textoFalloOrden(t, e))));
      if (mounted) setState(() => _guardando = false);
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(t.errOtro('$e'))));
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _rechazar() async {
    final t = Textos.of(context);
    final salir = await confirmar(
      context,
      icono: Icons.logout_rounded,
      titulo: t.terminosSalirPregunta,
      texto: t.terminosSalirTexto,
      boton: t.terminosSalir,
    );
    if (salir) widget.alRechazar?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF050E24),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const FondoLogin(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66050E24), Color(0xCC050E24), Color(0xF2050E24)],
                ),
              ),
            ),
            SafeArea(
              child: FutureBuilder<Terminos>(
                future: _carga,
                builder: (context, foto) {
                  final terminos = foto.data;
                  if (terminos == null) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  // si todo cabe sin deslizar, ya se puede aceptar
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _medir();
                  });
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _encabezado(t, terminos),
                      Expanded(child: _documento(terminos)),
                      if (!_soloLeer) _pie(t, terminos),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encabezado(Textos t, Terminos terminos) {
    final fecha = DateTime.tryParse(terminos.version);
    final idioma = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/logo.svg', width: 36, height: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.appTitulo,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (_soloLeer)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Aparecer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_soloLeer)
                  Text(
                    t.terminosAntes(widget.tecnico.nombre.isEmpty ? t.tecnico : widget.tecnico.nombre),
                    style: const TextStyle(color: Marca.cielo, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                Text(
                  t.terminosTitulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.15,
                  ),
                ),
                if (fecha != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF34D399)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            t.terminosActualizados(DateFormat.yMMMMd(idioma).format(fecha)),
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // barra de lectura
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 4, color: Colors.white.withValues(alpha: 0.1)),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 150),
                  widthFactor: _avance,
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Marca.cielo, Color(0xFF34D399)])),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documento(Terminos terminos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                Text(terminos.intro, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.55)),
                const SizedBox(height: 8),
                for (var i = 0; i < terminos.secciones.length; i++)
                  Aparecer(
                    orden: i + 1,
                    child: _Seccion(numero: i + 1, seccion: terminos.secciones[i]),
                  ),
                const SizedBox(height: 18),
                Text(
                  terminos.cierre,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pie(Textos t, Terminos terminos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _alFinal
                  ? Presionable(
                      key: const ValueKey('marcar'),
                      radio: 16,
                      alTocar: () => setState(() => _marcado = !_marcado),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: _marcado ? 0.12 : 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _marcado ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _marcado ? const Color(0xFF34D399) : Colors.transparent,
                                border: Border.all(
                                  color: _marcado ? const Color(0xFF34D399) : Colors.white54,
                                  width: 2,
                                ),
                              ),
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                scale: _marcado ? 1 : 0,
                                child: const Icon(Icons.check_rounded, size: 18, color: Color(0xFF052E1B)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.terminosLeiAcepto,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      key: const ValueKey('desliza'),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _FlechaAbajo(),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              t.terminosDesliza,
                              style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              ignoring: !_marcado,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _marcado ? 1 : 0.4,
                child: BotonPrincipal(
                  icono: Icons.verified_user_rounded,
                  texto: t.terminosAceptar,
                  ocupado: _guardando,
                  alTocar: () => _aceptar(terminos),
                ),
              ),
            ),
            TextButton(
              onPressed: _guardando ? null : _rechazar,
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: Text(t.terminosNoAcepto),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una sección: número con su ícono, título y texto.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.numero, required this.seccion});

  final int numero;
  final SeccionTerminos seccion;

  static IconData _icono(String clave) => switch (clave) {
    'app' => Icons.phone_android_rounded,
    'cuenta' => Icons.badge_rounded,
    'uso' => Icons.verified_user_rounded,
    'datos' => Icons.lock_person_rounded,
    'cobros' => Icons.payments_rounded,
    'red' => Icons.lan_rounded,
    'registro' => Icons.history_edu_rounded,
    'equipo' => Icons.wifi_rounded,
    'cambios' => Icons.update_rounded,
    'faltas' => Icons.gavel_rounded,
    _ => Icons.article_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
              ),
              boxShadow: [BoxShadow(color: Marca.azul.withValues(alpha: 0.4), blurRadius: 14, spreadRadius: -4)],
            ),
            child: Icon(_icono(seccion.icono), color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numero. ${seccion.titulo}',
                  style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(seccion.texto, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14.5, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Flecha que sube y baja, invitando a deslizar.
class _FlechaAbajo extends StatefulWidget {
  const _FlechaAbajo();

  @override
  State<_FlechaAbajo> createState() => _FlechaAbajoState();
}

class _FlechaAbajoState extends State<_FlechaAbajo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, hijo) =>
          Transform.translate(offset: Offset(0, 4 * Curves.easeInOut.transform(_c.value)), child: hijo),
      child: const Icon(Icons.keyboard_double_arrow_down_rounded, color: Marca.cielo),
    );
  }
}
