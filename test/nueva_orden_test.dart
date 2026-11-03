import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/nueva_orden.dart';
import 'package:operia_tecnicos/logica/orden.dart';
import 'package:operia_tecnicos/logica/telefono.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';

/// Catálogos con la forma de los de la web.
final cat = CatalogosOrden(
  servicios: {
    'falla': {'name': 'Falla / Reparación', 'commission': false, 'order': 1},
    'instalacion': {'name': 'Nuevo Servicio', 'commission': true, 'order': 0},
    'baja': {'name': 'Cancelar Servicio Definitivo', 'order': 2},
    'temporal': {'name': 'Cancelación temporal', 'order': 3},
    'tvdp': {'name': 'Cancelar Servicio TV Doble Play', 'order': 4},
  },
  modems: const [
    CategoriaModem('inter', 'Módem Internet', doblePlay: false),
    CategoriaModem('dp', 'Módem Doble Play', doblePlay: true),
  ],
  comisionistas: const [
    Comisionista('c1', 'Pedro', ['Tecolutilla'], ['nuevo-int', 'nuevo-dp', 'Recuperar Modem Internet']),
  ],
  comisiones: const [
    {'id': 'nuevo-int', 'name': 'Nuevo Internet', 'amount': 100},
    {'id': 'nuevo-dp', 'name': 'Nuevo Doble Play', 'amount': '150'},
    {'id': 'Recuperar Modem Internet', 'name': 'Recuperar Modem Internet', 'amount': 50},
  ],
  motivos: const [MotivoBaja('falta', 'Falta de pago'), MotivoBaja('Otros', 'Otros', otro: true)],
);

DatosOrden base(String servicio, {DateTime? dia}) => DatosOrden()
  ..cliente = 'Ana'
  ..zonaId = 'Tecolutilla'
  ..servicioId = servicio
  ..dia = dia ?? DateTime(2026, 11, 2);

void main() {
  setUpAll(FakeFirebaseFirestore.new);
  const admin = Tecnico(userId: 'a1', nombre: 'reinier', esAdmin: true);
  final ahora = DateTime(2026, 11, 2, 10, 0);

  test('tipo de cada servicio, como la web', () {
    expect(tipoServicio(cat.servicios['falla']), TipoServicio.sencillo);
    expect(tipoServicio(cat.servicios['instalacion']), TipoServicio.nuevo);
    expect(tipoServicio({'name': 'Nuevo Servicio'}), TipoServicio.nuevo);
    expect(tipoServicio(cat.servicios['baja']), TipoServicio.baja);
    expect(tipoServicio({'name': 'Baja'}), TipoServicio.baja);
    expect(tipoServicio(cat.servicios['temporal']), TipoServicio.temporal);
    expect(tipoServicio(cat.servicios['tvdp']), TipoServicio.tvFibra);
    expect(tipoServicio({'name': 'Cancelar TV Cable'}), TipoServicio.tvCable);
    expect(tipoServicio({'name': 'Cancelación TV'}), TipoServicio.sencillo, reason: 'sin decir de cuál no es de TV');
  });

  test('teléfono de cualquier país, guardado como la web', () {
    expect(telefonoInternacional('993 123 4567', 'MX'), '+52 993 123 4567');
    expect(telefonoInternacional('', 'MX'), '');
    expect(telefonoInternacional('12345', 'MX'), isNull);
    expect(telefonoInternacional('(213) 373-4253', 'US'), '+1 213 373 4253');
    expect(telefonoInternacional('612 345 678', 'ES'), startsWith('+34 '));
    expect(telefonoInternacional('+57 300 1234567', 'MX'), isNull, reason: 'de otro país: hay que cambiar el país');
    expect(telefonoInternacional('+57 300 1234567', 'CO'), startsWith('+57 300'));
    expect(separarTelefono('+52 993 123 4567')?.iso, 'MX');
    expect(ladaDe('CO'), '57');
    expect(bandera('MX'), '🇲🇽');
  });

  test('folio, coordenadas', () {
    expect(folioNuevo(7, 'Tecolutilla'), '007-TECO');
    expect(folioParaZona('012-TECO', 'Comalcalco'), '012-COMA');
    expect(coordenadas('https://www.google.com/maps/@18.25,-93.21,17z'), (lat: 18.25, lng: -93.21));
    expect(coordenadas('hola'), isNull);
  });

  test('cada servicio pide lo suyo', () {
    expect(revisarOrden(base('falla'), ahora, cat), isNull);
    final nuevo = base('instalacion');
    expect(revisarOrden(nuevo, ahora, cat), FalloNuevaOrden.plan);
    nuevo.plan = cat.modems[1];
    expect(revisarOrden(nuevo, ahora, cat), isNull, reason: 'el comisionista es opcional');
    nuevo.comisionistaId = 'c1';
    expect(revisarOrden(nuevo, ahora, cat), FalloNuevaOrden.comision);
    nuevo.comisionId = cat.comisionSugerida('c1', nuevo.plan);
    expect(nuevo.comisionId, 'nuevo-dp', reason: 'la del plan Doble Play se elige sola');
    expect(revisarOrden(nuevo, ahora, cat), isNull);

    final baja = base('baja');
    expect(revisarOrden(baja, ahora, cat), FalloNuevaOrden.motivoBaja);
    baja.motivoOtro = true;
    expect(revisarOrden(baja, ahora, cat), FalloNuevaOrden.motivoOtro);
    baja.motivoTexto = 'se muda';
    expect(revisarOrden(baja, ahora, cat), FalloNuevaOrden.modem);

    final temporal = base('temporal');
    expect(revisarOrden(temporal, ahora, cat), FalloNuevaOrden.recogeModem);
    temporal.recogeModem = false;
    expect(revisarOrden(temporal, ahora, cat), FalloNuevaOrden.fechaRegreso);
    temporal.fechaRegreso = '2026-10-01';
    expect(revisarOrden(temporal, ahora, cat), FalloNuevaOrden.fechaRegresoPasada);

    expect(revisarOrden(base('tvdp'), ahora, cat), FalloNuevaOrden.modem);
    expect(revisarOrden(base('falla')..telefono = '123', ahora, cat), FalloNuevaOrden.telefono);
    expect(revisarOrden(base('falla', dia: DateTime(2026, 11, 1)), ahora, cat), FalloNuevaOrden.diaPasado);
  });

  test('servicio nuevo y cancelación definitiva guardan lo mismo que la web; sin técnico', () {
    final nuevo = base('instalacion')
      ..plan = cat.modems[1]
      ..tvPagadas = 2
      ..comisionistaId = 'c1'
      ..comisionId = 'nuevo-dp';
    final d = datosOrdenNueva(nuevo, cat, folio: '001-TECO', userId: 'a1', nombre: 'reinier', ahora: ahora);
    expect(d['status'], 'pendiente');
    expect(d['assignedTechId'], '');
    expect(d['commission'], true);
    expect(d['referrerName'], 'Pedro');
    expect(d['commissionAmount'], 150);
    expect(d['plan'], 'doble_play');
    expect(d['planCatId'], 'dp');
    expect(d['tvPaidQty'], 2);
    expect(d['serviceName'], 'Nuevo Servicio');

    final baja = base('baja')
      ..motivoId = 'falta'
      ..modemBaja = cat.modems[0];
    final b = datosOrdenNueva(baja, cat, folio: '002-TECO', userId: 'a1', nombre: 'reinier', ahora: ahora);
    expect(b['bajaReason'], 'Falta de pago');
    expect(b['bajaEquipment'], 'internet');
    expect(b['modemStatus'], 'pendiente');
    expect(b['commission'], false);
    expect(b['plan'], '');
  });

  test('editar no toca el técnico y respeta el día que no se cambió', () {
    final o = Orden('x', {
      'status': 'en_proceso',
      'acceptedBy': 'u7',
      'serviceType': 'falla',
      'folio': '010-TECO',
      'zoneId': 'Tecolutilla',
      'workDate': '2026-10-30',
      'clientPhone': '+52 993 123 4567',
    });
    final d = DatosOrden.de(o)..zonaId = 'Comalcalco';
    expect(d.pais, 'MX');
    expect(revisarOrden(d..cliente = 'Ana', ahora, cat, antes: o), isNull);
    final c = datosOrdenEditada(o, d, cat, nombreZona: 'Comalcalco', userId: 'a1', nombre: 'reinier');
    expect(c.containsKey('status'), isFalse);
    expect(c.containsKey('assignedTechId'), isFalse);
    expect(c.containsKey('workDate'), isFalse);
    expect(c['clientPhone'], '+52 993 123 4567');
    expect(c['folio'], '010-COMA');
  });

  group('con base simulada', () {
    late FakeFirebaseFirestore db;
    late ServicioOrdenes servicio;
    setUp(() async {
      db = FakeFirebaseFirestore();
      servicio = ServicioOrdenes(db: db);
      await db.collection('zones').doc('Tecolutilla').set({'name': 'Tecolutilla'});
      for (final e in cat.servicios.entries) {
        await db.collection('services').doc(e.key).set(e.value);
      }
      await db.collection('assetCategories').doc('inter').set({'name': 'Módem Internet'});
      await db.collection('counters').doc('tickets').set({'value': 41});
    });

    test('crear: folio con el contador, sin técnico, y la temporal en Cancelados › Temporales', () async {
      final d = base('temporal', dia: DateTime.now())
        ..telefono = '9931234567'
        ..recogeModem = true;
      final c = await servicio.catalogosOrden();
      d.modemTemporal = c.modems.single;
      final creada = await servicio.crear(d, admin);
      expect(creada, (id: '042-TECO', folio: '042-TECO'));
      final o = (await db.collection('tickets').doc('042-TECO').get()).data()!;
      expect(o['status'], 'pendiente');
      expect(o['assignedTechId'], '');
      expect(o['clientPhone'], '+52 993 123 4567');
      expect((o['tempCancel'] as Map)['pickupModem'], true);
      final tc = (await db.collection('tempCancels').doc('tk_042-TECO').get()).data()!;
      expect(tc['status'], 'activo');
      expect(tc['modemName'], 'Módem Internet');
      expect(tc['createdByName'], 'reinier');
    });

    test('eliminar: a la Papelera, y su temporal se anula', () async {
      await db.collection('tickets').doc('042-TECO').set({
        'folio': '042-TECO',
        'clientName': 'Ana',
        'tempCancel': {'reason': ''},
      });
      await db.collection('tempCancels').doc('tk_042-TECO').set({'status': 'activo', 'voided': false});
      final o = Orden('042-TECO', (await db.collection('tickets').doc('042-TECO').get()).data()!);
      await servicio.eliminar(o, admin);
      expect((await db.collection('tickets').doc('042-TECO').get()).exists, isFalse);
      expect((await db.collection('trash').get()).docs.single.data()['label'], '042-TECO · Ana');
      expect((await db.collection('tempCancels').doc('tk_042-TECO').get()).data()!['voided'], true);
    });
  });

  test('la papelera usa el id si no hay folio ni cliente', () {
    expect(datosPapelera(Orden('abc', const {}), 'a1', 'reinier')['label'], 'abc');
    expect(datosPapelera(Orden('abc', const {}), 'a1', 'reinier')['deletedAt'], isA<FieldValue>());
  });
}
