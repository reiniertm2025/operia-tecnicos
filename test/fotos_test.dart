import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/cobro.dart';
import 'package:operia_tecnicos/logica/fotos.dart';
import 'package:operia_tecnicos/logica/orden.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';

void main() {
  setUpAll(FakeFirebaseFirestore.new);
  const tecnico = Tecnico(userId: 'u1', nombre: 'Ana');

  test('cuántas fotos y cambios como phSave de la web', () {
    expect(cuantasFotos(Orden('a', {'photoCount': 3})), 3);
    expect(cuantasFotos(Orden('b', {'hasPhoto': true})), 1);
    expect(fotoVieja(Orden('b', {'hasPhoto': true})), isTrue);
    final c = cambiosDeFotos(
      Orden('x', {'photoCount': 3}),
      ['f0', 'f1', 'f2'],
      ['f0', 'nueva'],
      userId: 'u1',
      nombre: 'Ana',
    );
    expect(c.fotos.keys.toSet(), {'tickets__x_1', 'tickets__x_2'});
    expect(c.fotos['tickets__x_1']!['photo'], 'nueva');
    expect(c.fotos['tickets__x_2'], isNull, reason: 'la que sobra se borra');
    expect((c.orden['hasPhoto'], c.orden['photoCount']), (true, 2));
    // la foto vieja sin número se vuelve a escribir con número y se borra la vieja
    final v = cambiosDeFotos(Orden('y', {'hasPhoto': true}), ['f0'], ['f0', 'f1'], userId: 'u1', nombre: 'Ana');
    expect(v.fotos.keys.toSet(), {'tickets__y_0', 'tickets__y_1', 'tickets__y'});
    expect(v.fotos['tickets__y'], isNull);
  });

  test('servicio: lee y guarda las fotos de la orden', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('tickets').doc('x').set({'photoCount': 1});
    await db.collection('orderPhotos').doc('tickets__x_0').set({'photo': 'f0'});
    final s = ServicioOrdenes(db: db);
    final o = Orden('x', (await db.collection('tickets').doc('x').get()).data()!);
    expect(await s.fotosDeOrden(o), ['f0']);
    await s.guardarFotos(o, ['f0'], ['f0', 'f1'], tecnico);
    expect((await db.collection('orderPhotos').doc('tickets__x_1').get()).data()!['photo'], 'f1');
    expect((await db.collection('tickets').doc('x').get()).data()!['photoCount'], 2);
  });

  test('comprobante de transferencia: archivo aparte y resumen en la orden, como savePayment', () async {
    final o = Orden('042-TECO', {'folio': '042-TECO', 'status': 'en_proceso', 'serviceType': 'cambio'});
    final c = datosComprobante(o, 'data:image/jpeg;base64,AAAA', userId: 'u1', nombre: 'Ana');
    expect(
      (c.archivo['ticketId'], c.archivo['dataUrl'], c.archivo['name'], c.archivo['type'], c.archivo['size']),
      ('042-TECO', 'data:image/jpeg;base64,AAAA', 'comprobante-042-TECO.jpg', 'image/jpeg', 3),
    );
    expect((c.resumen['paymentProof'] as Map)['byName'], 'Ana');
    expect((c.resumen['paymentProof'] as Map).containsKey('dataUrl'), isFalse, reason: 'la foto no infla la orden');

    final db = FakeFirebaseFirestore();
    await db.collection('tickets').doc(o.id).set(o.datos);
    await ServicioOrdenes(db: db)
        .cobrar(o, const [], FormaPago.transferencia, tecnico, comprobante: 'data:image/jpeg;base64,AAAA');
    expect((await db.collection('payProofs').doc(o.id).get()).data()!['ticketId'], '042-TECO');
    final t = (await db.collection('tickets').doc(o.id).get()).data()!;
    expect((t['techPayMethod'], (t['paymentProof'] as Map)['name']), ('transferencia', 'comprobante-042-TECO.jpg'));
  });
}
