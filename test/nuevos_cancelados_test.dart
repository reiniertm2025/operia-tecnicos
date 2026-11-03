import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/cobro.dart';
import 'package:torrexi_tecnicos/logica/nuevos_cancelados.dart';
import 'package:torrexi_tecnicos/logica/orden.dart';
import 'package:torrexi_tecnicos/servicios/ordenes.dart';

// las mismas fechas de pago de ejemplo que las pruebas de la web (src/features/zones/pay-dates.test.ts)
const p1 = FechaPago('p1', pagoDe: 1, pagoA: 5, factura: 28, instalaDe: 25, instalaA: 31);
const p15 = FechaPago('p15', pagoDe: 15, pagoA: 19, factura: 12, instalaDe: 10, instalaA: 15);

const cat = Catalogos(
  cobros: [],
  servicios: {
    'nuevo': {'name': 'Nuevo Servicio', 'commission': true},
    'falla': {'name': 'Falla'},
  },
);

void main() {
  setUpAll(FakeFirebaseFirestore.new);

  test('ciclo de pago igual que payCycle de la web', () {
    expect(cicloDePago('2026-10-25', p1), (pagoInicio: '2026-11-01', pagoFin: '2026-11-05', factura: '2026-10-28'));
    expect(cicloDePago('2026-10-31', p1), (pagoInicio: '2026-11-01', pagoFin: '2026-11-05', factura: '2026-10-28'));
    expect(cicloDePago('2026-12-27', p1), (pagoInicio: '2027-01-01', pagoFin: '2027-01-05', factura: '2026-12-28'));
    expect(cicloDePago('2026-10-10', p15), (pagoInicio: '2026-10-15', pagoFin: '2026-10-19', factura: '2026-10-12'));
    expect(cicloDePago('2026-10-15', p15), (pagoInicio: '2026-10-15', pagoFin: '2026-10-19', factura: '2026-10-12'));
    expect(cicloDePago('2026-10-20', p1), isNull);
    expect(cicloDePago('2026-10-09', p15), isNull);
    expect(cicloDePago('', p1), isNull);
    const corto = FechaPago('c', pagoDe: 30, pagoA: 31, factura: 31, instalaDe: 20, instalaA: 29);
    expect(cicloDePago('2027-02-20', corto), (pagoInicio: '2027-02-28', pagoFin: '2027-02-28', factura: '2027-02-28'));
  });

  test('filas de Eliminar factura del ISP: servicio nuevo completado, por localidad, y si ya se marcó', () {
    Orden nueva(String id, String zona, {bool hecha = false}) => Orden(id, {
      'status': 'completada',
      'serviceType': 'nuevo',
      'zoneId': zona,
      'completedAt': Timestamp.fromDate(DateTime(2026, 10, 26, 12)),
      if (hecha) 'ispInvoice': {'done': true},
    });
    final fechas = [
      const FechaPago('a', pagoDe: 1, pagoA: 5, factura: 28, instalaDe: 25, instalaA: 31, zonas: ['teco']),
      const FechaPago('b', pagoDe: 1, pagoA: 5, factura: 27, instalaDe: 25, instalaA: 31),
    ];
    final filas = filasFactura(
      [
        nueva('x', 'teco'),
        nueva('y', 'coma', hecha: true),
        Orden('z', {
          'status': 'completada',
          'serviceType': 'falla',
          'completedAt': Timestamp.fromDate(DateTime(2026, 10, 26)),
        }),
      ],
      fechas,
      cat,
    );
    expect(filas.map((f) => (f.orden.id, f.fecha.id, f.hecha)), [('y', 'b', true), ('x', 'a', false)]);
    final d = datosFacturaEliminada(filas.last, 'u1', 'reinier')['ispInvoice'] as Map;
    expect((d['done'], d['payDateId'], d['invoiceDate'], d['byName']), (true, 'a', '2026-10-28', 'reinier'));
  });

  test('cancelaciones de TV, cuándo toca y futuro como la web', () {
    expect(cancelacionTv(Orden('a', const {'serviceName': 'Cancelar Servicio TV Doble Play'}), cat), CancelTv.fibra);
    expect(cancelacionTv(Orden('b', const {'serviceName': 'Cancelar Servicio TV Cable'}), cat), CancelTv.cable);
    expect(cancelacionTv(Orden('c', const {'serviceName': 'Cancelar Servicio Definitivo'}), cat), isNull);
    const hoy = '2026-11-03';
    expect(cuandoToca(Orden('d', const {'workDate': '2026-11-01'}), hoy), (cuando: CuandoToca.atrasada, dias: 2));
    expect(cuandoToca(Orden('e', const {'workDate': '2026-11-03'}), hoy), (cuando: CuandoToca.hoy, dias: 0));
    expect(cuandoToca(Orden('f', const {'workDate': '2026-11-04'}), hoy), (cuando: CuandoToca.futura, dias: 1));
    expect(esFutura(Orden('g', const {'status': 'pendiente', 'workDate': '2026-11-04'}), hoy), isTrue);
    expect(esFutura(Orden('h', const {'status': 'completada', 'workDate': '2026-11-04'}), hoy), isFalse);
    expect(esNuevoCancelado(Orden('i', const {'serviceType': 'nuevo', 'cancelled': true}), cat), isTrue);
    expect(esNuevoHistorico(Orden('i', const {'serviceType': 'nuevo', 'cancelled': true}), cat), isFalse);
  });

  test('definitivos como isBajaTicket de la web, con el nombre del catálogo', () {
    const c = Catalogos(
      cobros: [],
      servicios: {
        'def': {'name': 'Cancelar Servicio Definitivo'},
        'temp': {'name': 'Cancelación temporal'},
        'tv': {'name': 'Cancelar Servicio TV Cable'},
        'viejo': {'name': 'Baja'},
      },
    );
    expect(esBajaDefinitiva(Orden('a', const {'serviceType': 'def'}), c), isTrue);
    expect(esBajaDefinitiva(Orden('b', const {'serviceType': 'viejo', 'serviceName': 'otro nombre'}), c), isTrue);
    expect(esBajaDefinitiva(Orden('c', const {'serviceType': 'temp'}), c), isFalse);
    expect(esBajaDefinitiva(Orden('d', const {'serviceType': 'tv'}), c), isFalse);
    expect(esBajaDefinitiva(Orden('e', const {'serviceName': 'Falla', 'bajaEquipment': 'internet'}), c), isTrue);
    expect(diasEntre('2026-03-07', '2026-03-09'), 2, reason: 'el cambio de horario no mueve los días');
  });

  test('temporales: luz como tcLight de la web', () {
    const hoy = '2026-11-03';
    expect(luzTemporal(const Temporal('a', {'activationDate': '2026-11-03'}), hoy), LuzTemporal.vencida);
    expect(luzTemporal(const Temporal('b', {'activationDate': '2026-11-06'}), hoy), LuzTemporal.pronto);
    expect(luzTemporal(const Temporal('c', {'activationDate': '2026-11-20'}), hoy), LuzTemporal.ninguna);
    expect(
      luzTemporal(const Temporal('d', {'activationDate': '2026-11-01', 'status': 'reactivado'}), hoy),
      LuzTemporal.ninguna,
    );
  });

  test('servicio: órdenes por día de servicio (workDate o el día en que se creó)', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('tickets').doc('a').set({'workDate': '2026-11-05'});
    await db.collection('tickets').doc('b').set({'createdAt': Timestamp.fromDate(DateTime(2026, 11, 2, 10))});
    await db.collection('tickets').doc('c').set({
      'workDate': '2026-12-01',
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 2)),
    });
    final l = await ServicioOrdenes(db: db)
        .ordenesPorDia((desde: DateTime(2026, 11, 1), hasta: DateTime(2026, 11, 30)));
    expect(l.map((o) => o.id).toSet(), {
      'a',
      'b',
    }, reason: 'la c se creó en noviembre pero su día de servicio es diciembre');
  });
}
