import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/fechas.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';

void main() {
  // miércoles 12 de noviembre de 2026, a media tarde
  final ahora = DateTime(2026, 11, 12, 16, 30);

  test('botones rápidos como la web (la semana empieza en lunes)', () {
    expect(rangoRapido(RangoRapido.hoy, ahora), (desde: DateTime(2026, 11, 12), hasta: DateTime(2026, 11, 12)));
    expect(rangoRapido(RangoRapido.semana, ahora), (desde: DateTime(2026, 11, 9), hasta: DateTime(2026, 11, 15)));
    expect(rangoRapido(RangoRapido.mes, ahora), (desde: DateTime(2026, 11, 1), hasta: DateTime(2026, 11, 30)));
    expect(rangoRapido(RangoRapido.mesAnterior, ahora), (desde: DateTime(2026, 10, 1), hasta: DateTime(2026, 10, 31)));
    expect(rangoRapido(RangoRapido.mesAnterior, DateTime(2026, 1, 5)), (
      desde: DateTime(2025, 12, 1),
      hasta: DateTime(2025, 12, 31),
    ));
  });

  test('se reconoce el botón rápido de un rango; uno elegido a mano no tiene botón', () {
    expect(rapidoDe(rangoRapido(RangoRapido.mes, ahora), ahora), RangoRapido.mes);
    expect(rapidoDe((desde: DateTime(2026, 11, 3), hasta: DateTime(2026, 11, 5)), ahora), isNull);
    expect(rapidoDe(null, ahora), isNull);
  });

  test('el historial trae solo las órdenes creadas en el rango (el último día completo)', () async {
    final db = FakeFirebaseFirestore();
    Future<void> orden(String id, DateTime creada) => db.collection('tickets').doc(id).set({
      'assignedTechId': 'u1',
      'status': 'completada',
      'createdAt': Timestamp.fromDate(creada),
    });
    await orden('antes', DateTime(2026, 11, 2, 23, 59));
    await orden('primero', DateTime(2026, 11, 3, 0, 0));
    await orden('ultimo', DateTime(2026, 11, 5, 23, 30));
    await orden('despues', DateTime(2026, 11, 6, 0, 0));
    final p = await ServicioOrdenes(db: db).historial(
      const Tecnico(userId: 'u1', nombre: 'Portela'),
      rango: (desde: DateTime(2026, 11, 3), hasta: DateTime(2026, 11, 5)),
    );
    expect(p.ordenes.map((o) => o.id), ['ultimo', 'primero']);
  });
}
