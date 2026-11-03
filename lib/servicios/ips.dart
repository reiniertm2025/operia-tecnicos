import 'package:cloud_firestore/cloud_firestore.dart';

import '../logica/ips.dart';
import 'ordenes.dart';
import 'sesion.dart';

/// IPs libres publicadas por el administrador (`ipSegments`). Las reglas de la web dejan a cualquier usuario cambiar solo
/// `taken` (apartar y liberar); publicar y quitar segmentos es de la web.
class ServicioIps {
  ServicioIps({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _segmentos => _db.collection('ipSegments');

  /// Segmentos en vivo: el administrador, todos; el técnico, solo los de sus localidades (hasta 30 por consulta).
  Stream<List<SegmentoIp>> segmentos(Tecnico t) {
    if (!t.esAdmin && t.zonas.isEmpty) return Stream.value(const []);
    final q = t.esAdmin ? _segmentos : _segmentos.where('zoneId', whereIn: t.zonas.take(30).toList());
    return q.snapshots().map((s) => [for (final d in s.docs) SegmentoIp(d.id, d.data())]);
  }

  /// Aparta la IP solo si sigue libre y en la lista (por si otro la aparta al mismo tiempo). Necesita internet.
  Future<void> apartar(SegmentoIp s, String ip, Tecnico t) => _cambiar(s, (actual, tx, ref) {
    if (!actual.libres.contains(ip) || actual.apartadaDe(ip) != null) throw const ErrorDeOrden(FalloOrden.ipOcupada);
    tx.update(ref, datosApartar(ip, t.userId, t.nombre, DateTime.now()));
  });

  /// Libera una IP apartada por él (o cualquiera, si es administrador).
  Future<void> liberar(SegmentoIp s, String ip, Tecnico t) => _cambiar(s, (actual, tx, ref) {
    final a = actual.apartadaDe(ip);
    if (a == null) return;
    if (!puedeLiberar(a, t.userId, esAdmin: t.esAdmin)) throw const ErrorDeOrden(FalloOrden.sinPermiso);
    tx.update(ref, {'taken.${claveIp(ip)}': FieldValue.delete()});
  });

  Future<void> _cambiar(
    SegmentoIp s,
    void Function(SegmentoIp actual, Transaction tx, DocumentReference<Map<String, dynamic>> ref) cambio,
  ) => ServicioOrdenes.seguro(
    () => _db
        .runTransaction((tx) async {
          final ref = _segmentos.doc(s.id);
          final d = (await tx.get(ref)).data();
          if (d == null) throw const ErrorDeOrden(FalloOrden.ipOcupada);
          cambio(SegmentoIp(s.id, d), tx, ref);
        })
        .timeout(ServicioOrdenes.espera, onTimeout: () => throw const ErrorDeOrden(FalloOrden.sinInternet)),
  );
}
