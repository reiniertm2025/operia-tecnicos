import 'package:cloud_firestore/cloud_firestore.dart';

import 'orden.dart';

/// Recuperar Módem › Definitivos y Pago de comisiones, igual que la web (src/legacy/app.js: modemState, assignModem,
/// toggleRecovered, modemCommission, mbAmount, commissionPayRows, modemCommissionRows).
/// Un cancelado definitivo guarda el módem a recuperar (`bajaEquipment`: internet | doble_play) y `modemStatus`:
/// pendiente (sin asignar) → asignado (alguien va por él: `modemRecoveryById/Name`) → recuperado (`modemRecoveredAt`).
/// Al recuperarlo se gana la comisión de Sistema › Comisiones «Recuperar Modem Internet» o «… Doble Play».

enum EstadoModem { sinAsignar, asignado, recuperado }

EstadoModem estadoModem(Orden o) => o.datos['modemStatus'] == 'recuperado'
    ? EstadoModem.recuperado
    : '${o.datos['modemRecoveryById'] ?? ''}'.isNotEmpty
    ? EstadoModem.asignado
    : EstadoModem.sinAsignar;

/// Cancelado definitivo con módem (lo que lista Recuperar Módem).
bool esBajaConModem(Orden o) => '${o.datos['bajaEquipment'] ?? ''}'.isNotEmpty;

bool esDoblePlay(Orden o) => o.datos['bajaEquipment'] == 'doble_play';

String recuperaId(Orden o) => '${o.datos['modemRecoveryById'] ?? ''}';
String recuperaNombre(Orden o) => '${o.datos['modemRecoveryByName'] ?? ''}';

/// Motivo de la baja como lo escribió la oficina.
String motivoBaja(Orden o) {
  final otro = '${o.datos['bajaReasonOther'] ?? ''}';
  return otro.isNotEmpty ? otro : '${o.datos['bajaReason'] ?? ''}';
}

/// La comisión de Sistema › Comisiones para ese módem, como `modemCommission` de la web.
Map<String, dynamic>? comisionModem(List<Map<String, dynamic>> comisiones, {required bool doblePlay}) {
  final quiere = doblePlay ? RegExp('doble|double') : RegExp('internet');
  bool sirve(Map<String, dynamic> c) {
    final n = plano(c['name']);
    return (RegExp(r'\bbajas?\b').hasMatch(n) ||
            RegExp(r'\bcancelad').hasMatch(n) ||
            RegExp(r'\brecuper').hasMatch(n)) &&
        quiere.hasMatch(n);
  }

  return comisiones.where((c) => sirve(c) && plano(c['name']).contains('modem')).firstOrNull ??
      comisiones.where(sirve).firstOrNull;
}

double? _importe(Object? v) => v == null || v == '' ? null : num.tryParse('$v')?.toDouble();

/// Cuánto se gana por recuperarlo: lo guardado en la orden o, si no, lo del catálogo (`mbAmount`).
double? comisionDeModem(Orden o, List<Map<String, dynamic>> comisiones) =>
    _importe(o.datos['modemCommissionAmount']) ??
    _importe(comisionModem(comisiones, doblePlay: esDoblePlay(o))?['amount']);

Map<String, Object?> _cambiadoPor(String userId, String nombre) => {
  'lastChangedById': userId,
  'lastChangedByName': nombre,
  'lastChangedAt': FieldValue.serverTimestamp(),
};

/// Asignar quién lo recupera (uid vacío = quitar la asignación), como `assignModem`.
Map<String, Object?> datosAsignarModem(
  Orden o,
  List<Map<String, dynamic>> comisiones, {
  required String uid,
  required String uNombre,
  required String userId,
  required String nombre,
}) {
  if (uid.isEmpty) {
    return {
      'modemRecoveryById': '',
      'modemRecoveryByName': '',
      'modemStatus': 'pendiente',
      'modemAssignedAt': null,
      'modemCommissionId': '',
      'modemCommissionName': '',
      'modemCommissionAmount': null,
      ..._cambiadoPor(userId, nombre),
    };
  }
  final c = comisionModem(comisiones, doblePlay: esDoblePlay(o));
  return {
    'modemRecoveryById': uid,
    'modemRecoveryByName': uNombre,
    'modemStatus': 'asignado',
    'modemAssignedAt': FieldValue.serverTimestamp(),
    'modemAssignedById': userId,
    'modemAssignedByName': nombre,
    'modemCommissionId': c?['id'] ?? '',
    'modemCommissionName': c?['name'] ?? '',
    'modemCommissionAmount': _importe(c?['amount']),
    ..._cambiadoPor(userId, nombre),
  };
}

/// Marcarlo recuperado (como `toggleRecovered`): guarda quién y cuándo, y la comisión del catálogo.
Map<String, Object?> datosModemRecuperado(
  Orden o,
  List<Map<String, dynamic>> comisiones,
  String userId,
  String nombre,
) {
  final c = comisionModem(comisiones, doblePlay: esDoblePlay(o));
  return {
    'modemStatus': 'recuperado',
    'modemRecoveredAt': FieldValue.serverTimestamp(),
    'modemRecoveredById': userId,
    'modemRecoveredByName': nombre,
    'modemCommissionId': c?['id'] ?? o.datos['modemCommissionId'] ?? '',
    'modemCommissionName': c?['name'] ?? o.datos['modemCommissionName'] ?? '',
    'modemCommissionAmount': _importe(c?['amount']) ?? _importe(o.datos['modemCommissionAmount']),
    ..._cambiadoPor(userId, nombre),
  };
}

// ---------- Pago de comisiones ----------
// Como Reportes › Pago de comisiones de la web (commissionPayRows, modemCommissionRows, iiCpTickets, whoName):
// las comisiones las cobran los COMISIONISTAS (Sistema › Comisionistas), no los usuarios de la app. Las órdenes viejas
// pueden traer un usuario: se juntan con el comisionista que se llama igual (whoCmr/whoKey de la web).

enum TipoComision { instalacion, modem, modemIsp }

class Comision {
  const Comision(
    this.orden,
    this.tipo,
    this.fecha,
    this.importe, {
    required this.entregada,
    required this.clave,
    required this.quien,
  });
  final Orden orden;
  final TipoComision tipo;
  final DateTime? fecha;

  /// null = la oficina todavía no le puso importe.
  final double? importe;

  /// La oficina ya se la entregó (`cpCashDelivered`).
  final bool entregada;

  /// Quién la cobra: `c:` y el id del comisionista, o `n:` y el nombre si no hay comisionista; y su nombre.
  final String clave;
  final String quien;
}

DateTime? _fecha(Object? v) => switch (v) {
  final Timestamp t => t.toDate(),
  final DateTime d => d,
  final num n => DateTime.fromMillisecondsSinceEpoch(n.toInt()),
  final String s when RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) => DateTime.parse('${s}T12:00:00'),
  _ => null,
};

/// Un registro de Importados ISP (`ispCancels`) recuperado, con la forma de una orden (como `iiCpTickets`).
Orden ordenDeIsp(String id, Map<String, dynamic> r) => Orden('isp:$id', {
  'clientName': r['name'] ?? '',
  'zoneId': r['zoneId'] ?? '',
  'bajaEquipment': r['kind'] == 'doble_play' ? 'doble_play' : 'internet',
  'modemRecoveryById': r['recoveredById'] ?? '',
  'modemRecoveryByName': r['recoveredByName'] ?? '',
  'modemCommissionAmount': r['commissionAmount'],
  'modemRecoveredAt': r['recoveredDay'] ?? r['recoveredAt'],
  'cpCashDelivered': r['cpCashDelivered'],
});

/// El nombre para comparar personas (`personKey` de la web): sin acentos, minúsculas y un solo espacio.
String clavePersona(Object? nombre) => plano(nombre).trim().replaceAll(RegExp(r's+'), ' ');

/// Quién cobra (`whoKey`/`whoName` de la web): el comisionista con ese id; si es un id viejo (de un usuario), el
/// comisionista que se llama igual; si no hay, la persona por su nombre.
({String clave, String nombre}) quienCobra(
  String id,
  Object? guardado,
  Map<String, String> comisionistas,
  Map<String, String> usuarios,
) {
  if (comisionistas[id] case final n?) return (clave: 'c:$id', nombre: n);
  final g = '${guardado ?? ''}'.trim();
  final nombre = g.isNotEmpty ? g : (usuarios[id] ?? '');
  final k = clavePersona(nombre);
  if (k.isEmpty) return (clave: '', nombre: '');
  for (final c in comisionistas.entries) {
    if (clavePersona(c.value) == k) return (clave: 'c:${c.key}', nombre: c.value);
  }
  return (clave: 'n:$k', nombre: nombre);
}

/// Las comisiones del periodo. `comisionistas` y `usuarios`: id → nombre.
List<Comision> pagoDeComisiones({
  required Iterable<Orden> ordenes,
  required Iterable<Orden> isp,
  required List<Map<String, dynamic>> comisiones,
  required Map<String, String> comisionistas,
  Map<String, String> usuarios = const {},
  required DateTime desde,
  required DateTime hastaExclusivo,
}) {
  bool enRango(DateTime? f) => f != null && !f.isBefore(desde) && f.isBefore(hastaExclusivo);
  ({String clave, String nombre}) quien(String id, Object? guardado) => quienCobra(id, guardado, comisionistas, usuarios);

  Comision modem(Orden o, TipoComision tipo, DateTime f) => Comision(
    o,
    tipo,
    f,
    comisionDeModem(o, comisiones),
    entregada: o.datos['cpCashDelivered'] == true,
    clave: quien(recuperaId(o), o.datos['modemRecoveryByName']).clave,
    quien: quien(recuperaId(o), o.datos['modemRecoveryByName']).nombre,
  );
  final vistas = <String>{};
  final lista = <Comision>[
    for (final o in ordenes)
      if (vistas.add(o.id)) ...[
        if (o.datos['commission'] == true &&
            o.datos['cancelled'] != true &&
            '${o.datos['referrerId'] ?? ''}'.isNotEmpty &&
            o.estado == 'completada')
          if (_fecha(o.datos['completedAt']) ?? _fecha(o.datos['paymentUpdatedAt']) ?? _fecha(o.datos['createdAt'])
              case final DateTime f when enRango(f))
            Comision(
              o,
              TipoComision.instalacion,
              f,
              _importe(o.datos['commissionAmount']),
              entregada: o.datos['cpCashDelivered'] == true,
              clave: quien('${o.datos['referrerId']}', o.datos['referrerName']).clave,
              quien: quien('${o.datos['referrerId']}', o.datos['referrerName']).nombre,
            ),
        if (o.esBaja && estadoModem(o) == EstadoModem.recuperado && recuperaId(o).isNotEmpty)
          if (_fecha(o.datos['modemRecoveredAt']) ?? _fecha(o.datos['modemAssignedAt']) ?? _fecha(o.datos['createdAt'])
              case final DateTime f when enRango(f))
            modem(o, TipoComision.modem, f),
      ],
    for (final o in isp)
      if (recuperaId(o).isNotEmpty)
        if (_fecha(o.datos['modemRecoveredAt']) case final DateTime f when enRango(f))
          modem(o, TipoComision.modemIsp, f),
  ];
  return lista..sort((a, b) => (b.fecha ?? DateTime(0)).compareTo(a.fecha ?? DateTime(0)));
}

double totalComisiones(Iterable<Comision> l, {bool? entregada}) =>
    l.where((c) => entregada == null || c.entregada == entregada).fold(0, (s, c) => s + (c.importe ?? 0));

/// Las comisiones juntas por quien las cobra (como hace Pago de comisiones de la web), la de más dinero primero.
List<({String quien, List<Comision> filas})> porComisionista(List<Comision> lista) {
  final grupos = <String, List<Comision>>{};
  for (final c in lista) {
    grupos.putIfAbsent(c.clave, () => []).add(c);
  }
  return [for (final g in grupos.values) (quien: g.first.quien, filas: g)]
    ..sort((a, b) => totalComisiones(b.filas).compareTo(totalComisiones(a.filas)));
}
