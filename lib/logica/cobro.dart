import 'package:cloud_firestore/cloud_firestore.dart';

import 'acciones.dart';
import 'orden.dart';

/// Cobro al completar una orden, igual que «Forma de pago al completar» de la web (src/legacy/app.js:
/// openPaymentModal, savePayment, needsPayment; src/features/charges/logic.ts).
///
/// Paso 1: qué se cobró (conceptos del catálogo `serviceCharges`). Paso 2: cómo pagó el cliente.
/// - Efectivo: queda completada.
/// - Pendiente de pago / Sin costo: sigue en proceso y la oficina lo autoriza en la web (payAuthStatus «solicitada»).
/// - Transferencia: las reglas no dejan a la app subir el comprobante; sigue en proceso con el aviso
///   (techDone…, techPayMethod) y la oficina sube el comprobante y la completa en la web.

/// Formas de pago de la web y las que necesitan autorización de la oficina (AUTH_METHODS).
enum FormaPago { efectivo, transferencia, pendiente, sinCosto }

extension on FormaPago {
  String get valor => this == FormaPago.sinCosto ? 'sin_costo' : name;
}

bool necesitaAutorizacion(FormaPago f) => f == FormaPago.pendiente || f == FormaPago.sinCosto;

/// Catálogos de la web que hacen falta para el cobro: `serviceCharges` y `services`.
class Catalogos {
  const Catalogos({required this.cobros, required this.servicios});

  /// Cada cobro con su id (`id`), `serviceName`, `amount`, `order` y a veces `serviceId`.
  final List<Map<String, dynamic>> cobros;

  /// Servicios por id, con `name`, `billable` y `commission`.
  final Map<String, Map<String, dynamic>> servicios;
}

// ---------- cómo clasifica la web cada orden ----------

String _clave(Object? v) => plano(v).trim().replaceAll(RegExp(r'\s+'), ' ');
bool _esOtros(Object? n) => RegExp(r'^otros?$').hasMatch(_clave(n));
bool _esReconexion(Object? n) => RegExp(r'^re ?conexion(es)?\b').hasMatch(_clave(n));

/// «Otros» y «Reconexión»: el importe se escribe al completar y llevan comentario.
bool esCobroAbierto(Object? nombre) => _esOtros(nombre) || _esReconexion(nombre);

String nombreCobro(Map<String, dynamic> c, Catalogos cat) =>
    '${c['serviceName'] ?? cat.servicios[c['serviceId']]?['name'] ?? '-'}';
bool _esPlan(Map<String, dynamic> c, Catalogos cat) => RegExp(r'^plan\b').hasMatch(plano(nombreCobro(c, cat)).trim());
double? _importe(Map<String, dynamic> c) {
  final a = c['amount'];
  if (a == null || a == '') return null;
  final n = a is num ? a.toDouble() : double.tryParse('$a');
  return n != null && n.isFinite ? n : null;
}

double _redondear(double v) => (v * 100).round() / 100;

const _serviciosQueCobran = ['reconexion', 'cambio de domicilio', 'tv adicional', 'cambio de contrasena'];

/// `isNewServiceTicket`: servicio nuevo (se cobra un plan).
bool esServicioNuevo(Orden o, Catalogos cat) {
  if (o.esBaja) return false;
  if (o.datos['commission'] == true) return true;
  final s = cat.servicios[o.datos['serviceType']];
  if (s != null) {
    return s['commission'] is bool
        ? s['commission'] as bool
        : RegExp('nuev', caseSensitive: false).hasMatch('${s['name'] ?? ''}');
  }
  return RegExp('nuev', caseSensitive: false).hasMatch('${o.datos['serviceName'] ?? ''}');
}

/// `isChargeTicket`: lleva cobro de servicio.
bool _esDeCobro(Orden o, Catalogos cat) {
  if (o.sinCobro) return false;
  final items = o.datos['chargeItems'];
  if (items is List) return items.isNotEmpty;
  if (o.datos['billable'] == true) return true;
  final tipo = o.datos['serviceType'];
  if (cat.cobros.any((c) => c['serviceId'] != null && c['serviceId'] == tipo)) return true;
  final s = cat.servicios[tipo];
  if (s == null) return false;
  return s['billable'] is bool ? s['billable'] as bool : _serviciosQueCobran.contains(_clave(s['name']));
}

/// `needsPayment`: al completar hay que registrar el cobro.
bool llevaCobro(Orden o, Catalogos cat) => esServicioNuevo(o, cat) || _esDeCobro(o, cat);

/// La app la completa sin pasar por el cobro (como el botón de estado de la web).
bool completaSinCobro(Orden o, Catalogos cat) => !o.esperaAutorizacion && (o.sinCobro || !llevaCobro(o, cat));

// ---------- paso 1: conceptos ----------

/// Un renglón del paso 1. `importe` null = hay que escribirlo.
class Concepto {
  Concepto({
    required this.chargeId,
    required this.nombre,
    required this.importe,
    this.marcado = false,
    this.nota = '',
    this.cantidad,
  });

  final String chargeId;
  final String nombre;
  double? importe;
  bool marcado;
  String nota;
  final int? cantidad;

  /// Datos que el cobrador puede cambiar: «Otros», «Reconexión» o sin importe en el catálogo.
  late final bool editable = esCobroAbierto(nombre) || importe == null;
  bool get pideNota => esCobroAbierto(nombre);
}

/// Televisiones adicionales cobradas (`tvOf` de la web).
int _tvPagadas(Map<String, dynamic> d) {
  final viejo = (d['tvExtra'] as num?)?.toInt() ?? 0;
  if (d['tvPaidQty'] != null) return (d['tvPaidQty'] as num?)?.toInt() ?? 0;
  return d['tvExtraPaid'] == false ? 0 : viejo;
}

/// Conceptos que se ofrecen, ya marcados si la orden tenía un cobro guardado (`openPaymentModal`).
List<Concepto> conceptosPara(Orden o, Catalogos cat) {
  final nuevo = esServicioNuevo(o, cat);
  int grupo(Map<String, dynamic> c) => _esPlan(c, cat) ? 0 : (_esOtros(nombreCobro(c, cat)) ? 2 : 1);
  double orden(Map<String, dynamic> c) => double.tryParse('${c['order'] ?? ''}') ?? 1e9;
  final lista = [...cat.cobros]
    ..sort((a, b) {
      final r = orden(a).compareTo(orden(b));
      if (r != 0) return r;
      final g = grupo(a) - grupo(b);
      if (g != 0) return g;
      if (grupo(a) == 0) {
        final c = (_importe(a) ?? double.infinity).compareTo(_importe(b) ?? double.infinity);
        if (c != 0) return c;
      }
      return nombreCobro(a, cat).compareTo(nombreCobro(b, cat));
    });
  final filas = [
    for (final c in lista)
      if (_esPlan(c, cat) == nuevo)
        Concepto(chargeId: '${c['id'] ?? ''}', nombre: nombreCobro(c, cat), importe: _importe(c)),
  ];
  final guardados = o.datos['chargeItems'] is List ? (o.datos['chargeItems'] as List).whereType<Map>().toList() : null;
  // servicio nuevo con televisiones adicionales pagadas
  final tvs = _tvPagadas(o.datos);
  final tv = cat.cobros.where((c) => _clave(nombreCobro(c, cat)) == 'tv adicional').firstOrNull;
  if (nuevo && tvs > 0 && tv != null) {
    final precio = _importe(tv);
    filas.add(
      Concepto(
        chargeId: '${tv['id'] ?? ''}',
        nombre: tvs > 1 ? '${nombreCobro(tv, cat)} × $tvs' : nombreCobro(tv, cat),
        importe: precio == null ? null : _redondear(precio * tvs),
        marcado: guardados == null,
        cantidad: tvs,
      ),
    );
  }
  if (guardados != null) {
    for (final it in guardados) {
      final id = '${it['chargeId'] ?? ''}';
      final fila = filas
          .where((f) => (id.isNotEmpty && f.chargeId == id) || _clave(f.nombre) == _clave(it['name']))
          .firstOrNull;
      final importe = (it['amount'] as num?)?.toDouble() ?? double.tryParse('${it['amount']}') ?? 0;
      if (fila != null) {
        fila
          ..marcado = true
          ..importe = importe
          ..nota = '${it['comment'] ?? ''}';
      } else {
        filas.add(
          Concepto(
            chargeId: id,
            nombre: '${it['name'] ?? '-'}',
            importe: importe,
            marcado: true,
            nota: '${it['comment'] ?? ''}',
          ),
        );
      }
    }
  } else {
    final antes = o.datos['chargeAmount'];
    final habia = antes != null && antes != '';
    final c = habia
        ? cat.cobros.where((x) => x['serviceId'] != null && x['serviceId'] == o.datos['serviceType']).firstOrNull
        : null;
    final fila = c == null ? null : filas.where((f) => f.chargeId == '${c['id']}').firstOrNull;
    final importe = double.tryParse('$antes') ?? 0;
    if (fila != null) {
      fila
        ..marcado = true
        ..importe = importe;
    } else if (habia) {
      final nombre = '${o.datos['chargeName'] ?? ''}'.isNotEmpty ? '${o.datos['chargeName']}' : o.servicio;
      filas.add(Concepto(chargeId: '', nombre: nombre, importe: importe, marcado: true));
    }
  }
  return filas;
}

/// Problema en el paso 1 (para mostrar el mensaje).
enum FalloConcepto { importe, nota }

/// Revisa el paso 1 como la web: importe válido y comentario en «Otros» / «Reconexión».
(FalloConcepto, Concepto)? revisarConceptos(List<Concepto> filas) {
  for (final f in filas.where((f) => f.marcado)) {
    final i = f.importe;
    if (i == null || !i.isFinite || i < 0) return (FalloConcepto.importe, f);
  }
  for (final f in filas.where((f) => f.marcado)) {
    if (f.pideNota && f.nota.trim().isEmpty) return (FalloConcepto.nota, f);
  }
  return null;
}

double totalConceptos(List<Concepto> filas) =>
    _redondear(filas.where((f) => f.marcado).fold(0.0, (a, f) => a + (f.importe ?? 0)));

/// Después del paso 1: si no se marcó nada y no es servicio nuevo, se completa sin cobro (sin paso 2).
bool pideFormaPago(Orden o, Catalogos cat, List<Concepto> filas) =>
    filas.any((f) => f.marcado) || esServicioNuevo(o, cat);

// ---------- lo que se guarda (`savePayment`) ----------

/// Datos para guardar el cobro. `forma` null = completar sin cobro.
Map<String, Object?> datosCobro(Orden o, List<Concepto> filas, FormaPago? forma, String userId, String nombre) {
  final ahora = FieldValue.serverTimestamp();
  final d = o.datos;
  final anteriores = d['chargeItems'] is List ? (d['chargeItems'] as List).whereType<Map>().toList() : const <Map>[];
  final items = [
    for (final f in filas.where((f) => f.marcado))
      () {
        final previo = anteriores
            .where(
              (x) =>
                  '${x['chargeId'] ?? ''}' == f.chargeId &&
                  x['name'] == f.nombre &&
                  x['manualAmount'] != null &&
                  x['manualAmount'] != '',
            )
            .firstOrNull;
        return <String, Object?>{
          'chargeId': f.chargeId,
          'name': f.nombre,
          if (f.cantidad != null) 'qty': f.cantidad,
          'amount': _redondear(f.importe ?? 0),
          if (f.pideNota && f.nota.trim().isNotEmpty) 'comment': f.nota.trim(),
          if (previo != null) ...{
            'manualAmount': previo['manualAmount'],
            'manualAmountByName': previo['manualAmountByName'] ?? '',
            'manualAmountAt': previo['manualAmountAt'] ?? '',
          },
        };
      }(),
  ];
  double cuenta(Map<String, Object?> i) {
    final manual = double.tryParse('${i['manualAmount'] ?? ''}') ?? 0;
    return (i['amount'] as double) + manual;
  }

  final datos = <String, Object?>{
    'chargeItems': items,
    'chargeAmount': items.isEmpty ? null : _redondear(items.fold(0.0, (a, i) => a + cuenta(i))),
    'chargeName': items.map((i) => i['name']).join(', '),
    'billable': items.isNotEmpty,
    ...cambiadoPor(userId, nombre),
  };
  final estado = d.containsKey('estado');
  void completar() {
    datos['status'] = 'completada';
    if (estado) datos['estado'] = 'completada';
    datos['completedAt'] = ahora;
    if (!o.iniciada) datos['startedAt'] = ahora;
  }

  if (forma == null) {
    // completar sin cobro
    if (d['paymentMethod'] != null) {
      datos['paymentMethod'] = null;
      datos['paymentUpdatedAt'] = ahora;
    }
    if (d['payAuthStatus'] == 'solicitada') datos['payAuthStatus'] = null;
    completar();
  } else if (forma == FormaPago.transferencia) {
    // la oficina sube el comprobante y la completa en la web
    datos.addAll({'techDoneAt': ahora, 'techDoneById': userId, 'techDoneByName': nombre, 'techPayMethod': forma.valor});
    if (!o.iniciada) datos['startedAt'] = ahora;
  } else {
    datos['paymentMethod'] = forma.valor;
    datos['paymentUpdatedAt'] = ahora;
    if (necesitaAutorizacion(forma)) {
      datos.addAll({
        'payAuthStatus': 'solicitada',
        'payAuthMethod': forma.valor,
        'payAuthRequestedAt': ahora,
        'payAuthRequestedById': userId,
        'payAuthRequestedByName': nombre,
        'payAuthNote': '',
      });
      if (o.estado != 'en_proceso') {
        datos['status'] = 'en_proceso';
        if (estado) datos['estado'] = 'en_proceso';
      }
      if (!o.iniciada) datos['startedAt'] = ahora;
    } else {
      if (d['payAuthStatus'] == 'solicitada') datos['payAuthStatus'] = null;
      completar();
    }
  }
  return datos;
}

/// Comprobante de transferencia que sube el técnico, como `savePayment` de la web: el archivo va aparte en
/// `payProofs/<id de la orden>` y en la orden queda el resumen `paymentProof`. Con ese resumen la oficina completa la orden
/// en la web sin volver a subirlo (y la web le saca después su huella de imagen, `proofBackfill`).
({Map<String, Object?> archivo, Map<String, Object?> resumen}) datosComprobante(
  Orden o,
  String dataUrl, {
  required String userId,
  required String nombre,
}) {
  final base64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
  final datos = {
    'name': 'comprobante-${o.folio.isEmpty ? o.id : o.folio}.jpg',
    'type': 'image/jpeg',
    'size': base64.length * 3 ~/ 4,
    'uploadedAt': FieldValue.serverTimestamp(),
    'byId': userId,
    'byName': nombre,
  };
  return (archivo: {'ticketId': o.id, 'dataUrl': dataUrl, ...datos}, resumen: {'paymentProof': datos});
}
