import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/cobro.dart';
import 'package:operia_tecnicos/logica/orden.dart';

/// Catálogo con la forma del real (serviceCharges y services de la base, 2026-11-02).
final cat = Catalogos(
  cobros: [
    {'id': 'Cobro - Plan 300', 'serviceName': 'Plan 300', 'amount': '300', 'order': '3'},
    {'id': 'Cobro - Plan 220', 'serviceName': 'Plan 220', 'amount': '220', 'order': '1'},
    {'id': 'Cobro - Cambio de Domicilio', 'serviceName': 'Cambio de Domicilio', 'amount': '180', 'order': '14'},
    {'id': 'Cobro - TV Adicional', 'serviceName': 'TV Adicional', 'amount': '120', 'order': '15'},
    {'id': 'Cobro - Reconexión', 'serviceName': 'Reconexión', 'amount': null, 'order': '16'},
    {'id': 'Cobro - Otros', 'serviceName': 'Otros', 'amount': null, 'order': '17'},
  ],
  servicios: {
    'instalacion': {'name': 'Nuevo Servicio', 'billable': true, 'commission': true},
    'desactivacion': {'name': 'Cambio de Domicilio', 'billable': true, 'commission': false},
    'falla': {'name': 'Falla / Reparación', 'billable': false, 'commission': false},
    'Cambios de Plan': {'name': 'Cambios de Plan', 'billable': false, 'commission': false},
  },
);

void main() {
  final nuevo = Orden('n', {
    'status': 'en_proceso',
    'serviceType': 'instalacion',
    'serviceName': 'Nuevo Servicio',
    'startedAt': 1,
  });
  final domicilio = Orden('d', {
    'status': 'en_proceso',
    'serviceType': 'desactivacion',
    'serviceName': 'Cambio de Domicilio',
    'startedAt': 1,
  });

  test('qué órdenes llevan cobro, como needsPayment de la web', () {
    expect(esServicioNuevo(nuevo, cat), isTrue);
    expect(llevaCobro(nuevo, cat), isTrue);
    expect(llevaCobro(domicilio, cat), isTrue);
    expect(llevaCobro(Orden('f', {'serviceType': 'falla', 'serviceName': 'Falla / Reparación'}), cat), isFalse);
    expect(completaSinCobro(Orden('p', {'serviceType': 'Cambios de Plan', 'serviceName': 'Cambios de Plan'}), cat), isTrue);
    // esperando autorización de la oficina: nunca se completa sola
    expect(completaSinCobro(Orden('f', {'serviceType': 'falla', 'payAuthStatus': 'solicitada'}), cat), isFalse);
  });

  test('servicio nuevo: solo planes, ordenados; las TV adicionales pagadas ya van marcadas', () {
    final filas = conceptosPara(Orden('n', {...nuevo.datos, 'tvPaidQty': 2}), cat);
    expect(filas.map((f) => f.nombre), ['Plan 220', 'Plan 300', 'TV Adicional × 2']);
    expect(filas.last.importe, 240);
    expect(filas.last.marcado, isTrue);
    expect(filas.last.cantidad, 2);
  });

  test('otros servicios: sin planes; «Otros» y «Reconexión» piden importe y comentario', () {
    final filas = conceptosPara(domicilio, cat);
    expect(filas.map((f) => f.nombre), ['Cambio de Domicilio', 'TV Adicional', 'Reconexión', 'Otros']);
    expect(filas.first.editable, isFalse);
    expect(filas[2].editable && filas[2].pideNota, isTrue);
    expect(filas[3].importe, isNull);
  });

  test('un cobro guardado antes vuelve a salir marcado con su importe', () {
    final filas = conceptosPara(
      Orden('d', {
        ...domicilio.datos,
        'chargeItems': [
          {'chargeId': 'Cobro - Otros', 'name': 'Otros', 'amount': 50, 'comment': 'cable extra'},
        ],
      }),
      cat,
    );
    final otros = filas.firstWhere((f) => f.nombre == 'Otros');
    expect(otros.marcado, isTrue);
    expect(otros.importe, 50);
    expect(otros.nota, 'cable extra');
  });

  test('revisión del paso 1: importe y comentario obligatorios en «Otros»', () {
    final filas = conceptosPara(domicilio, cat);
    final otros = filas.firstWhere((f) => f.nombre == 'Otros')..marcado = true;
    expect(revisarConceptos(filas)?.$1, FalloConcepto.importe);
    otros.importe = 80;
    expect(revisarConceptos(filas)?.$1, FalloConcepto.nota);
    otros.nota = 'material';
    expect(revisarConceptos(filas), isNull);
  });

  test('efectivo: guarda los conceptos y la orden queda completada', () {
    final filas = conceptosPara(domicilio, cat)..first.marcado = true;
    expect(totalConceptos(filas), 180);
    final d = datosCobro(domicilio, filas, FormaPago.efectivo, 'u1', 'Juan');
    expect(d['chargeItems'], [
      {'chargeId': 'Cobro - Cambio de Domicilio', 'name': 'Cambio de Domicilio', 'amount': 180.0},
    ]);
    expect(d['chargeAmount'], 180);
    expect(d['chargeName'], 'Cambio de Domicilio');
    expect(d['billable'], isTrue);
    expect(d['paymentMethod'], 'efectivo');
    expect(d['status'], 'completada');
    expect(d['completedAt'], isA<FieldValue>());
    expect(d.containsKey('payAuthStatus'), isFalse);
  });

  test('pendiente de pago y sin costo: piden autorización y siguen en proceso', () {
    final filas = conceptosPara(domicilio, cat)..first.marcado = true;
    for (final (forma, valor) in [(FormaPago.pendiente, 'pendiente'), (FormaPago.sinCosto, 'sin_costo')]) {
      final d = datosCobro(domicilio, filas, forma, 'u1', 'Juan');
      expect(d['paymentMethod'], valor);
      expect(d['payAuthStatus'], 'solicitada');
      expect(d['payAuthMethod'], valor);
      expect(d['payAuthRequestedByName'], 'Juan');
      expect(d.containsKey('status'), isFalse);
      expect(d.containsKey('completedAt'), isFalse);
    }
  });

  test('transferencia: guarda los conceptos y deja el aviso; la oficina sube el comprobante', () {
    final filas = conceptosPara(domicilio, cat)..first.marcado = true;
    final d = datosCobro(domicilio, filas, FormaPago.transferencia, 'u1', 'Juan');
    expect(d['chargeAmount'], 180);
    expect(d['techPayMethod'], 'transferencia');
    expect(d['techDoneById'], 'u1');
    expect(d.containsKey('paymentMethod'), isFalse);
    expect(d.containsKey('status'), isFalse);
  });

  test('sin conceptos marcados y sin ser servicio nuevo: se completa sin cobro', () {
    final filas = conceptosPara(domicilio, cat);
    expect(pideFormaPago(domicilio, cat, filas), isFalse);
    expect(pideFormaPago(nuevo, cat, conceptosPara(nuevo, cat)), isTrue);
    final d = datosCobro(domicilio, filas, null, 'u1', 'Juan');
    expect(d['chargeItems'], isEmpty);
    expect(d['chargeAmount'], isNull);
    expect(d['billable'], isFalse);
    expect(d['status'], 'completada');
  });
}
