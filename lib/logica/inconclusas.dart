import 'package:cloud_firestore/cloud_firestore.dart';

import 'orden.dart';

/// Órdenes de trabajo › Inconclusas, igual que la web (src/features/incomplete/logic.ts; src/legacy/app.js: ipForm, incResolve):
/// órdenes completadas que dejaron algo pendiente (ej. se puso un módem de solo internet y falta el Doble Play).
/// En la orden: incPending, incDue (AAAA-MM-DD), incReason, incAt/incById/incByName; al resolverse: incPending=false,
/// incResolvedAt/incResolvedById/incResolvedByName.

/// Semáforo: atrasada (ya pasó la fecha), hoy, o próxima (todavía no llega, o sin fecha).
enum LuzInconclusa { atrasada, hoy, proxima }

bool esInconclusa(Orden o) => o.datos['incPending'] == true;

String fechaRegreso(Orden o) => '${o.datos['incDue'] ?? ''}';
String motivoInconclusa(Orden o) => '${o.datos['incReason'] ?? ''}';

LuzInconclusa luzInconclusa(Orden o, String hoy) {
  final d = fechaRegreso(o);
  if (d.isEmpty) return LuzInconclusa.proxima;
  final c = d.compareTo(hoy);
  return c < 0 ? LuzInconclusa.atrasada : (c == 0 ? LuzInconclusa.hoy : LuzInconclusa.proxima);
}

/// Primero las atrasadas, luego hoy y luego las próximas; dentro, por fecha (`incSort`).
List<Orden> ordenarInconclusas(Iterable<Orden> l, String hoy) => [...l]
  ..sort((a, b) {
    final c = luzInconclusa(a, hoy).index.compareTo(luzInconclusa(b, hoy).index);
    if (c != 0) return c;
    String f(Orden o) => fechaRegreso(o).isEmpty ? '9999' : fechaRegreso(o);
    return f(a).compareTo(f(b));
  });

Map<String, Object?> _cambio(String userId, String nombre) => {
  'lastChangedById': userId,
  'lastChangedByName': nombre,
  'lastChangedAt': FieldValue.serverTimestamp(),
};

/// Marcarla inconclusa (o cambiar su fecha y motivo). La primera vez guarda quién y cuándo, y borra lo de una vez anterior.
Map<String, Object?> datosInconclusa(
  Orden o, {
  required String dia,
  required String motivo,
  required String userId,
  required String nombre,
}) {
  final primera = !esInconclusa(o);
  return {
    'incPending': true,
    'incDue': dia,
    'incReason': motivo,
    if (primera) ...{
      'incAt': FieldValue.serverTimestamp(),
      'incById': userId,
      'incByName': nombre,
      'incResolvedAt': FieldValue.delete(),
      'incResolvedByName': FieldValue.delete(),
      'incResolvedById': FieldValue.delete(),
    },
    ..._cambio(userId, nombre),
  };
}

Map<String, Object?> datosResolverInconclusa(String userId, String nombre) => {
  'incPending': false,
  'incResolvedAt': FieldValue.serverTimestamp(),
  'incResolvedById': userId,
  'incResolvedByName': nombre,
  ..._cambio(userId, nombre),
};
