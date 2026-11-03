import '../servicios/sesion.dart';
import 'orden.dart';

/// Qué ve cada quien en las pestañas de abajo (Pendientes, En proceso, Culminadas).
/// - Administrador: todas las órdenes de todas las localidades.
/// - Técnico: las suyas, y las que no tienen técnico en sus localidades (para aceptarlas).
class Tablero {
  Tablero({required Tecnico quien, required Iterable<Orden> abiertas, required Iterable<Orden> culminadasHoy, String? zona}) {
    bool enZona(Orden o) => zona == null || o.zonaId == zona;
    for (final o in abiertas) {
      if (!enZona(o) || !leToca(quien, o)) continue;
      if (o.estado == 'pendiente') pendientes.add(o);
      if (o.estado == 'en_proceso') enProceso.add(o);
    }
    culminadas
      ..addAll(culminadasHoy.where((o) => o.estado == 'completada' && enZona(o) && (quien.esAdmin || o.esDe(quien.userId))))
      ..sort((a, b) => (b.completadaEn ?? DateTime(0)).compareTo(a.completadaEn ?? DateTime(0)));
  }

  final pendientes = <Orden>[];
  final enProceso = <Orden>[];
  final culminadas = <Orden>[];
}

/// Si la orden le toca: el administrador, todas; el técnico, las suyas y las sin técnico de sus localidades.
bool leToca(Tecnico quien, Orden o) =>
    quien.esAdmin || o.esDe(quien.userId) || (!o.tieneTecnico && quien.zonas.contains(o.zonaId));

/// Une las órdenes de varias consultas (la misma orden puede salir en dos), sin repetirlas.
List<Orden> unirSinRepetir(Iterable<List<Orden>> listas) {
  final porId = <String, Orden>{};
  for (final lista in listas) {
    for (final o in lista) {
      porId[o.id] = o;
    }
  }
  return porId.values.toList();
}
