import '../servicios/sesion.dart';
import 'orden.dart';
import 'tablero.dart';

/// Qué órdenes avisar: compara cada foto de las órdenes abiertas con la anterior.
/// - La primera foto no avisa nada (son las que ya estaban).
/// - Una orden que aparece y le toca (ver `leToca`) es «nueva», o «asignada» si ya viene a su nombre.
/// - Una orden que ya estaba y ahora pasa a su nombre es «asignada».
/// - Una orden que ya estaba en proceso y la oficina regresa a pendiente (la web le quita el técnico) es «regresó»;
///   si quedó para otro día (la pospusieron), no se avisa.

enum TipoAviso { nueva, asignada, regreso }

/// Solo se avisa de las localidades que el usuario tiene marcadas (decisión del dueño, 2 nov 2026), también al
/// administrador; sin ninguna marcada, de todas (como la web). Las que le asignan a él siempre se avisan.
bool leAvisa(Tecnico quien, Orden o) =>
    leToca(quien, o) && (o.esDe(quien.userId) || quien.zonas.isEmpty || quien.zonas.contains(o.zonaId));

class Aviso {
  const Aviso(this.orden, this.tipo);
  final Orden orden;
  final TipoAviso tipo;
}

class Vigia {
  Vigia(this.quien);

  final Tecnico quien;

  /// Id de cada orden que ya se vio → si ya era suya y en qué estado estaba.
  Map<String, ({bool suya, String estado})>? _antes;

  /// Pendientes que le tocan en la última foto (para el texto del aviso fijo).
  int pendientes = 0;

  /// `hoy` (AAAA-MM-DD) solo para las pruebas.
  List<Aviso> revisar(Iterable<Orden> abiertas, {String? hoy}) {
    final ahora = {
      for (final o in abiertas)
        if ((o.estado == 'pendiente' || o.estado == 'en_proceso') && leAvisa(quien, o)) o.id: o,
    };
    pendientes = ahora.values.where((o) => o.estado == 'pendiente').length;
    final antes = _antes;
    _antes = {for (final o in ahora.values) o.id: (suya: o.esDe(quien.userId), estado: o.estado)};
    if (antes == null) return const [];
    TipoAviso? tipo(Orden o) {
      final previa = antes[o.id];
      final suya = o.esDe(quien.userId);
      if (previa == null) return suya ? TipoAviso.asignada : TipoAviso.nueva;
      if (!previa.suya && suya) return TipoAviso.asignada;
      // al posponer, la web también la regresa a pendiente: si quedó para otro día no se avisa
      if (previa.estado != 'pendiente' &&
          o.estado == 'pendiente' &&
          o.dia.compareTo(hoy ?? textoDia(DateTime.now())) <= 0) {
        return TipoAviso.regreso;
      }
      return null;
    }

    return [
      for (final o in ahora.values)
        if (tipo(o) case final t?) Aviso(o, t),
    ];
  }
}
