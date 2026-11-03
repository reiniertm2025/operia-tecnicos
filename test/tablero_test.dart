import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/orden.dart';
import 'package:operia_tecnicos/logica/tablero.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';

void main() {
  const tecnico = Tecnico(userId: 'u1', nombre: 'Portela', zonas: ['Comalcalco', 'Chichicapa']);
  const admin = Tecnico(userId: 'a1', nombre: 'reinier', esAdmin: true);
  final hoy = Timestamp.fromDate(DateTime(2026, 11, 2, 10));

  final abiertas = [
    Orden('libre-mia', {'status': 'pendiente', 'zoneId': 'Comalcalco', 'assignedTechId': ''}),
    Orden('libre-otra-zona', {'status': 'pendiente', 'zoneId': 'Tecolutilla', 'assignedTechId': ''}),
    Orden('de-otro', {'status': 'en_proceso', 'zoneId': 'Comalcalco', 'assignedTechId': 'u2'}),
    Orden('mia', {'status': 'en_proceso', 'zoneId': 'Tecolutilla', 'assignedTechId': 'u1'}),
    Orden('proceso-sin-tecnico', {'status': 'en_proceso', 'zoneId': 'Chichicapa', 'assignedTechId': ''}),
    Orden('cancelada', {'status': 'pendiente', 'zoneId': 'Comalcalco', 'cancelled': true}),
  ];
  final culminadas = [
    Orden('hecha-mia', {'status': 'completada', 'zoneId': 'Comalcalco', 'assignedTechId': 'u1', 'completedAt': hoy}),
    Orden('hecha-otro', {'status': 'completada', 'zoneId': 'Comalcalco', 'assignedTechId': 'u2', 'completedAt': hoy}),
  ];

  List<String> ids(List<Orden> l) => l.map((o) => o.id).toList();

  test('el técnico ve las suyas y las libres de sus localidades, nunca las de otro', () {
    final t = Tablero(quien: tecnico, abiertas: abiertas, culminadasHoy: culminadas);
    expect(ids(t.pendientes), ['libre-mia']);
    expect(ids(t.enProceso), ['mia', 'proceso-sin-tecnico']);
    expect(ids(t.culminadas), ['hecha-mia']);
  });

  test('el administrador ve todo menos las canceladas', () {
    final t = Tablero(quien: admin, abiertas: abiertas, culminadasHoy: culminadas);
    expect(ids(t.pendientes), ['libre-mia', 'libre-otra-zona']);
    expect(ids(t.enProceso), ['de-otro', 'mia', 'proceso-sin-tecnico']);
    expect(ids(t.culminadas), ['hecha-mia', 'hecha-otro']);
  });

  test('el filtro de localidad deja solo las de esa localidad', () {
    final t = Tablero(quien: admin, abiertas: abiertas, culminadasHoy: culminadas, zona: 'Tecolutilla');
    expect(ids(t.pendientes), ['libre-otra-zona']);
    expect(ids(t.enProceso), ['mia']);
    expect(t.culminadas, isEmpty);
  });

  test('al juntar consultas, una orden repetida sale una sola vez (con sus datos más nuevos)', () {
    final juntas = unirSinRepetir([
      [
        Orden('a', {'status': 'pendiente'}),
      ],
      [
        Orden('a', {'status': 'en_proceso'}),
        Orden('b', {}),
      ],
    ]);
    expect(ids(juntas), ['a', 'b']);
    expect(juntas.first.estado, 'en_proceso');
  });
}
