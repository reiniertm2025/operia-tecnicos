import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/sistema.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';

void main() {
  setUpAll(FakeFirebaseFirestore.new);
  const admin = Tecnico(userId: 'a1', nombre: 'reinier', esAdmin: true);

  test('llaves como la web: nameId, chargeDocName y areaDocName', () {
    expect(llaveDeNombre('  Fibra  óptica / 1 '), 'Fibra óptica - 1');
    expect(llaveNueva(Catalogo.cobros, {'serviceName': 'Reconexión'}), 'Cobro - Reconexión');
    expect(llaveNueva(Catalogo.zonas, {'name': 'Centro'}, nombreLocalidad: 'Comalcalco'), 'Comalcalco - Centro');
    expect(llaveNueva(Catalogo.comisionistas, {'name': 'Pedro'}), isNull, reason: 'la llave la pone Firebase');
  });

  test('revisar: nombre, repetidos, días e importe', () {
    const existentes = [
      (id: 'Efectivo', datos: <String, dynamic>{'name': 'Efectivo'}),
    ];
    expect(revisarRegistro(Catalogo.formasPago, {'name': ' '}, existentes), FalloSistema.faltaNombre);
    expect(revisarRegistro(Catalogo.formasPago, {'name': 'efectivo'}, existentes), FalloSistema.yaExiste);
    expect(revisarRegistro(Catalogo.formasPago, {'name': 'Tarjeta'}, existentes), isNull);
    final fecha = {
      'payFrom': 1,
      'payTo': 5,
      'invoiceDay': 32,
      'installFrom': 25,
      'installTo': 31,
      'zoneIds': <String>[],
    };
    expect(revisarRegistro(Catalogo.fechasPago, fecha, const []), FalloSistema.dia);
    expect(revisarRegistro(Catalogo.comisiones, {'name': 'X', 'amount': -1}, const []), FalloSistema.importe);
    expect(revisarRegistro(Catalogo.zonas, {'name': 'Centro'}, const []), FalloSistema.localidad);
  });

  test('revisar: importe obligatorio, «Otros», categoría, llave ocupada y fechas que chocan', () {
    expect(revisarRegistro(Catalogo.comisiones, {'name': 'X'}, const []), FalloSistema.importe);
    expect(revisarRegistro(Catalogo.cobros, {'serviceName': 'Reconexión'}, const []), isNull, reason: 'cobro abierto');
    expect(revisarRegistro(Catalogo.cobros, {'serviceName': 'Cambio'}, const []), FalloSistema.importe);
    expect(revisarRegistro(Catalogo.motivosCancelacion, {'name': 'otros'}, const []), FalloSistema.yaExiste);
    expect(revisarRegistro(Catalogo.activos, {'name': 'Módem'}, const []), FalloSistema.categoria);
    const llaveOcupada = [
      (id: 'Centro', datos: <String, dynamic>{'name': 'Otro'}),
    ];
    expect(revisarRegistro(Catalogo.ocupaciones, {'name': 'Centro'}, llaveOcupada), FalloSistema.yaExiste);
    Map<String, dynamic> fecha(int de, int a, List<String> zonas) => {
      'payFrom': 1,
      'payTo': 5,
      'invoiceDay': 1,
      'installFrom': de,
      'installTo': a,
      'zoneIds': zonas,
    };
    final otra = [
      (id: 'f1', datos: fecha(25, 5, ['Paraíso'])),
    ];
    expect(revisarRegistro(Catalogo.fechasPago, fecha(3, 10, ['Paraíso']), otra), FalloSistema.fechaChoca);
    expect(revisarRegistro(Catalogo.fechasPago, fecha(6, 10, ['Paraíso']), otra), isNull);
    expect(revisarRegistro(Catalogo.fechasPago, fecha(3, 10, ['Centla']), otra), isNull, reason: 'otra localidad');
    expect(
      revisarRegistro(Catalogo.fechasPago, fecha(3, 10, ['Paraíso']), otra, antes: otra.first),
      isNull,
      reason: 'no choca consigo misma',
    );
  });

  test('al editar: campos fijos y catálogos sin nada que cambiar', () {
    const r = (id: 'Efectivo', datos: <String, dynamic>{'name': 'Efectivo'});
    expect(camposFijos(Catalogo.formasPago, null), isEmpty);
    expect(camposFijos(Catalogo.formasPago, r), contains('name'));
    expect(nadaQueCambiar(Catalogo.formasPago, r), isTrue);
    expect(nadaQueCambiar(Catalogo.formasPago, null), isFalse);
    expect(nadaQueCambiar(Catalogo.localidades, (id: 'P', datos: const {'name': 'P'})), isFalse);
  });

  test('datos al crear y al cambiar, como los formularios de la web', () {
    final nueva = datosRegistro(
      Catalogo.localidades,
      {'name': 'Paraíso', 'description': 'Costa'},
      existentes: const [],
      userId: 'a1',
      nombre: 'reinier',
    );
    expect((nueva['name'], nueva['active'], (nueva['payDays'] as List).length), ('Paraíso', true, 6));
    final cambio = datosRegistro(
      Catalogo.localidades,
      {'name': 'Otro nombre', 'description': 'Playa'},
      antes: (id: 'Paraíso', datos: const {'name': 'Paraíso'}),
      existentes: const [],
      userId: 'a1',
      nombre: 'reinier',
    );
    expect(cambio.containsKey('name'), isFalse, reason: 'el nombre es la llave: se cambia en la web');
    expect(cambio['description'], 'Playa');
    final motivo = datosRegistro(
      Catalogo.motivosCancelacion,
      {'name': 'Se muda', 'description': ''},
      existentes: const [
        (id: 'a', datos: <String, dynamic>{'order': 2}),
        (id: 'Otros', datos: <String, dynamic>{'order': 9, 'other': true}),
      ],
      userId: 'a1',
      nombre: 'reinier',
    );
    expect(motivo['order'], 3, reason: 'después del último, sin contar «Otros»');
    final insumo = datosRegistro(
      Catalogo.insumos,
      {'name': 'Fibra', 'price': 2.5},
      existentes: const [],
      userId: 'a1',
      nombre: 'r',
    );
    expect(insumo['categoryId'], '');
    expect(sePuedeBorrar(Catalogo.servicios, (id: 'falla', datos: const {})), isFalse);
    expect(sePuedeBorrar(Catalogo.motivosCancelacion, (id: 'Otros', datos: const {'other': true})), isFalse);
    expect(sePuedeBorrar(Catalogo.roles, (id: 'Técnico', datos: const {})), isTrue);
  });

  test('servicio: crear con su llave, cambiar y borrar a la Papelera con sus zonas', () async {
    final db = FakeFirebaseFirestore();
    final s = ServicioOrdenes(db: db);
    await s.guardarRegistro(Catalogo.localidades, {'name': 'Paraíso', 'description': ''}, admin, existentes: const []);
    expect((await db.collection('zones').doc('Paraíso').get()).exists, isTrue);
    await s.guardarRegistro(
      Catalogo.zonas,
      {'name': 'Centro', 'localityId': 'Paraíso'},
      admin,
      existentes: const [],
      nombreLocalidad: 'Paraíso',
    );
    expect((await db.collection('localityZones').doc('Paraíso - Centro').get()).data()!['localityName'], 'Paraíso');
    final r = (id: 'Paraíso', datos: (await db.collection('zones').doc('Paraíso').get()).data()!);
    await s.borrarRegistro(Catalogo.localidades, r, admin);
    expect((await db.collection('zones').doc('Paraíso').get()).exists, isFalse);
    expect((await db.collection('localityZones').doc('Paraíso - Centro').get()).exists, isFalse);
    final papelera = (await db.collection('trash').get()).docs.map((d) => d.data()).toList();
    final principal = papelera.firstWhere((d) => d['col'] == 'zones');
    expect((principal['label'], (principal['relatedIds'] as List).length), ('Paraíso', 1));
    expect(papelera.firstWhere((d) => d['col'] == 'localityZones')['deletedAt'], isA<Timestamp>());
  });
}
