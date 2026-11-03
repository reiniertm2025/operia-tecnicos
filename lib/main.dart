import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'l10n/textos.dart';
import 'pantallas/diseno.dart';
import 'ayuda/terminos.dart';
import 'pantallas/inicio_sesion.dart';
import 'pantallas/terminos.dart';
import 'pantallas/principal.dart';
import 'servicios/ajustes.dart';
import 'servicios/avisos.dart';
import 'servicios/sesion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(TorrexiTecnicos(ajustes: await Ajustes.cargar()));
}

/// Tema de la app: azul de la marca, fondos suaves, esquinas redondeadas y transiciones con desvanecido.
ThemeData _tema(Brightness brillo) {
  final oscuro = brillo == Brightness.dark;
  final colores = ColorScheme.fromSeed(
    seedColor: Marca.azul,
    brightness: brillo,
    primary: oscuro ? const Color(0xFF7CB4FF) : Marca.azul,
  );
  final redondo = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return ThemeData(
    colorScheme: colores,
    scaffoldBackgroundColor: oscuro ? const Color(0xFF070D1A) : const Color(0xFFF3F6FB),
    appBarTheme: const AppBarTheme(centerTitle: false, scrolledUnderElevation: 0),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()}),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: redondo,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: redondo),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      elevation: 0,
      backgroundColor: oscuro ? const Color(0xFF0E1628) : Colors.white,
      indicatorColor: colores.primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(fontSize: 12, fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500),
      ),
    ),
    // filas tocables (opciones, interruptores, casillas): el efecto de toque con esquinas redondeadas, como los botones
    listTileTheme: ListTileThemeData(shape: redondo),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: redondo),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    inputDecorationTheme: InputDecorationTheme(filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
  );
}

class TorrexiTecnicos extends StatelessWidget {
  const TorrexiTecnicos({super.key, required this.ajustes});

  final Ajustes ajustes;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ajustes.idioma, ajustes.tema]),
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => Textos.of(context).appTitulo,
        debugShowCheckedModeBanner: false,
        // claro u oscuro: el del teléfono, o el que se eligió en Apariencia
        theme: _tema(Brightness.light),
        darkTheme: _tema(Brightness.dark),
        themeMode: ajustes.tema.value,
        locale: ajustes.idioma.value,
        supportedLocales: Textos.supportedLocales,
        localizationsDelegates: const [
          Textos.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _Inicio(sesion: Sesion(), ajustes: ajustes),
      ),
    );
  }
}

/// Al abrir la app: si ya había sesión en este celular entra directo; si no, pide usuario y contraseña.
class _Inicio extends StatefulWidget {
  const _Inicio({required this.sesion, required this.ajustes});
  final Sesion sesion;
  final Ajustes ajustes;

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  bool _revisando = true;
  Tecnico? _tecnico;

  /// Versión vigente de los términos y si ya los aceptó en esta sesión.
  String _versionTerminos = '';
  bool _acepto = false;

  @override
  void initState() {
    super.initState();
    _revisar();
  }

  Future<void> _revisar() async {
    Tecnico? tecnico;
    try {
      // la versión vigente sale siempre del español (la prueba exige que el inglés diga la misma)
      _versionTerminos = (await cargarTerminos('es')).version;
      tecnico = await widget.sesion.actual();
    } catch (_) {
      // sin internet o sin permiso: se pide entrar de nuevo
    }
    if (!mounted) return;
    setState(() {
      _tecnico = tecnico;
      _revisando = false;
    });
  }

  Future<void> _salir() async {
    try {
      await Avisos.apagar();
    } catch (_) {
      // si no estaba encendido, no pasa nada
    }
    await widget.sesion.cerrar();
    if (mounted) {
      setState(() {
        _tecnico = null;
        _acepto = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_revisando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final tecnico = _tecnico;
    if (tecnico == null) {
      return PantallaInicioSesion(sesion: widget.sesion, alEntrar: (t) => setState(() => _tecnico = t));
    }
    if (!_acepto && tecnico.terminosAceptados != _versionTerminos) {
      return PantallaTerminos(
        tecnico: tecnico,
        alAceptar: (_) async {
          await widget.sesion.aceptarTerminos(tecnico, _versionTerminos);
          if (mounted) setState(() => _acepto = true);
        },
        alRechazar: _salir,
      );
    }
    return PantallaPrincipal(tecnico: tecnico, ajustes: widget.ajustes, alSalir: _salir);
  }
}
