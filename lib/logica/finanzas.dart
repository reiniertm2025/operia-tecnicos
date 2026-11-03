import 'package:cloud_firestore/cloud_firestore.dart';

import 'cobro.dart';
import 'metricas.dart';
import 'modems.dart';
import 'orden.dart';

/// Finanzas del administrador: lo principal del Estado financiero de la web (src/legacy/app.js: erModel;
/// src/features/service-income/logic.ts: incomeInRange). Salarios y materiales (AFT, insumos) no entran: se ven en la web.
///
/// - Ingresos de servicios (`serviceIncome`): cada registro cubre dateFrom..dateTo (los viejos solo `date`) y cuenta si se
///   cruza con el periodo; se suman por forma de pago.
/// - Cobros de órdenes: completadas en efectivo o transferencia (sin reparaciones ni bajas), por el día en que se cobraron.
/// - Gastos (`expenses`): por partida (`category`).
/// - Comisiones: Pago de comisiones del periodo; cuentan como gasto si existe la partida automática «comisiones» (o si no
///   hay partidas: la web usa las de siempre, que la traen).

String _dia(Object? v) {
  final m = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch('${v ?? ''}'.trim());
  return m?[0] ?? '';
}

/// Del día `desde` al día `hasta` (los dos incluidos, AAAA-MM-DD), como `incomeInRange`.
bool ingresoEnRango(Map<String, dynamic> r, String desde, String hasta) {
  final de = _dia(r['dateFrom']).isNotEmpty ? _dia(r['dateFrom']) : _dia(r['date']);
  final a = _dia(r['dateTo']).isNotEmpty ? _dia(r['dateTo']) : de;
  return a.compareTo(desde) >= 0 && de.compareTo(hasta) <= 0;
}

double _monto(Object? v) => (v is num ? v.toDouble() : double.tryParse('${v ?? ''}')) ?? 0;

/// Una línea con nombre e importe (forma de pago o partida).
typedef Linea = ({String nombre, double importe});

List<Linea> _sumar(Iterable<Map<String, dynamic>> filas, String Function(Map<String, dynamic>) nombre) {
  final m = <String, double>{};
  for (final r in filas) {
    final n = nombre(r);
    m[n] = (m[n] ?? 0) + _monto(r['amount']);
  }
  return [for (final e in m.entries) (nombre: e.key, importe: (e.value * 100).round() / 100)]
    ..sort((a, b) => b.importe.compareTo(a.importe));
}

double _total(List<Linea> l) => l.fold(0.0, (s, x) => s + x.importe);

class Finanzas {
  Finanzas({
    required List<Map<String, dynamic>> ingresos,
    required List<Map<String, dynamic>> gastos,
    required List<Map<String, dynamic>> partidas,
    required Iterable<Orden> ordenes,
    required List<Comision> comisiones,
    required Catalogos cat,
    required DateTime desde,
    required DateTime hastaExclusivo,
    String? zona,
    required String sinFormaDePago,
    required String otrosGastos,
  }) {
    final de = textoDia(desde);
    final a = textoDia(hastaExclusivo.subtract(const Duration(days: 1)));
    bool deZona(Object? id) => zona == null || '${id ?? ''}' == zona;
    porFormaDePago = _sumar(
      ingresos.where((r) => deZona(r['localityId']) && ingresoEnRango(r, de, a)),
      (r) => '${r['paymentMethodName'] ?? ''}'.trim().isEmpty ? sinFormaDePago : '${r['paymentMethodName']}'.trim(),
    );
    porPartida = _sumar(
      gastos.where(
        (g) => deZona(g['localityId']) && _dia(g['date']).compareTo(de) >= 0 && _dia(g['date']).compareTo(a) <= 0,
      ),
      (g) => '${g['category'] ?? ''}'.trim().isEmpty ? otrosGastos : '${g['category']}'.trim(),
    );
    for (final o in ordenes) {
      if (!deZona(o.zonaId) || !cobrada(o) || o.estado != 'completada') continue;
      final f = _cuandoSeCobro(o);
      if (f == null || f.isBefore(desde) || !f.isBefore(hastaExclusivo)) continue;
      cobros += importeCobrado(o, cat) ?? 0;
      cobrosCuantos++;
    }
    cobros = (cobros * 100).round() / 100;
    cuentanComisiones = partidas.isEmpty || partidas.any((p) => p['auto'] == 'comisiones');
    // como el Balance de la web: solo las comisiones de órdenes (las de Importados ISP no entran)
    comisionesTotal = totalComisiones(
      comisiones.where((c) => c.tipo != TipoComision.modemIsp && deZona(c.orden.zonaId)),
    );
  }

  late final List<Linea> porFormaDePago;
  late final List<Linea> porPartida;
  double cobros = 0;
  int cobrosCuantos = 0;
  late final double comisionesTotal;
  late final bool cuentanComisiones;

  double get ingresosServicios => _total(porFormaDePago);
  double get gastosRegistrados => _total(porPartida);
  double get entradas => ingresosServicios + cobros;
  double get salidas => gastosRegistrados + (cuentanComisiones ? comisionesTotal : 0);
  double get resultado => entradas - salidas;

  /// El día en que se cobró, como erModel: pendingPaidAt, completedAt o paymentUpdatedAt.
  static DateTime? _cuandoSeCobro(Orden o) {
    for (final c in const ['pendingPaidAt', 'completedAt', 'paymentUpdatedAt']) {
      if (o.datos[c] case final Timestamp t) return t.toDate();
    }
    return null;
  }
}
