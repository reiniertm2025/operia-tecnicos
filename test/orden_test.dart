import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/orden.dart';

void main() {
  test('el estado se entiende igual que en la web', () {
    expect(normalizarEstado({'status': 'en_proceso'}), 'en_proceso');
    expect(normalizarEstado({'status': 'En Proceso'}), 'en_proceso');
    expect(normalizarEstado({'estado': 'Atención'}), 'atencion');
    expect(normalizarEstado({'status': 'asignada'}), 'en_proceso');
    expect(normalizarEstado({}), 'pendiente');
    expect(normalizarEstado({'status': 'en_proceso', 'cancelled': true}), 'cancelada');
  });

  test('el folio se muestra como en la web', () {
    expect(folioVisible('AB12'), '012-AB');
    expect(folioVisible('raro-1'), 'raro-1');
    expect(folioVisible(null), '');
  });

  test('día de servicio: workDate, o el día en que se registró', () {
    expect(Orden('a', {'workDate': '2026-11-05'}).dia, '2026-11-05');
    expect(Orden('a', {'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1, 18))}).dia, '2026-11-01');
    expect(Orden('a', {}).dia, '');
  });

  test('ubicación desde latitude/longitude o desde el texto de coordenadas', () {
    expect(Orden('a', {'latitude': 19.4, 'longitude': -99.1}).ubicacion, (lat: 19.4, lng: -99.1));
    expect(Orden('a', {'coordinates': '19.5, -99.2'}).ubicacion, (lat: 19.5, lng: -99.2));
    expect(Orden('a', {'address': 'Centro'}).ubicacion, isNull);
  });

  test('las órdenes se separan en atrasadas, hoy y próximos días', () {
    final g = OrdenesDelTecnico([
      Orden('ayer', {'workDate': '2026-11-01', 'status': 'pendiente'}),
      Orden('hoy-pend', {'workDate': '2026-11-02', 'status': 'pendiente', 'scheduledTime': '09:00'}),
      Orden('hoy-proc', {'workDate': '2026-11-02', 'status': 'en_proceso', 'scheduledTime': '12:00'}),
      Orden('manana', {'workDate': '2026-11-03', 'status': 'en_proceso'}),
      Orden('hecha', {'workDate': '2026-11-02', 'status': 'completada'}),
      Orden('cancelada', {'workDate': '2026-11-02', 'status': 'pendiente', 'cancelled': true}),
    ], '2026-11-02');
    expect(g.atrasadas.map((o) => o.id), ['ayer']);
    expect(g.deHoy.map((o) => o.id), ['hoy-proc', 'hoy-pend']);
    expect(g.proximas.map((o) => o.id), ['manana']);
  });

  test('el buscador encuentra por folio, cliente, teléfono, dirección y localidad', () {
    final o = Orden('x', {
      'folio': 232,
      'clientName': 'José Pérez',
      'clientPhone': '993 123 4567',
      'address': 'Calle Reforma 10',
      'serviceName': 'Falla / Reparación',
    });
    bool busca(String q) => coincideBusqueda(o, q, zona: 'Tecolutilla');
    expect(busca(''), isTrue);
    expect(busca('jose'), isTrue, reason: 'sin acentos ni mayúsculas');
    expect(busca('perez reforma'), isTrue, reason: 'varias palabras');
    expect(busca('9931234'), isTrue, reason: 'teléfono sin espacios');
    expect(busca('232'), isTrue);
    expect(busca('tecolu'), isTrue);
    expect(busca('maria'), isFalse);
    expect(busca('perez centro'), isFalse);
  });

  test('las localidades se ordenan como en la web: por order y luego la más vieja', () {
    final zonas = [
      {'name': 'Chichicapa', 'order': 2},
      {'name': 'Sin orden vieja', 'createdAt': Timestamp.fromMillisecondsSinceEpoch(1)},
      {'name': 'Tecolutilla', 'order': 0},
      {'name': 'Comalcalco', 'order': '1'},
      {'name': 'Sin orden nueva', 'createdAt': Timestamp.fromMillisecondsSinceEpoch(5)},
    ]..sort(compararOrdenWeb);
    expect(zonas.map((z) => z['name']), ['Tecolutilla', 'Comalcalco', 'Chichicapa', 'Sin orden vieja', 'Sin orden nueva']);
  });
}
