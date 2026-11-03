import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/cobro.dart';
import 'package:operia_tecnicos/logica/metricas.dart';
import 'package:operia_tecnicos/logica/orden.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';

final cat = Catalogos(
  cobros: const [
    {'id': 'c1', 'serviceId': 'instalacion', 'amount': 500},
  ],
  servicios: const {
    'instalacion': {'name': 'Nuevo Servicio', 'commission': true},
    'falla': {'name': 'Falla / Reparación'},
  },
);

Timestamp dia(int d, [int h = 9]) => Timestamp.fromDate(DateTime(2026, 11, d, h));

Orden orden(String id, Map<String, dynamic> d) => Orden(id, {'zoneId': 'Tecolutilla', ...d});

void main() {
  test('importe cobrado como chargeAmountOf de la web', () {
    expect(
      importeCobrado(
        orden('a', {
          'chargeItems': [
            {'amount': 300, 'manualAmount': 50},
            {'amount': '100'},
          ],
        }),
        cat,
      ),
      450,
    );
    expect(importeCobrado(orden('b', {'chargeAmount': '200', 'chargeManual': 20}), cat), 220);
    expect(importeCobrado(orden('c', {'serviceType': 'instalacion'}), cat), 500, reason: 'el cobro de su servicio');
    expect(importeCobrado(orden('d', {'serviceType': 'falla'}), cat), isNull);
  });

  test('resumen del periodo: estados, cobros, nuevos, pospuestas y tiempo', () {
    final base = [
      orden('1', {
        'status': 'completada',
        'serviceType': 'instalacion',
        'paymentMethod': 'efectivo',
        'createdAt': dia(3, 9),
        'completedAt': dia(3, 13),
      }),
      orden('2', {
        'status': 'completada',
        'serviceType': 'instalacion',
        'paymentMethod': 'pendiente',
        'createdAt': dia(4),
        'completedAt': dia(5, 9),
      }),
      orden('3', {'status': 'pendiente', 'serviceType': 'falla', 'createdAt': dia(5), 'postponeCount': 1}),
      orden('4', {'status': 'en_proceso', 'serviceType': 'falla', 'createdAt': dia(6)}),
      orden('5', {'status': 'pendiente', 'cancelled': true, 'createdAt': dia(6)}),
      orden('6', {'status': 'completada', 'createdAt': dia(20, 9), 'completedAt': dia(20, 10)}),
    ];
    final r = Resumen(base, DateTime(2026, 11, 1), DateTime(2026, 11, 8), cat);
    expect(r.total, 5);
    expect((r.pendientes, r.enProceso, r.completadas, r.canceladas), (1, 1, 2, 1));
    expect(r.abiertas, 2);
    expect(r.nuevos, 2);
    expect(r.pospuestas, 1);
    expect(r.ingresos, 500);
    expect(r.cobros, 1);
    expect(r.porCobrar, 500);
    expect(r.horasPromedio, (4 + 24) / 2);
    expect(r.cumplimiento, 40);

    final zonas = porLocalidad(r, cat);
    expect(zonas.single.recibidas, 5);
    expect(zonas.single.ingresos, 500);
  });

  test('cambio, periodo anterior y tramos por día', () {
    expect(cambio(15, 10), 50);
    expect(cambio(0, 0), 0);
    expect(cambio(3, 0), double.infinity);
    final antes = periodoAnterior(DateTime(2026, 11, 1), DateTime(2026, 11, 8));
    expect(antes.desde, DateTime(2026, 10, 25));
    expect(antes.hastaExclusivo, DateTime(2026, 11, 1));

    final base = [
      orden('1', {'status': 'completada', 'createdAt': dia(1), 'completedAt': dia(2)}),
      orden('2', {'status': 'pendiente', 'createdAt': dia(2)}),
    ];
    final t = tramos(base, DateTime(2026, 11, 1), DateTime(2026, 11, 4));
    expect(t.length, 3);
    expect([for (final x in t) (x.recibidas, x.completadas)], [(1, 0), (1, 1), (0, 0)]);
    expect(unidadDe(DateTime(2026, 1, 1), DateTime(2026, 6, 1)), UnidadTramo.semana);
  });

  test('por técnico: las completadas en el periodo, con el nombre de users', () {
    final base = [
      orden('1', {'status': 'completada', 'acceptedBy': 'u1', 'createdAt': dia(1, 8), 'completedAt': dia(1, 10)}),
      orden('2', {'status': 'completada', 'assignedTechId': 'u1', 'createdAt': dia(1, 8), 'completedAt': dia(1, 12)}),
      orden('3', {'status': 'completada', 'assignedTechName': 'Luis', 'completedAt': dia(2)}),
      orden('4', {'status': 'completada', 'assignedTechId': 'u1', 'completedAt': dia(20)}),
    ];
    final filas = porTecnico(base, DateTime(2026, 11, 1), DateTime(2026, 11, 8), {'u1': 'Ana'});
    expect(filas.map((f) => (f.nombre, f.completadas)), [('Ana', 2), ('Luis', 1)]);
    expect(filas.first.horasPromedio, 3);
  });

  test('técnico mostrado como shownTech de la web: por correo, y si no hay, quien la cerró en la web', () {
    const nombres = {'u1': 'Ana'};
    const correos = {'ana@x.com': 'u1'};
    expect(tecnicoMostrado(orden('a', {'assignedTechEmail': 'ANA@x.com'}), nombres, correos), (
      id: 'u1',
      nombre: 'Ana',
    ));
    expect(tecnicoMostrado(orden('b', {'lastChangedById': 'w9', 'lastChangedByName': 'Oficina'}), nombres, correos), (
      id: 'web:w9',
      nombre: 'Oficina',
    ));
    expect(tecnicoMostrado(orden('c', {}), nombres, correos), (id: '', nombre: ''));
  });

  test('por autorizar como needsPayAuth de la web', () {
    expect(esperaAutorizar(orden('a', {'status': 'en_proceso', 'payAuthStatus': 'solicitada'})), isTrue);
    expect(esperaAutorizar(orden('b', {'status': 'completada', 'paymentMethod': 'sin_costo'})), isTrue);
    expect(
      esperaAutorizar(
        orden('c', {'status': 'completada', 'paymentMethod': 'pendiente', 'payAuthStatus': 'autorizada'}),
      ),
      isFalse,
    );
    expect(esperaAutorizar(orden('d', {'status': 'completada', 'paymentMethod': 'efectivo'})), isFalse);
    expect(
      esperaAutorizar(orden('e', {'status': 'en_proceso', 'serviceType': 'falla', 'payAuthStatus': 'solicitada'})),
      isFalse,
      reason: 'una reparación no se cobra',
    );
  });

  test('servicio: lee el periodo una vez y lo guarda', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('tickets').doc('a').set({'createdAt': dia(3)});
    await db.collection('tickets').doc('b').set({'createdAt': dia(1), 'completedAt': dia(5), 'status': 'completada'});
    await db.collection('tickets').doc('c').set({'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1))});
    final s = ServicioOrdenes(db: db);
    final l = await s.ordenesDelPeriodo(DateTime(2026, 11, 2), DateTime(2026, 11, 4), DateTime(2026, 11, 8));
    expect(l.map((o) => o.id).toSet(), {'a', 'b'});
    await db.collection('tickets').doc('d').set({'createdAt': dia(4)});
    expect((await s.ordenesDelPeriodo(DateTime(2026, 11, 2), DateTime(2026, 11, 4), DateTime(2026, 11, 8))).length, 2);
    expect(
      (await s.ordenesDelPeriodo(
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 8),
        recargar: true,
      )).length,
      3,
    );

    await db.collection('tickets').doc('p').set({'status': 'completada', 'paymentMethod': 'pendiente'});
    await db.collection('tickets').doc('q').set({'status': 'en_proceso', 'payAuthStatus': 'solicitada'});
    expect((await s.porAutorizar().first).map((o) => o.id).toSet(), {'p', 'q'});
  });
}
