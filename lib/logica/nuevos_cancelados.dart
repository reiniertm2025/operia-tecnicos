import 'package:cloud_firestore/cloud_firestore.dart';

import 'cobro.dart';
import 'orden.dart';

/// Menús «Nuevos Servicios» y «Cancelados» de la web (src/legacy/app.js: futureList, renderNewPending, npAlert,
/// renderNewServices, renderNewCancelled, cancelKind, renderCancelList, renderModems, renderTempCancels, tcLight, ifaRows,
/// isIspService; src/features/zones/pay-dates.ts: payCycle, matchPayDate). Solo los ve el administrador.

// ---------- Futuro y Pendientes ----------

/// Futuro (`futureList`): no completada, no cancelada y su día de servicio es después de hoy.
bool esFutura(Orden o, String hoy) => o.estado != 'completada' && o.estado != 'cancelada' && o.dia.compareTo(hoy) > 0;

/// Nuevos Servicios › Pendientes: servicio nuevo, sin cancelar, pendiente o en proceso.
bool esNuevoPendiente(Orden o, Catalogos cat) =>
    esServicioNuevo(o, cat) && (o.estado == 'pendiente' || o.estado == 'en_proceso');

enum CuandoToca { atrasada, hoy, futura }

/// Días de `de` a `a` (AAAA-MM-DD), sin que el horario de verano los mueva (como `Math.round` de la web).
int diasEntre(String de, String a) =>
    DateTime.parse('${a}T00:00:00Z').difference(DateTime.parse('${de}T00:00:00Z')).inDays;

/// `npAlert`: atrasada (cuántos días), toca hoy, o en cuántos días.
({CuandoToca cuando, int dias}) cuandoToca(Orden o, String hoy) {
  final n = diasEntre(hoy, o.dia.isEmpty ? hoy : o.dia);
  return n < 0
      ? (cuando: CuandoToca.atrasada, dias: -n)
      : (cuando: n == 0 ? CuandoToca.hoy : CuandoToca.futura, dias: n);
}

/// Como `futSort` de la web: por día, luego por hora y luego la que se registró primero.
List<Orden> porDiaYHora(Iterable<Orden> l) => [...l]
  ..sort((a, b) {
    final c = a.dia.compareTo(b.dia);
    if (c != 0) return c;
    final h = (a.hora.isEmpty ? '99' : a.hora).compareTo(b.hora.isEmpty ? '99' : b.hora);
    if (h != 0) return h;
    return (a.creadaEn ?? DateTime(0)).compareTo(b.creadaEn ?? DateTime(0));
  });

// ---------- Histórico y Cancelados ----------

/// `serviceLabel`: el nombre del servicio en el catálogo (si no está, el guardado en la orden).
String nombreServicio(Orden o, Catalogos cat) {
  final n = '${cat.servicios[o.datos['serviceType']]?['name'] ?? ''}'.trim();
  return n.isNotEmpty ? n : o.servicio;
}

/// Nuevos Servicios › Histórico: servicio nuevo sin cancelar. Cancelados › Nuevos Servicios: servicio nuevo cancelado.
bool esNuevoHistorico(Orden o, Catalogos cat) => esServicioNuevo(o, cat) && o.estado != 'cancelada';
bool esNuevoCancelado(Orden o, Catalogos cat) => esServicioNuevo(o, cat) && o.estado == 'cancelada';

enum CancelTv { cable, fibra }

/// `cancelKindName`: «Cancelar Servicio TV Doble Play» (o TV Fibra) → fibra; «… TV Cable» → cable.
CancelTv? cancelacionTvDe(String nombre) {
  final n = plano(nombre);
  if (!RegExp('cancel|canel').hasMatch(n) || !RegExp(r'\btv\b|television').hasMatch(n)) return null;
  if (RegExp('fibra|doble|double|play').hasMatch(n)) return CancelTv.fibra;
  return n.contains('cable') ? CancelTv.cable : null;
}

/// `cancelKind`: con el nombre del servicio en el catálogo.
CancelTv? cancelacionTv(Orden o, Catalogos cat) => cancelacionTvDe(nombreServicio(o, cat));

/// Cancelados › Definitivos (`isBajaTicket` / `isBajaService`): trae el módem a recuperar, o el servicio es una baja o
/// una cancelación definitiva (no una temporal o suspensión, ni de TV).
bool esBajaDefinitiva(Orden o, Catalogos cat) {
  final e = o.datos['bajaEquipment'];
  if (e != null && e != false && e != '') return true;
  final nombre = nombreServicio(o, cat);
  final n = plano(nombre);
  return (RegExp(r'\bbajas?\b').hasMatch(n) || (RegExp('cancel|canel').hasMatch(n) && n.contains('definitiv'))) &&
      !RegExp(r'\btemporal(es)?\b|\bsuspension\b').hasMatch(n) &&
      cancelacionTvDe(nombre) == null;
}

DateTime? _fecha(Object? v) => v is Timestamp ? v.toDate() : null;

/// Las listas por fechas van del día más nuevo al más viejo (y, el mismo día, la creada después primero).
List<Orden> masNuevasPrimero(Iterable<Orden> l) => [...l]
  ..sort((a, b) {
    final c = b.dia.compareTo(a.dia);
    if (c != 0) return c;
    return (b.creadaEn ?? DateTime(0)).compareTo(a.creadaEn ?? DateTime(0));
  });

/// Por una fecha de la orden (`cancelledAt`, `createdAt`…), la más nueva primero.
List<Orden> masNuevasPor(Iterable<Orden> l, String campo) =>
    [...l]..sort((a, b) => (_fecha(b.datos[campo]) ?? DateTime(0)).compareTo(_fecha(a.datos[campo]) ?? DateTime(0)));

// ---------- Temporales ----------

/// Un registro de Cancelados › Temporales (`tempCancels`).
class Temporal extends RegistroCliente {
  const Temporal(super.id, super.datos);

  String _t(String c) => texto(c);
  String get motivo => _t('reason');
  String get modem => _t('modemName');
  String get folio => folioVisible(datos['ticketFolio']);
  String get regreso => _t('activationDate');
  bool get recogeModem => datos['pickupModem'] == true;
  bool get anulado => datos['voided'] == true;

  /// activo | reactivado | …
  String get estado => _t('status').isEmpty ? 'activo' : _t('status');

  /// `tcRecState`: el módem a recoger.
  String get estadoModem =>
      datos['recStatus'] == 'recuperado' ? 'recuperado' : (_t('recById').isEmpty ? 'pendiente' : 'asignado');

  /// `tcDay`: el día en que se registró.
  String get dia => datos['createdAt'] is Timestamp ? textoDia((datos['createdAt'] as Timestamp).toDate()) : '';

  /// Para llamar y ver en el mapa como una orden.
  Orden get comoOrden =>
      Orden(id, {'clientName': nombre, 'clientPhone': telefono, 'address': direccion, 'zoneId': zonaId});
}

/// `tcLight`: activo con fecha de regreso ya llegada (roja) o en 3 días o menos (amarilla).
enum LuzTemporal { ninguna, pronto, vencida }

LuzTemporal luzTemporal(Temporal r, String hoy) {
  if (r.estado != 'activo' || r.regreso.isEmpty) return LuzTemporal.ninguna;
  if (r.regreso.compareTo(hoy) <= 0) return LuzTemporal.vencida;
  final n = diasEntre(hoy, r.regreso);
  return n <= 3 ? LuzTemporal.pronto : LuzTemporal.ninguna;
}

// ---------- Eliminar factura del ISP ----------

/// Sistema › Fechas de pago (`payDates`).
class FechaPago {
  const FechaPago(
    this.id, {
    required this.pagoDe,
    required this.pagoA,
    required this.factura,
    required this.instalaDe,
    required this.instalaA,
    this.zonas = const [],
  });

  factory FechaPago.de(String id, Map<String, dynamic> d) {
    int n(String c) => (num.tryParse('${d[c] ?? ''}') ?? 0).toInt();
    return FechaPago(
      id,
      pagoDe: n('payFrom'),
      pagoA: n('payTo'),
      factura: n('invoiceDay'),
      instalaDe: n('installFrom'),
      instalaA: n('installTo'),
      zonas: [for (final z in (d['zoneIds'] as List? ?? const [])) '$z'],
    );
  }

  final String id;
  final int pagoDe, pagoA, factura, instalaDe, instalaA;
  final List<String> zonas;

  bool _dia(int x) => x >= 1 && x <= 31;
  bool get valida => _dia(pagoDe) && _dia(pagoA) && _dia(factura) && _dia(instalaDe) && _dia(instalaA);
  bool aplica(String zona) => zonas.isEmpty || zonas.contains(zona);
}

/// Como `pdSorted` de la web: por día de pago, luego fin de pago y luego inicio de instalación.
List<FechaPago> ordenarFechasPago(Iterable<FechaPago> l) => [...l]
  ..sort((a, b) {
    final c = a.pagoDe.compareTo(b.pagoDe);
    if (c != 0) return c;
    final d = a.pagoA.compareTo(b.pagoA);
    return d != 0 ? d : a.instalaDe.compareTo(b.instalaDe);
  });

bool _enRango(int dia, int de, int a) => de <= a ? dia >= de && dia <= a : dia >= de || dia <= a;

/// El día pedido en ese mes (si es más corto, su último día), en AAAA-MM-DD, como `at` de pay-dates.ts.
String _el(int y, int m, int d) {
  final yy = y + (m / 12).floor();
  final mm = ((m % 12) + 12) % 12;
  final ultimo = DateTime(yy, mm + 2, 0).day;
  return textoDia(DateTime(yy, mm + 1, d < ultimo ? d : ultimo));
}

/// `payCycle`: para una instalación (AAAA-MM-DD), cuándo empieza y termina su primer pago y el día de la factura del ISP;
/// null si no entra en esa fecha de pago.
({String pagoInicio, String pagoFin, String factura})? cicloDePago(String instalacion, FechaPago p) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(instalacion);
  if (m == null || !p.valida) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!) - 1, d = int.parse(m[3]!);
  if (!_enRango(d, p.instalaDe, p.instalaA)) return null;
  var sm = mo;
  var inicio = _el(y, sm, p.pagoDe);
  if (inicio.compareTo(instalacion) < 0) {
    sm = mo + 1;
    inicio = _el(y, sm, p.pagoDe);
  }
  final fin = _el(y, p.pagoA >= p.pagoDe ? sm : sm + 1, p.pagoA);
  var factura = _el(y, sm, p.factura);
  if (factura.compareTo(inicio) > 0) factura = _el(y, sm - 1, p.factura);
  return (pagoInicio: inicio, pagoFin: fin, factura: factura);
}

/// `isIspService`: el servicio va con el ISP (los nuevos y las cancelaciones de TV).
bool servicioIsp(Map<String, dynamic>? s) {
  if (s == null) return true;
  if (s['isp'] is bool) return s['isp'] as bool;
  final n = plano(s['name']);
  final nuevo = s['commission'] is bool ? s['commission'] as bool : RegExp('nuev').hasMatch(n);
  return nuevo || (n.contains('cancel') && RegExp('tv|television').hasMatch(n));
}

/// Una fila de Eliminar factura del ISP.
typedef FilaFactura = ({
  Orden orden,
  String instalacion,
  FechaPago fecha,
  ({String pagoInicio, String pagoFin, String factura}) ciclo,
  bool hecha,
});

/// `ifaRows`: servicios nuevos ya instalados (completados) que van con el ISP, con su fecha de pago según el día de
/// instalación y la localidad.
List<FilaFactura> filasFactura(Iterable<Orden> ordenes, List<FechaPago> fechas, Catalogos cat) {
  final lista = ordenarFechasPago(fechas);
  final filas = <FilaFactura>[];
  if (lista.isEmpty) return filas;
  for (final o in ordenes) {
    if (o.estado != 'completada' || !esServicioNuevo(o, cat)) continue;
    final s = cat.servicios[o.datos['serviceType']];
    if (s != null && !servicioIsp(s)) continue;
    final dia = o.completadaEn != null ? textoDia(o.completadaEn!) : o.dia;
    for (final p in lista) {
      if (!p.aplica(o.zonaId)) continue;
      final c = cicloDePago(dia, p);
      if (c == null) continue;
      final hecha = o.datos['ispInvoice'] is Map && (o.datos['ispInvoice'] as Map)['done'] == true;
      filas.add((orden: o, instalacion: dia, fecha: p, ciclo: c, hecha: hecha));
      break;
    }
  }
  return filas..sort((a, b) => a.ciclo.factura.compareTo(b.ciclo.factura));
}

/// Marcar que ya se eliminó la factura en el ISP (como el botón «Completado» de la web).
Map<String, Object?> datosFacturaEliminada(FilaFactura f, String userId, String nombre) => {
  'ispInvoice': {
    'done': true,
    'at': FieldValue.serverTimestamp(),
    'byId': userId,
    'byName': nombre,
    'payDateId': f.fecha.id,
    'invoiceDate': f.ciclo.factura,
  },
};

/// Deshacer la marca (como «Deshacer» de la web).
Map<String, Object?> datosFacturaPendiente() => {'ispInvoice': FieldValue.delete()};
