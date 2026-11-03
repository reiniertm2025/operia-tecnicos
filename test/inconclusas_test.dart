import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/inconclusas.dart';
import 'package:torrexi_tecnicos/logica/orden.dart';
import 'package:torrexi_tecnicos/servicios/ordenes.dart';
import 'package:torrexi_tecnicos/servicios/sesion.dart';

Orden inc(String id, String dia, {String zona = 'Tecolutilla'}) =>
    Orden(id, {'status': 'completada', 'incPending': true, 'incDue': dia, 'zoneId': zona});

void main() {
  setUpAll(FakeFirebaseFirestore.new);

  test('semáforo y orden como incLight/incSort de la web', () {
    const hoy = '2026-11-02';
    expect(luzInconclusa(inc('a', '2026-11-01'), hoy), LuzInconclusa.atrasada);
    expect(luzInconclusa(inc('b', '2026-11-02'), hoy), LuzInconclusa.hoy);
    expect(luzInconclusa(inc('c', '2026-11-09'), hoy), LuzInconclusa.proxima);
    expect(luzInconclusa(inc('d', ''), hoy), LuzInconclusa.proxima, reason: 'sin fecha cuenta como próxima');
    final l = ordenarInconclusas([
      inc('c', '2026-11-09'),
      inc('d', ''),
      inc('b', '2026-11-02'),
      inc('a', '2026-10-01'),
    ], hoy);
    expect(l.map((o) => o.id), ['a', 'b', 'c', 'd']);
  });

  test('marcar la primera vez guarda quién y borra lo resuelto antes; cambiarla no', () {
    final d = datosInconclusa(
      Orden('x', const {'status': 'completada'}),
      dia: '2026-11-05',
      motivo: 'Falta material',
      userId: 'u1',
      nombre: 'Ana',
    );
    expect(
      (d['incPending'], d['incDue'], d['incReason'], d['incByName']),
      (true, '2026-11-05', 'Falta material', 'Ana'),
    );
    expect(d['incResolvedAt'], isA<FieldValue>());
    final cambio = datosInconclusa(
      inc('y', '2026-11-05'),
      dia: '2026-11-06',
      motivo: 'Otro',
      userId: 'u1',
      nombre: 'Ana',
    );
    expect(cambio.containsKey('incByName'), isFalse);
    expect(datosResolverInconclusa('u1', 'Ana')['incPending'], false);
  });

  test('servicio: el técnico ve las de sus localidades y las suyas; marcar y resolver', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('tickets').doc('a').set(inc('a', '2026-11-05').datos);
    await db.collection('tickets').doc('b').set(inc('b', '2026-11-05', zona: 'Otra').datos);
    await db.collection('tickets').doc('c').set({
      ...inc('c', '2026-11-05', zona: 'Otra').datos,
      'assignedTechId': 'u1',
    });
    await db.collection('tickets').doc('d').set({'status': 'completada', 'zoneId': 'Tecolutilla'});
    final s = ServicioOrdenes(db: db);
    const tecnico = Tecnico(userId: 'u1', nombre: 'Ana', zonas: ['Tecolutilla']);
    expect((await s.inconclusas(tecnico).first).map((o) => o.id).toSet(), {'a', 'c'});
    final d = Orden('d', (await db.collection('tickets').doc('d').get()).data()!);
    await s.marcarInconclusa(d, '2026-11-06', 'Falta material', tecnico);
    expect((await db.collection('tickets').doc('d').get()).data()!['incPending'], true);
    await s.resolverInconclusa(d, tecnico);
    expect((await db.collection('tickets').doc('d').get()).data()!['incResolvedByName'], 'Ana');
  });
}
