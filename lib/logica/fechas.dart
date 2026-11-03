// Rangos de días para filtrar el historial, como los botones rápidos de la web (la semana empieza en lunes).

/// Días completos: de `desde` (00:00) hasta `hasta` (incluido).
typedef RangoDias = ({DateTime desde, DateTime hasta});

enum RangoRapido { hoy, semana, mes, mesAnterior }

RangoDias rangoRapido(RangoRapido r, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  return switch (r) {
    RangoRapido.hoy => (desde: hoy, hasta: hoy),
    RangoRapido.semana => (desde: hoy.subtract(Duration(days: hoy.weekday - 1)), hasta: hoy.add(Duration(days: 7 - hoy.weekday))),
    RangoRapido.mes => (desde: DateTime(hoy.year, hoy.month), hasta: DateTime(hoy.year, hoy.month + 1, 0)),
    RangoRapido.mesAnterior => (desde: DateTime(hoy.year, hoy.month - 1), hasta: DateTime(hoy.year, hoy.month, 0)),
  };
}

/// Cuál botón rápido corresponde al rango (null si es un rango elegido a mano).
RangoRapido? rapidoDe(RangoDias? rango, DateTime ahora) {
  if (rango == null) return null;
  for (final r in RangoRapido.values) {
    if (rangoRapido(r, ahora) == rango) return r;
  }
  return null;
}

/// El primer instante después del rango (para buscar con «menor que»).
DateTime finDeRango(RangoDias r) => DateTime(r.hasta.year, r.hasta.month, r.hasta.day + 1);

/// El rango cortado en hoy, como el Dashboard de la web (`anSetRange`): «Este mes» es del 1 a hoy, no hasta el 30.
RangoDias hastaHoy(RangoDias r, DateTime ahora) {
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  return (desde: r.desde, hasta: r.hasta.isAfter(hoy) ? hoy : r.hasta);
}
