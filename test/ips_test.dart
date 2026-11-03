import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/l10n/textos.dart';
import 'package:operia_tecnicos/logica/ips.dart';
import 'package:operia_tecnicos/pantallas/ips.dart';
import 'package:operia_tecnicos/servicios/ips.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';

/// Un segmento con la forma que publica la web (Herramientas › IPs libres › «Publicar en la app»).
Map<String, dynamic> segmento(
  String base,
  String vlan,
  String zona,
  List<String> libres, [
  Map<String, dynamic> apartadas = const {},
]) => {
  'segment': '$base.0/24',
  'label': '$base.x',
  'vlan': vlan,
  'zoneId': zona,
  'free': libres,
  'used': 10,
  'arpAt': '2026-10-30T16:23',
  'taken': apartadas,
};

void main() {
  const tecnico = Tecnico(userId: 'u1', nombre: 'Portela', zonas: ['Tecolutilla']);

  final segs = [
    SegmentoIp(
      'a',
      segmento(
        '192.168.100',
        '20',
        'Tecolutilla',
        ['192.168.100.5', '192.168.100.6'],
        {
          '192_168_100_6': {'byId': 'u2', 'byName': 'Juan', 'day': '2026-11-01', 'from': 'web'},
        },
      ),
    ),
    SegmentoIp(
      'b',
      segmento(
        '192.168.88',
        '20',
        'Tecolutilla',
        ['192.168.88.9'],
        {
          '192_168_88_9': {'byId': 'u1', 'byName': 'Portela', 'day': '2026-11-02', 'from': 'app'},
        },
      ),
    ),
    SegmentoIp('c', segmento('10.0.0', '9', 'Tecolutilla', ['10.0.0.2'])),
  ];

  test('se ordena por VLAN y segmento con los números como números', () {
    expect(ordenarSegmentos(segs, const {}).map((s) => s.id), ['c', 'b', 'a']);
  });

  test('filtros: libres, ocupadas, mías, todas y búsqueda', () {
    List<String> ips(MostrarIps m, [String q = '']) =>
        filasIp(segs, userId: 'u1', mostrar: m, buscar: q).map((f) => f.ip).toList();
    expect(ips(MostrarIps.libres), ['192.168.100.5', '10.0.0.2']);
    expect(ips(MostrarIps.ocupadas), ['192.168.100.6', '192.168.88.9']);
    expect(ips(MostrarIps.mias), ['192.168.88.9']);
    expect(ips(MostrarIps.todas).length, 4);
    expect(ips(MostrarIps.todas, 'VLAN9'), ['10.0.0.2']);
    expect(ips(MostrarIps.todas, '88.x'), ['192.168.88.9']);
  });

  test('libera quien la apartó o un administrador', () {
    final ajena = segs[0].apartadaDe('192.168.100.6')!;
    expect(ajena.desdeApp, isFalse);
    expect(puedeLiberar(ajena, 'u1', esAdmin: false), isFalse);
    expect(puedeLiberar(ajena, 'a1', esAdmin: true), isTrue);
    expect(puedeLiberar(segs[1].apartadaDe('192.168.88.9')!, 'u1', esAdmin: false), isTrue);
  });

  test('al apartar se guarda igual que la web, marcado «desde la app»', () {
    final d = datosApartar('192.168.88.5', 'u1', 'Portela', DateTime(2026, 11, 2, 9, 30));
    expect(d.keys, ['taken.192_168_88_5']);
    expect(d['taken.192_168_88_5'], {
      'byId': 'u1',
      'byName': 'Portela',
      'day': '2026-11-02',
      'at': DateTime(2026, 11, 2, 9, 30).millisecondsSinceEpoch,
      'from': 'app',
    });
  });

  group('pantalla con base simulada', () {
    Future<FakeFirebaseFirestore> abrir(WidgetTester tester, {Tecnico quien = tecnico}) async {
      final db = FakeFirebaseFirestore();
      await db.collection('ipSegments').doc('192-168-88-0').set(segmento('192.168.88', '20', 'Tecolutilla', ['192.168.88.5']));
      await db.collection('ipSegments').doc('10-0-0-0').set(segmento('10.0.0', '9', 'Otra', ['10.0.0.2']));
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
          home: PantallaIps(
            tecnico: quien,
            nombresZonas: const {},
            servicio: ServicioIps(db: db),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return db;
    }

    testWidgets('el técnico ve solo su localidad, aparta una IP y la libera', (tester) async {
      final db = await abrir(tester);
      expect(find.text('192.168.88.5'), findsOneWidget);
      expect(find.text('10.0.0.2'), findsNothing);
      await tester.tap(find.text('Apartar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Apartar').last);
      await tester.pumpAndSettle();
      final d = (await db.collection('ipSegments').doc('192-168-88-0').get()).data()!;
      expect(d['taken']['192_168_88_5']['byName'], 'Portela');
      expect(d['taken']['192_168_88_5']['from'], 'app');
      expect(find.textContaining('Apartaste la IP 192.168.88.5'), findsOneWidget);
      // ahora sale en «Mías» y se puede liberar
      await tester.tap(find.text('Mías'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Liberar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Liberar'));
      await tester.pumpAndSettle();
      expect((await db.collection('ipSegments').doc('192-168-88-0').get()).data()!['taken'], isEmpty);
    });

    testWidgets('si otro la apartó un momento antes, avisa y no la pisa', (tester) async {
      final db = await abrir(tester);
      await tester.tap(find.text('Apartar'));
      await tester.pumpAndSettle();
      await db.collection('ipSegments').doc('192-168-88-0').update({
        'taken.192_168_88_5': {'byId': 'u2', 'byName': 'Juan', 'day': '2026-11-02', 'from': 'web'},
      });
      await tester.tap(find.widgetWithText(FilledButton, 'Apartar').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('ya no está libre'), findsOneWidget);
      final d = (await db.collection('ipSegments').doc('192-168-88-0').get()).data()!;
      expect(d['taken']['192_168_88_5']['byName'], 'Juan');
    });

    testWidgets('se filtra por VLAN y después se marcan los segmentos', (tester) async {
      final db = await abrir(tester);
      await db.collection('ipSegments').doc('192-168-89-0').set(segmento('192.168.89', '20', 'Tecolutilla', ['192.168.89.7']));
      await db.collection('ipSegments').doc('10-1-1-0').set(segmento('10.1.1', '120', 'Tecolutilla', ['10.1.1.3']));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'VLAN 20'));
      await tester.pumpAndSettle();
      expect(find.text('10.1.1.3'), findsNothing);
      expect(find.text('192.168.88.5'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, '192.168.89.x · 1 libre'));
      await tester.pumpAndSettle();
      expect(find.text('192.168.88.5'), findsNothing);
      expect(find.text('192.168.89.7'), findsOneWidget);
    });

    testWidgets('el usuario de consulta ve las IPs pero no puede apartar', (tester) async {
      await abrir(
        tester,
        quien: const Tecnico(userId: 'c1', nombre: 'Sup', zonas: ['Tecolutilla'], soloMirar: true),
      );
      expect(find.text('192.168.88.5'), findsOneWidget);
      expect(find.text('Apartar'), findsNothing);
    });
  });
}
