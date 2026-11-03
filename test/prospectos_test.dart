import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/nueva_orden.dart';
import 'package:torrexi_tecnicos/logica/prospectos.dart';
import 'package:torrexi_tecnicos/servicios/ordenes.dart';
import 'package:torrexi_tecnicos/servicios/sesion.dart';

void main() {
  setUpAll(FakeFirebaseFirestore.new);

  test('luz como dueLight de la web: hoy o pasado roja, mañana amarilla, asignado sin luz', () {
    const hoy = '2026-11-02';
    expect(luzProspecto(const Prospecto('a', {'installDate': '2026-11-01'}), hoy), LuzProspecto.hoy);
    expect(luzProspecto(const Prospecto('b', {'installDate': '2026-11-02'}), hoy), LuzProspecto.hoy);
    expect(luzProspecto(const Prospecto('c', {'installDate': '2026-11-03'}), hoy), LuzProspecto.manana);
    expect(luzProspecto(const Prospecto('d', {'installDate': '2026-11-09'}), hoy), LuzProspecto.ninguna);
    expect(
      luzProspecto(const Prospecto('e', {'installDate': '2026-11-01', 'status': 'asignado'}), hoy),
      LuzProspecto.ninguna,
    );
    final l = ordenarProspectos(const [
      Prospecto('x', {}),
      Prospecto('y', {'installDate': '2026-11-05'}),
      Prospecto('z', {'installDate': '2026-11-03'}),
    ]);
    expect(l.map((p) => p.id), ['z', 'y', 'x']);
  });

  test('revisar y guardar como la web: teléfono internacional, coordenadas y sin fecha pasada', () {
    final d = DatosProspecto()
      ..nombre = ' Ana '
      ..telefono = '9931234567'
      ..coordenadas = '18.25, -93.21'
      ..dia = '2026-11-01';
    expect(revisarProspecto(d, '2026-11-02'), FalloProspecto.diaPasado);
    d.dia = '2026-11-05';
    expect(revisarProspecto(d, '2026-11-02'), isNull);
    expect(revisarProspecto(DatosProspecto()..telefono = '12', '2026-11-02'), FalloProspecto.telefono);
    final g = datosProspecto(d, userId: 'u1', nombre: 'Ana');
    expect(
      (g['name'], g['phone'], g['latitude'], g['status'], g['photoCount']),
      ('Ana', '+52 993 123 4567', 18.25, 'pendiente', 0),
    );
    // al editar no cambia el estado ni quién lo creó
    final antes = Prospecto('p', {'status': 'pendiente', 'photoCount': 3});
    final e = datosProspecto(d..foto = 'data:image/jpeg;base64,AA==', antes: antes, userId: 'u1', nombre: 'Ana');
    expect(e.containsKey('status'), isFalse);
    expect(e['photoCount'], 3, reason: 'las fotos extra de la web se conservan');
  });

  test('crear orden: primer servicio nuevo, comisionista y el comentario en la descripción', () {
    final cat = CatalogosOrden(
      servicios: {
        'falla': {'name': 'Falla', 'order': 0},
        'nuevo': {'name': 'Nuevo Servicio', 'commission': true, 'order': 1},
      },
      comisionistas: const [Comisionista('c1', 'Pedro', [], [])],
    );
    final p = Prospecto('p', {
      'name': 'Ana',
      'phone': '+52 993 123 4567',
      'zoneId': 'Tecolutilla',
      'prospectorId': 'c1',
      'comment': 'Quiere 50 megas',
    });
    final d = ordenDeProspecto(p, cat, (x) => 'Prospecto: $x');
    expect(
      (d.cliente, d.telefono, d.pais, d.zonaId, d.servicioId, d.comisionistaId, d.descripcion),
      ('Ana', '993 123 4567', 'MX', 'Tecolutilla', 'nuevo', 'c1', 'Prospecto: Quiere 50 megas'),
    );
  });

  test('servicio: el técnico ve los de sus localidades y los sin localidad; guardar y asignar', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('prospects').doc('a').set({'name': 'A', 'zoneId': 'Tecolutilla'});
    await db.collection('prospects').doc('b').set({'name': 'B', 'zoneId': 'Otra'});
    await db.collection('prospects').doc('c').set({'name': 'C'});
    final s = ServicioOrdenes(db: db);
    const tecnico = Tecnico(userId: 'u1', nombre: 'Ana', zonas: ['Tecolutilla']);
    final lista = await s.prospectos(tecnico).first;
    expect(lista.map((p) => p.id).toSet(), {'a', 'c'});
    await s.guardarProspecto(DatosProspecto()..nombre = 'Nuevo', tecnico);
    expect(
      (await db.collection('prospects').where('name', isEqualTo: 'Nuevo').get()).docs.single.data()['status'],
      'pendiente',
    );
    await s.asignarProspecto(lista.firstWhere((p) => p.id == 'a'), (id: '050-TECO 1', folio: '050-TECO'), tecnico);
    final a = (await db.collection('prospects').doc('a').get()).data()!;
    expect((a['status'], a['ticketId'], a['ticketFolio']), ('asignado', '050-TECO 1', '050-TECO'));
  });
}
