import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/cobro.dart';
import 'package:torrexi_tecnicos/logica/finanzas.dart';
import 'package:torrexi_tecnicos/logica/modems.dart';
import 'package:torrexi_tecnicos/logica/orden.dart';
import 'package:torrexi_tecnicos/servicios/ordenes.dart';

const cat = Catalogos(cobros: [], servicios: {});

Finanzas finanzas({List<Map<String, dynamic>> partidas = const [], String? zona}) => Finanzas(
  ingresos: const [
    {
      'dateFrom': '2026-11-01',
      'dateTo': '2026-11-30',
      'paymentMethodName': 'Efectivo',
      'amount': 1000,
      'localityId': 'T',
    },
    {'date': '2026-11-05', 'paymentMethodName': 'Transferencia', 'amount': '500', 'localityId': 'C'},
    {
      'dateFrom': '2026-10-01',
      'dateTo': '2026-10-31',
      'paymentMethodName': 'Efectivo',
      'amount': 999,
      'localityId': 'T',
    },
  ],
  gastos: const [
    {'date': '2026-11-03', 'category': 'Energía', 'amount': 200, 'localityId': 'T'},
    {'date': '2026-12-01', 'category': 'Energía', 'amount': 999, 'localityId': 'T'},
  ],
  partidas: partidas,
  ordenes: [
    Orden('o1', {
      'status': 'completada',
      'zoneId': 'T',
      'serviceType': 'instalacion',
      'paymentMethod': 'efectivo',
      'chargeAmount': 300,
      'completedAt': Timestamp.fromDate(DateTime(2026, 11, 4)),
    }),
    Orden('o2', {
      'status': 'completada',
      'zoneId': 'T',
      'paymentMethod': 'pendiente',
      'chargeAmount': 300,
      'completedAt': Timestamp.fromDate(DateTime(2026, 11, 4)),
    }),
  ],
  comisiones: [
    Comision(
      Orden('i1', const {'zoneId': 'T'}),
      TipoComision.instalacion,
      DateTime(2026, 11, 4),
      150,
      entregada: false,
      clave: 'c:c',
      quien: 'C',
    ),
  ],
  cat: cat,
  desde: DateTime(2026, 11, 1),
  hastaExclusivo: DateTime(2026, 12, 1),
  zona: zona,
  sinFormaDePago: '-',
  otrosGastos: 'Otros',
);

void main() {
  test('ingreso de servicio cuenta si su periodo se cruza con el elegido (incomeInRange)', () {
    expect(ingresoEnRango({'dateFrom': '2026-10-20', 'dateTo': '2026-11-02'}, '2026-11-01', '2026-11-30'), isTrue);
    expect(ingresoEnRango({'date': '2026-10-31'}, '2026-11-01', '2026-11-30'), isFalse);
  });

  test('entradas, salidas y resultado del periodo', () {
    final f = finanzas();
    expect(f.porFormaDePago, [(nombre: 'Efectivo', importe: 1000.0), (nombre: 'Transferencia', importe: 500.0)]);
    expect(f.cobros, 300, reason: 'solo lo cobrado en efectivo o transferencia');
    expect(f.gastosRegistrados, 200);
    expect(f.cuentanComisiones, isTrue, reason: 'sin partidas, la web usa las de siempre (con Comisiones)');
    expect(f.resultado, 1000 + 500 + 300 - 200 - 150);
    final sinPartida = finanzas(
      partidas: const [
        {'name': 'Energía'},
      ],
    );
    expect(sinPartida.cuentanComisiones, isFalse);
    expect(sinPartida.salidas, 200);
    expect(finanzas(zona: 'C').entradas, 500);
  });

  test('servicio: lee ingresos, gastos del periodo y partidas', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('serviceIncome').doc('a').set({'date': '2026-11-02', 'amount': 10});
    await db.collection('expenses').doc('g1').set({'date': '2026-11-02', 'amount': 5});
    await db.collection('expenses').doc('g2').set({'date': '2026-12-02', 'amount': 5});
    await db.collection('expenseCategories').doc('Comisiones').set({'name': 'Comisiones', 'auto': 'comisiones'});
    final r = await ServicioOrdenes(db: db).finanzas(DateTime(2026, 11, 1), DateTime(2026, 12, 1));
    expect(r.ingresos.length, 1);
    expect(r.gastos.map((g) => g['id']), ['g1']);
    expect(r.partidas.single['auto'], 'comisiones');
  });
}
