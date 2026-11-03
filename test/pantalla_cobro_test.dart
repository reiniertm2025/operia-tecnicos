import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/l10n/textos.dart';
import 'package:operia_tecnicos/logica/cobro.dart';
import 'package:operia_tecnicos/logica/orden.dart';
import 'package:operia_tecnicos/pantallas/cobro.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';

import 'cobro_test.dart' show cat;

/// La pantalla de cobro con una base simulada: se dibuja, pasa al paso 2 y guarda igual que la web.
void main() {
  const tecnico = Tecnico(userId: 'u1', nombre: 'Portela');

  Future<FakeFirebaseFirestore> abrir(WidgetTester tester, Map<String, dynamic> datos, Catalogos catalogo) async {
    final db = FakeFirebaseFirestore();
    await db.collection('tickets').doc('t1').set(datos);
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
        home: PantallaCobro(
          orden: Orden('t1', datos),
          catalogos: catalogo,
          tecnico: tecnico,
          servicio: ServicioOrdenes(db: db),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  testWidgets('cambio de domicilio en efectivo: marca, continúa, elige efectivo y queda completada', (tester) async {
    final db = await abrir(tester, {
      'status': 'en_proceso',
      'serviceType': 'desactivacion',
      'serviceName': 'Cambio de Domicilio',
      'startedAt': 1,
    }, cat);
    expect(find.text('¿Qué se cobró?'), findsOneWidget);
    await tester.tap(find.text('Cambio de Domicilio').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo pagó el cliente?'), findsOneWidget);
    await tester.tap(find.text('Efectivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar y completar'));
    await tester.pumpAndSettle();
    final d = (await db.collection('tickets').doc('t1').get()).data()!;
    expect(d['status'], 'completada');
    expect(d['paymentMethod'], 'efectivo');
    expect(d['chargeAmount'], 180);
    expect(d['lastChangedByName'], 'Portela');
  });

  testWidgets('«Otros» sin comentario no deja seguir', (tester) async {
    await abrir(tester, {'status': 'en_proceso', 'serviceType': 'desactivacion', 'serviceName': 'Cambio de Domicilio'}, cat);
    await tester.scrollUntilVisible(find.text('Otros'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Otros'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Importe'), '50');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Escribe un comentario'), findsOneWidget);
  });

  testWidgets('sin catálogo de cobros se muestra el aviso y se puede completar sin cobro', (tester) async {
    final db = await abrir(tester, {
      'status': 'en_proceso',
      'serviceType': 'desactivacion',
      'serviceName': 'Cambio de Domicilio',
    }, Catalogos(cobros: const [], servicios: cat.servicios));
    expect(find.textContaining('No hay cobros registrados'), findsOneWidget);
    await tester.tap(find.text('Completar sin cobro'));
    await tester.pumpAndSettle();
    expect((await db.collection('tickets').doc('t1').get()).data()!['status'], 'completada');
  });
}
