import '../servicios/sesion.dart';
import 'orden.dart';
import 'tablero.dart';

/// Qué órdenes avisar (decisión del dueño, 3 nov 2026: solo las nuevas y las que regresan de estado, por si hay que
/// corregirlo). Compara cada foto de las órdenes abiertas con la anterior:
/// - La primera foto no avisa nada (son las que ya estaban).
/// - Una orden que aparece y se creó después de encender el aviso es «nueva» («asignada» si ya viene a su nombre).
/// - Una orden que aparece y ya era vieja regresó de Completada a En proceso o Pendiente: «regresó».
/// - Una orden que estaba en proceso y la oficina regresa a pendiente es «regresó»; si quedó para otro día (la
///   pospusieron), no se avisa.
/// - Ya no se avisa cuando una orden que ya estaba se le asigna o avanza (pendiente → en proceso).

enum TipoAviso { nueva, asignada, regreso }

/// Solo se avisa de las localidades que el usuario tiene marcadas (decisión del dueño, 2 nov 2026), también al
/// administrador; sin ninguna marcada, de todas (como la web). Las que son suyas siempre se avisan.
bool leAvisa(Tecnico quien, Orden o) =>
    leToca(quien, o) && (o.esDe(quien.userId) || quien.zonas.isEmpty || quien.zonas.contains(o.zonaId));

class Aviso {
  const Aviso(this.orden, this.tipo);
  final Orden orden;
  final TipoAviso tipo;
}

class Vigia {
  /// `desde`: cuándo se encendió el aviso (solo las pruebas lo cambian).
  Vigia(this.quien, {DateTime? desde}) : desde = desde ?? DateTime.now();

  final Tecnico quien;
  final DateTime desde;

  /// Diferencia que se tolera entre el reloj del teléfono y el de Firebase al decidir si una orden es nueva.
  static const _margen = Duration(minutes: 5);

  /// Id de cada orden que ya se vio → en qué estado estaba.
  Map<String, String>? _antes;

  /// Pendientes que le tocan en la última foto (para el texto del aviso fijo).
  int pendientes = 0;

  /// `hoy` (AAAA-MM-DD) solo para las pruebas.
  List<Aviso> revisar(Iterable<Orden> abiertas, {String? hoy}) {
    final ahora = {
      for (final o in abiertas)
        if ((o.estado == 'pendiente' || o.estado == 'en_proceso') && leAvisa(quien, o)) o.id: o,
    };
    // el número del aviso fijo cuenta lo mismo que la pestaña Pendientes (leToca: el administrador, todas); solo el
    // sonido se limita a sus localidades marcadas
    pendientes = abiertas.where((o) => o.estado == 'pendiente' && leToca(quien, o)).length;
    final antes = _antes;
    _antes = {for (final o in ahora.values) o.id: o.estado};
    if (antes == null) return const [];
    final dia = hoy ?? textoDia(DateTime.now());
    TipoAviso? tipo(Orden o) {
      final previa = antes[o.id];
      if (previa == null) {
        final creada = o.creadaEn;
        // sin fecha todavía (se acaba de crear) o creada con el aviso encendido: nueva
        if (creada == null || !creada.isBefore(desde.subtract(_margen))) {
          return o.esDe(quien.userId) ? TipoAviso.asignada : TipoAviso.nueva;
        }
        // vieja que vuelve a las abiertas: la regresaron de Completada
        return TipoAviso.regreso;
      }
      // de en proceso a pendiente; al posponer la web también la regresa a pendiente: si quedó para otro día no se avisa
      if (previa == 'en_proceso' && o.estado == 'pendiente' && o.dia.compareTo(dia) <= 0) return TipoAviso.regreso;
      return null;
    }

    return [
      for (final o in ahora.values)
        if (tipo(o) case final t?) Aviso(o, t),
    ];
  }
}
