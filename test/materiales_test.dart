import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/materiales.dart';
import 'package:operia_tecnicos/logica/orden.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';

const categorias = {'dp': 'Modem Doble Play', 'int': 'Modem Internet'};
final cat = CatalogoMateriales(
  activos: [
    activoDe('m1', {'name': 'Huawei', 'model': 'HG8245', 'categoryId': 'dp', 'price': 900}, categorias),
    activoDe('m2', {'name': 'ZTE', 'categoryId': 'int', 'price': 700}, categorias),
    activoDe('fibra', {'name': 'Fibra drop', 'unit': 'M', 'price': '2.5'}, categorias),
    activoDe('conector', {'name': 'Conector', 'price': 10}, categorias),
  ],
  categorias: categorias,
  insumosPorZona: const {
    'Comalcalco': {'fibra': 250},
  },
);
const nuevo = {
  'name': 'Nuevo Servicio',
  'commission': true,
  'materialsOn': true,
  'materials': [
    {'assetId': 'fibra', 'qty': 150},
    {'assetId': 'conector', 'qty': 2},
    {'assetId': 'm1', 'qty': 1},
  ],
  'aftOff': ['m2'],
};

void main() {
  test('qué servicios piden materiales (svcHasMat), y nunca una cancelación definitiva', () {
    expect(servicioLlevaMateriales(nuevo), isTrue);
    expect(servicioLlevaMateriales({'materialsOn': false, 'materials': nuevo['materials']}), isFalse);
    expect(servicioLlevaMateriales({'name': 'Falla'}), isFalse);
    expect(pideMateriales(Orden('a', const {'serviceType': 'n'}), nuevo), isTrue);
    expect(pideMateriales(Orden('b', const {'bajaEquipment': 'internet'}), nuevo), isFalse);
  });

  test('activos: el módem por su categoría, nombre con modelo y unidad', () {
    expect(cat.activo('m1')!.esModem, isTrue);
    expect(cat.activo('m1')!.nombre, 'Huawei · HG8245');
    expect(cat.activo('fibra')!.esModem, isFalse);
    expect(cat.insumos.map((a) => a.id), ['conector', 'fibra']);
    expect(cat.activo('fibra')!.unidad, 'm');
    // pestañas de módem: el servicio quitó el m2 con aftOff, así que Internet no sale
    expect(cat.modemsPara(nuevo).map((m) => (m.nombre, m.activos.map((a) => a.id).join(','))), [
      ('Modem Doble Play', 'm1'),
    ]);
  });

  test('insumos del servicio con la cantidad de la localidad; lo guardado manda', () {
    final teco = Orden('a', const {'zoneId': 'Tecolutilla'});
    expect(insumosDeLaOrden(teco, nuevo, cat), [(assetId: 'fibra', qty: 150.0), (assetId: 'conector', qty: 2.0)]);
    final coma = Orden('b', const {'zoneId': 'Comalcalco'});
    expect(insumosDeLaOrden(coma, nuevo, cat).first, (assetId: 'fibra', qty: 250.0));
    final usada = Orden('c', const {
      'materialsUsed': [
        {'assetId': 'conector', 'qty': 5},
      ],
    });
    expect(insumosDeLaOrden(usada, nuevo, cat), [(assetId: 'conector', qty: 5.0)]);
    expect(insumosMarcados(teco, nuevo), isTrue, reason: 'servicio nuevo');
    expect(insumosMarcados(teco, {'name': 'Falla / Reparación'}), isFalse);
    expect(insumosMarcados(teco, {'name': 'Cambio de domicilio'}), isTrue);
  });

  test('lo que se guarda, igual que la web, y el gasto', () {
    expect(datosMateriales(userId: 'u1', nombre: 'Ana'), {'completedByTechId': 'u1', 'completedByTechName': 'Ana'});
    final d = datosMateriales(
      userId: 'u1',
      nombre: 'Ana',
      modemId: 'm1',
      insumos: const [(assetId: 'fibra', qty: 100), (assetId: 'conector', qty: 0)],
    );
    expect(d['modemUse'], {'assetId': 'm1', 'condition': 'nuevo'});
    expect(d['materialsUsed'], [
      {'assetId': 'fibra', 'qty': 100.0},
    ]);
    expect(datosMateriales(userId: 'u1', nombre: 'Ana', modemId: '', insumos: const [])['modemUse'], {'none': true});
    final g = gastoMateriales(
      cat,
      modemId: 'm1',
      insumos: const [(assetId: 'fibra', qty: 100), (assetId: 'conector', qty: 2)],
    );
    expect((g.modem, g.insumos), (900.0, 270.0));
  });

  test('servicio: lee activos, categorías e insumos por localidad', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('assetCategories').doc('dp').set({'name': 'Modem Doble Play'});
    await db.collection('assets').doc('m1').set({'name': 'Huawei', 'categoryId': 'dp'});
    await db.collection('assets').doc('fibra').set({'name': 'Fibra'});
    await db.collection('zones').doc('Comalcalco').set({
      'name': 'Comalcalco',
      'supplyQty': [
        {'assetId': 'fibra', 'qty': 250},
      ],
    });
    final c = await ServicioOrdenes(db: db).materiales();
    expect(c.activo('m1')!.esModem, isTrue);
    expect(c.insumosPorZona['Comalcalco'], {'fibra': 250.0});
  });
}
