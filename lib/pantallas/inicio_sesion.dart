import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/textos.dart';
import '../logica/errores.dart';
import '../servicios/recordar.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'fondo_login.dart';

/// Entrada «Conectando tu mundo», con el mismo fondo animado que el login de la web.
class PantallaInicioSesion extends StatefulWidget {
  const PantallaInicioSesion({super.key, required this.sesion, required this.alEntrar});

  final Sesion sesion;
  final ValueChanged<Tecnico> alEntrar;

  @override
  State<PantallaInicioSesion> createState() => _PantallaInicioSesionState();
}

class _PantallaInicioSesionState extends State<PantallaInicioSesion> with SingleTickerProviderStateMixin {
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  late final _entrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  final _recordados = DatosRecordados();
  bool _recordar = true;
  bool _ocultar = true;
  bool _entrando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recordados.leer().then((datos) {
      if (datos == null || !mounted) return;
      _usuario.text = datos.usuario;
      _contrasena.text = datos.contrasena;
    });
  }

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    _entrada.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_entrando) return;
    final t = Textos.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _entrando = true;
      _error = null;
    });
    try {
      final tecnico = await widget.sesion.iniciar(_usuario.text, _contrasena.text);
      // solo se recuerdan datos que sí funcionaron
      if (_recordar) {
        await _recordados.guardar(_usuario.text, _contrasena.text);
      } else {
        await _recordados.borrar();
      }
      widget.alEntrar(tecnico);
    } on ErrorDeSesion catch (e) {
      setState(() => _error = textoFalloSesion(t, e));
    } catch (e) {
      setState(() => _error = t.errOtro('$e'));
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final colores = Theme.of(context).colorScheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final curva = CurvedAnimation(parent: _entrada, curve: const Cubic(0.2, 0.7, 0.2, 1));
    // hora e íconos de arriba en blanco: el fondo siempre es oscuro
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF050E24),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const FondoLogin(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, caja) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: caja.maxHeight - 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/logo.svg', width: 48, height: 48),
                                const SizedBox(width: 12),
                                Text(
                                  t.appTitulo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(t.conectando, style: _titular(Colors.white)),
                            Text(t.tuMundo, style: _titular(const Color(0xFF38BDF8))),
                            const SizedBox(height: 10),
                            Text(
                              t.loginSubtitulo,
                              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, height: 1.4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: curva,
                          child: SlideTransition(
                            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curva),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 456),
                                child: _tarjeta(t, colores, oscuro),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _titular(Color color) => TextStyle(
    color: color,
    fontSize: 40,
    height: 1.02,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    shadows: const [Shadow(color: Color(0x73000000), blurRadius: 28, offset: Offset(0, 2))],
  );

  Widget _tarjeta(Textos t, ColorScheme colores, bool oscuro) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: oscuro ? colores.surfaceContainer.withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: oscuro ? 0.08 : 0.7)),
        boxShadow: const [
          BoxShadow(color: Color(0xBF020817), blurRadius: 90, offset: Offset(0, 40), spreadRadius: -30),
          BoxShadow(color: Color(0x73020817), blurRadius: 32, offset: Offset(0, 12), spreadRadius: -12),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.entrar, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(t.loginInstruccion, style: TextStyle(color: colores.onSurfaceVariant)),
            const SizedBox(height: 24),
            TextField(
              controller: _usuario,
              enabled: !_entrando,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: _campo(t.usuario, Icons.person_outline, colores),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contrasena,
              enabled: !_entrando,
              obscureText: _ocultar,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _entrar(),
              decoration: _campo(t.contrasena, Icons.lock_outline, colores).copyWith(
                suffixIcon: IconButton(
                  tooltip: _ocultar ? t.verContrasena : t.ocultarContrasena,
                  icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                ),
              ),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _recordar,
              onChanged: _entrando ? null : (v) => setState(() => _recordar = v ?? false),
              title: Text(t.recordarDatos),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colores.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(_error!, style: TextStyle(color: colores.onErrorContainer)),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _entrando ? null : _entrar,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _entrando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(t.entrar, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _campo(String texto, IconData icono, ColorScheme colores) => InputDecoration(
    labelText: texto,
    prefixIcon: Icon(icono),
    filled: true,
    fillColor: colores.surfaceContainerHighest.withValues(alpha: 0.5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colores.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colores.outlineVariant),
    ),
  );
}
