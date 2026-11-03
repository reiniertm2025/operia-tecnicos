import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de este celular: idioma (null = el del teléfono) y apariencia (automática, clara u oscura).
class Ajustes {
  Ajustes._(this._prefs, String? idioma, String? tema)
    : idioma = ValueNotifier(idioma == null ? null : Locale(idioma)),
      tema = ValueNotifier(ThemeMode.values.firstWhere((m) => m.name == tema, orElse: () => ThemeMode.system));

  static const _claveIdioma = 'idioma';
  static const _claveTema = 'tema';
  final SharedPreferences? _prefs;
  final ValueNotifier<Locale?> idioma;
  final ValueNotifier<ThemeMode> tema;

  static Future<Ajustes> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Ajustes._(prefs, prefs.getString(_claveIdioma), prefs.getString(_claveTema));
    } catch (_) {
      // sin preferencias guardadas la app sigue con lo del teléfono
      return Ajustes._(null, null, null);
    }
  }

  Future<void> cambiarIdioma(Locale? nuevo) async {
    idioma.value = nuevo;
    final prefs = _prefs;
    if (prefs == null) return;
    if (nuevo == null) {
      await prefs.remove(_claveIdioma);
    } else {
      await prefs.setString(_claveIdioma, nuevo.languageCode);
    }
  }

  Future<void> cambiarTema(ThemeMode nuevo) async {
    tema.value = nuevo;
    await _prefs?.setString(_claveTema, nuevo.name);
  }
}
