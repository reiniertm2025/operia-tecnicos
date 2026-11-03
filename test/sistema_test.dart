import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/menu.dart';
import 'package:operia_tecnicos/logica/sistema.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';

void main() {
  test('cada opción de Sistema abre su lista, y todas las listas tienen opción', () {
    final abiertas = [for (final o in OpcionMenu.values) ?catalogoDe(o)];
    expect(abiertas.toSet(), Catalogo.values.toSet());
    expect(coleccionDe(Catalogo.zonas), 'localityZones');
    expect(coleccionDe(Catalogo.insumos), 'assets');
  });

  test('orden como sortList de la web; activos con categoría e insumos sin ella', () {
    final l = ordenarCatalogo(Catalogo.servicios, const [
      (id: 'b', datos: {'name': 'B'}),
      (id: 'a', datos: {'name': 'A', 'order': 2}),
      (id: 'c', datos: {'name': 'C', 'order': 1}),
    ]);
    expect(l.map((r) => r.id), ['c', 'a', 'b']);
    const modem = (id: 'm', datos: <String, dynamic>{'name': 'Módem', 'categoryId': 'dp'});
    const cable = (id: 'f', datos: <String, dynamic>{'name': 'Fibra'});
    expect((entraEn(Catalogo.activos, modem), entraEn(Catalogo.insumos, modem)), (true, false));
    expect((entraEn(Catalogo.activos, cable), entraEn(Catalogo.insumos, cable)), (false, true));
  });

  test('servicio: lee una colección de Sistema una vez', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('roles').doc('admin').set({'name': 'Administrador', 'permission': 'admin'});
    await db.collection('roles').doc('_seed').set({});
    final s = ServicioOrdenes(db: db);
    expect((await s.registros('roles')).map((r) => r.id), ['admin']);
    await db.collection('roles').doc('tec').set({'name': 'Técnico'});
    expect((await s.registros('roles')).length, 1, reason: 'guardada mientras la app está abierta');
    expect((await s.registros('roles', recargar: true)).length, 2);
  });
}
