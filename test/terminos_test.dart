import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/ayuda/terminos.dart';
import 'package:torrexi_tecnicos/l10n/textos.dart';
import 'package:torrexi_tecnicos/pantallas/terminos.dart';
import 'package:torrexi_tecnicos/servicios/sesion.dart';

Terminos leer(String idioma) =>
    Terminos.deJson(jsonDecode(File('assets/terminos/$idioma.json').readAsStringSync()) as Map<String, dynamic>);

void main() {
  test('español e inglés tienen la misma versión y las mismas secciones', () {
    final es = leer('es'), en = leer('en');
    expect(es.version, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(en.version, es.version);
    expect(en.secciones.map((s) => s.icono), es.secciones.map((s) => s.icono));
    for (final s in [...es.secciones, ...en.secciones]) {
      expect(s.titulo, isNotEmpty);
      expect(s.texto, isNotEmpty);
    }
  });

  testWidgets('no deja aceptar sin leer hasta el final y marcar la casilla', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    String? aceptada;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: Textos.supportedLocales,
        localizationsDelegates: const [
          Textos.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: PantallaTerminos(
          tecnico: const Tecnico(userId: 'u1', nombre: 'Portela'),
          terminos: leer('es'),
          alAceptar: (v) async => aceptada = v,
          alRechazar: () {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Antes de empezar, Portela'), findsOneWidget);
    expect(find.text('Desliza hasta el final para poder aceptar'), findsOneWidget);
    await tester.tap(find.text('Aceptar y entrar'), warnIfMissed: false);
    expect(aceptada, isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Aceptar y entrar'), warnIfMissed: false);
    expect(aceptada, isNull, reason: 'falta marcar la casilla');

    await tester.tap(find.text('Leí y acepto los términos y condiciones'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Aceptar y entrar'));
    await tester.pump();
    expect(aceptada, leer('es').version);
  });
}
