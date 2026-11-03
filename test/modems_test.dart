import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/modems.dart';
import 'package:torrexi_tecnicos/logica/orden.dart';
import 'package:torrexi_tecnicos/servicios/ordenes.dart';
import 'package:torrexi_tecnicos/servicios/sesion.dart';

/// Catálogo de Sistema › Comisiones con la forma de la web.
final catalogo = [
  {'id': 'Nuevo Servicio', 'name': 'Nuevo Servicio', 'amount': 150},
  {'id': 'Recuperar Modem Internet', 'name': 'Recuperar Modem Internet', 'amount': '50'},
  {'id': 'Recuperar Modem Doble Play', 'name': 'Recuperar Modem Doble Play', 'amount': 80},
];

void main() {
  setUpAll(FakeFirebaseFirestore.new);
  const tecnico = Tecnico(userId: 'u1', nombre: 'Portela', zonas: ['Tecolutilla']);

  Orden baja(
    String id, {
    String equipo = 'internet',
    String estado = 'pendiente',
    String? quien,
    String zona = 'Tecolutilla',
  }) => Orden(id, {
    'status': 'completada',
    'zoneId': zona,
    'bajaEquipment': equipo,
    'modemStatus': estado,
    'modemRecoveryById': ?quien,
  });

  test('estado del módem y comisión del catálogo, como la web', () {
    expect(estadoModem(baja('a')), EstadoModem.sinAsignar);
    expect(estadoModem(baja('b', estado: 'asignado', quien: 'u1')), EstadoModem.asignado);
    expect(estadoModem(baja('c', estado: 'recuperado', quien: 'u1')), EstadoModem.recuperado);
    expect(comisionModem(catalogo, doblePlay: false)?['id'], 'Recuperar Modem Internet');
    expect(comisionDeModem(baja('d', equipo: 'doble_play'), catalogo), 80);
    expect(comisionDeModem(Orden('e', {'bajaEquipment': 'internet', 'modemCommissionAmount': 65}), catalogo), 65);
    expect(esBajaConModem(Orden('f', {'status': 'pendiente'})), isFalse);
  });

  test('asignar, recuperar y soltar guardan los mismos campos que la web', () {
    final a = datosAsignarModem(baja('a'), catalogo, uid: 'u1', uNombre: 'Portela', userId: 'u1', nombre: 'Portela');
    expect(a['modemStatus'], 'asignado');
    expect(a['modemRecoveryByName'], 'Portela');
    expect(a['modemCommissionAmount'], 50);
    expect(a['modemAssignedAt'], isA<FieldValue>());
    final r = datosModemRecuperado(baja('a', estado: 'asignado', quien: 'u1'), catalogo, 'u1', 'Portela');
    expect(r['modemStatus'], 'recuperado');
    expect(r['modemRecoveredByName'], 'Portela');
    expect(r['modemCommissionName'], 'Recuperar Modem Internet');
    final s = datosAsignarModem(baja('a'), catalogo, uid: '', uNombre: '', userId: 'u1', nombre: 'Portela');
    expect(s['modemStatus'], 'pendiente');
    expect(s['modemRecoveryById'], '');
  });

  test('pago de comisiones: por comisionista, con instalaciones, módems y los de Importados ISP', () {
    final nov = DateTime(2026, 11, 10);
    final ordenes = [
      Orden('i1', {
        'commission': true,
        'referrerId': 'cm1',
        'referrerName': 'Reinier',
        'status': 'completada',
        'completedAt': Timestamp.fromDate(nov),
        'commissionAmount': 150,
        'cpCashDelivered': true,
      }),
      Orden('i2', {'commission': true, 'referrerId': 'cm1', 'status': 'en_proceso', 'commissionAmount': 150}),
      Orden('i3', {
        'commission': true,
        'referrerId': 'cm2',
        'status': 'completada',
        'completedAt': Timestamp.fromDate(DateTime(2026, 10, 2)),
        'commissionAmount': 150,
      }),
      Orden('m1', {
        'bajaEquipment': 'doble_play',
        'serviceName': 'Cancelar Servicio Definitivo',
        'modemStatus': 'recuperado',
        'modemRecoveryById': 'cm2',
        'modemRecoveryByName': 'Pedro',
        'modemRecoveredAt': Timestamp.fromDate(nov),
      }),
    ];
    final isp = [
      ordenDeIsp('x', {
        'name': 'Luis',
        'kind': 'internet',
        'recoveredById': 'cm1',
        'recoveredDay': '2026-11-05',
        'commissionAmount': 40,
      }),
    ];
    final l = pagoDeComisiones(
      ordenes: ordenes,
      isp: isp,
      comisiones: catalogo,
      comisionistas: const {'cm1': 'Reinier', 'cm2': 'Pedro'},
      desde: DateTime(2026, 11, 1),
      hastaExclusivo: DateTime(2026, 12, 1),
    );
    expect(l.map((c) => c.orden.id).toSet(), {'i1', 'm1', 'isp:x'});
    expect(totalComisiones(l), 150 + 80 + 40);
    expect(totalComisiones(l, entregada: false), 120);
    final g = porComisionista(l);
    expect(g.map((x) => (x.quien, totalComisiones(x.filas))), [('Reinier', 190.0), ('Pedro', 80.0)]);
  });

  test('con base simulada: el técnico ve los de su localidad y los suyos, y se lleva uno', () async {
    final db = FakeFirebaseFirestore();
    Future<void> poner(Orden o) => db.collection('tickets').doc(o.id).set(o.datos);
    await poner(baja('libre'));
    await poner(baja('otra-zona', zona: 'Otra'));
    await poner(baja('mio-lejos', estado: 'asignado', quien: 'u1', zona: 'Otra'));
    await poner(baja('ya', estado: 'recuperado', quien: 'u1'));
    for (final c in catalogo) {
      await db.collection('commissions').doc('${c['id']}').set(c);
    }
    final servicio = ServicioOrdenes(db: db);
    final lista = await servicio.modemsPorRecuperar(tecnico).first;
    expect(lista.map((o) => o.id).toSet(), {'libre', 'mio-lejos'});
    await servicio.asignarModem(lista.firstWhere((o) => o.id == 'libre'), 'u1', 'Portela', tecnico);
    final d = (await db.collection('tickets').doc('libre').get()).data()!;
    expect(d['modemStatus'], 'asignado');
    expect(d['modemRecoveryById'], 'u1');
    // otro técnico ya no se lo puede quitar
    const otro = Tecnico(userId: 'u2', nombre: 'Juan', zonas: ['Tecolutilla']);
    expect(
      () => servicio.asignarModem(Orden('libre', d), 'u2', 'Juan', otro),
      throwsA(isA<ErrorDeOrden>().having((e) => e.fallo, 'fallo', FalloOrden.yaTomada)),
    );
  });

  test('con base simulada: comisiones del periodo (también Importados ISP) y nombres de los comisionistas', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('commissioners').doc('cm1').set({'name': 'Reinier'});
    await db.collection('users').doc('u1').set({'name': 'reinier'});
    await db.collection('tickets').doc('292-TECO').set({
      'referrerId': 'cm1',
      'commission': true,
      'status': 'completada',
      'completedAt': Timestamp.fromDate(DateTime(2026, 11, 2, 19)),
    });
    await db.collection('tickets').doc('viejo').set({'completedAt': Timestamp.fromDate(DateTime(2026, 9, 1))});
    await db.collection('ispCancels').doc('a').set({
      'status': 'recuperado',
      'recoveredById': 'cm1',
      'recoveredDay': '2026-11-03',
    });
    await db.collection('ispCancels').doc('b').set({
      'status': 'recuperado',
      'recoveredDay': '2026-11-03',
      'reconTicketId': 't9',
    });
    final s = ServicioOrdenes(db: db);
    final r = await s.comisionesDelPeriodo(DateTime(2026, 11, 1), DateTime(2026, 12, 1));
    expect(r.ordenes.map((o) => o.id), ['292-TECO']);
    expect(r.isp.map((o) => o.id), ['isp:a']);
    final nombres = await s.nombresParaComisiones();
    expect(nombres.comisionistas['cm1'], 'Reinier');
    expect(nombres.usuarios['u1'], 'reinier');
  });
}
