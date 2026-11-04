import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/acciones.dart';
import 'package:torrexi_tecnicos/logica/orden.dart';
import 'package:torrexi_tecnicos/servicios/sesion.dart';

void main() {
  const hoy = '2026-11-02';

  test('al tomarla queda en proceso a su nombre, como cuando la oficina la asigna', () {
    final d = datosAlTomar(Orden('a', {'status': 'pendiente', 'workDate': hoy}), 'u1', 'Juan', hoy);
    expect(d['assignedTechId'], 'u1');
    expect(d['assignedTechName'], 'Juan');
    expect(d['assignedById'], 'u1');
    expect(d['status'], 'en_proceso');
    expect(d['startedAt'], isA<FieldValue>());
    expect(d['lastChangedByName'], 'Juan');
    expect(d.containsKey('estado'), isFalse);
  });

  test('si la orden es para otro día, al tomarla todavía no cuenta como iniciada', () {
    final d = datosAlTomar(
      Orden('a', {'status': 'pendiente', 'workDate': '2026-11-05', 'estado': 'pendiente'}),
      'u1',
      'Juan',
      hoy,
    );
    expect(d.containsKey('startedAt'), isFalse);
    expect(d['estado'], 'en_proceso');
  });

  test('al terminar sin cobro queda completada y se limpia el cobro que hubiera, como en la web', () {
    final o = Orden('a', {
      'status': 'en_proceso',
      'serviceName': 'Reparación de falla',
      'paymentMethod': 'efectivo',
      'startedAt': 1,
    });
    final d = datosAlTerminar(o, 'u1', 'Juan');
    expect(d['status'], 'completada');
    expect(d['completedAt'], isA<FieldValue>());
    expect(d['paymentMethod'], isNull);
    expect(d['chargeItems'], isEmpty);
    expect(d.containsKey('startedAt'), isFalse);
  });

  test('las bajas y reparaciones son sin cobro', () {
    expect(Orden('a', {'serviceName': 'Baja de servicio'}).sinCobro, isTrue);
    expect(Orden('a', {'serviceName': 'Cancelación definitiva'}).sinCobro, isTrue);
    expect(Orden('a', {'serviceType': 'falla'}).sinCobro, isTrue);
    expect(
      Orden('a', {
        'serviceName': 'Instalación',
        'bajaEquipment': {'modem': true},
      }).sinCobro,
      isTrue,
    );
    expect(Orden('a', {'serviceName': 'Nuevo Servicio'}).sinCobro, isFalse);
  });

  test('quién tiene la orden, en cualquiera de los campos de técnico de la web', () {
    expect(Orden('a', {'assignedTechId': ''}).tieneTecnico, isFalse);
    expect(Orden('a', {'acceptedBy': 'u2'}).tieneTecnico, isTrue);
    expect(Orden('a', {'acceptedBy': 'u2'}).esDe('u2'), isTrue);
    expect(Orden('a', {'assignedTechId': 'u2'}).esDe('u1'), isFalse);
  });

  test('localidades del técnico: zoneIds, o zoneId en fichas viejas', () {
    expect(
      zonasDeUsuario({
        'zoneIds': ['z1', '', 'z2'],
      }),
      ['z1', 'z2'],
    );
    expect(zonasDeUsuario({'zoneIds': [], 'zoneId': 'z3'}), ['z3']);
    expect(zonasDeUsuario({}), isEmpty);
  });

  test('el administrador regresa la orden a pendiente o en proceso como el botón de estado de la web', () {
    final o = Orden('a', {
      'status': 'completada',
      'estado': 'completada',
      'assignedTechId': 'u2',
      'assignedTechName': 'Ana',
      'startedAt': 1,
      'completedAt': 2,
    });
    final p = datosCambioEstado(o, 'pendiente', 'adm', 'Jefe');
    expect(p['status'], 'pendiente');
    expect(p['estado'], 'pendiente');
    expect(p['completedAt'], isNull);
    expect(p.containsKey('completedAt'), isTrue);
    expect(p['assignedTechId'], '');
    expect(p['assignedTechName'], '');
    expect(p['startedAt'], isNull);
    expect(p.containsKey('startedAt'), isTrue);
    expect(p['lastChangedById'], 'adm');

    final e = datosCambioEstado(o, 'en_proceso', 'adm', 'Jefe');
    expect(e['status'], 'en_proceso');
    expect(e.containsKey('assignedTechId'), isFalse);
    expect(e.containsKey('startedAt'), isFalse, reason: 'ya tenía hora de inicio');
    final sinInicio = datosCambioEstado(Orden('b', {'status': 'pendiente'}), 'en_proceso', 'adm', 'Jefe');
    expect(sinInicio['startedAt'], isA<FieldValue>());
    expect(sinInicio.containsKey('estado'), isFalse);
  });
}
