import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados abiertos con los que la web busca las órdenes (TK_OPEN en src/legacy/app.js).
const estadosAbiertos = [
  'pendiente',
  'en_proceso',
  'en proceso',
  'Pendiente',
  'En proceso',
  'En Proceso',
  'asignada',
  'asignado',
  'aceptada',
  'nueva',
  'abierta',
  'en_camino',
];

/// Campos donde la web guarda el técnico asignado (TECH_ID_FIELDS).
const camposTecnico = ['assignedTechId', 'technicianId', 'techId', 'tecnicoId', 'assignedTo', 'acceptedBy', 'acceptedById'];

/// Otros nombres del estado que acepta la web (STATUS_ALIASES).
const _alias = {
  'pendiente': [
    'pendiente',
    'pending',
    'nueva',
    'nuevo',
    'abierta',
    'abierto',
    'sin_asignar',
    'por_asignar',
    'en_espera',
    'espera',
  ],
  'en_proceso': [
    'en_proceso',
    'enproceso',
    'proceso',
    'en_progreso',
    'progreso',
    'in_progress',
    'inprogress',
    'aceptada',
    'aceptado',
    'accepted',
    'asignada',
    'asignado',
    'en_curso',
    'en_camino',
    'iniciada',
    'iniciado',
    'atendiendo',
    'en_atencion',
  ],
  'completada': [
    'completada',
    'completado',
    'completed',
    'complete',
    'terminada',
    'terminado',
    'finalizada',
    'finalizado',
    'finished',
    'done',
    'cerrada',
    'cerrado',
    'resuelta',
    'resuelto',
    'closed',
    'concluida',
    'concluido',
  ],
};

/// Igual que `normStatus` de la web: pendiente | en_proceso | completada | cancelada.
String normalizarEstado(Map<String, dynamic> datos) {
  if (datos['cancelled'] == true) return 'cancelada';
  final crudo = (datos['status'] ?? datos['estado'] ?? '').toString().trim();
  if (crudo.isEmpty) return 'pendiente';
  final clave = _sinAcentos(crudo.toLowerCase()).replaceAll(RegExp(r'[\s-]+'), '_');
  for (final e in _alias.entries) {
    if (e.value.contains(clave)) return e.key;
  }
  return clave;
}

/// Igual que `formatFolio` de la web: «AB12» se muestra «012-AB».
String folioVisible(Object? folio) {
  final texto = (folio ?? '').toString();
  final m = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(texto);
  return m == null ? texto : '${m[2]!.padLeft(3, '0')}-${m[1]}';
}

/// Día como texto AAAA-MM-DD (hora del celular).
String textoDia(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Una orden de trabajo (`tickets/{id}`), solo lo que muestra la app.
class Orden {
  Orden(this.id, this.datos) : estado = normalizarEstado(datos);

  final String id;
  final Map<String, dynamic> datos;
  final String estado;

  String _texto(String campo) => (datos[campo] ?? '').toString().trim();

  String get folio => folioVisible(datos['folio']);
  String get cliente => _texto('clientName');
  String get telefono => _texto('clientPhone');
  String get direccion => _texto('address');
  String get servicio => _texto('serviceName').isNotEmpty ? _texto('serviceName') : _texto('serviceType');
  String get descripcion => _texto('description');
  String get notaOficina => _texto('staffNote');
  String get comentariosTecnico => _texto('techComments');
  String get hora => _texto('scheduledTime');
  String get zonaId => _texto('zoneId');
  String get tecnicoNombre => _texto('assignedTechName');

  /// Cuándo se completó (`completedAt`), si ya se completó.
  DateTime? get completadaEn {
    final v = datos['completedAt'];
    return v is Timestamp ? v.toDate() : null;
  }

  /// Cuándo se registró (`createdAt`).
  DateTime? get creadaEn {
    final v = datos['createdAt'];
    return v is Timestamp ? v.toDate() : null;
  }

  /// Algún técnico asignado (TECH_ID_FIELDS de la web).
  bool get tieneTecnico => camposTecnico.any((c) => _texto(c).isNotEmpty);
  bool esDe(String userId) => camposTecnico.any((c) => _texto(c) == userId);
  bool get iniciada => datos['startedAt'] != null;

  /// El técnico avisó desde la app que terminó; falta que la oficina registre el cobro.
  bool get avisoTerminada => datos['techDoneAt'] != null;

  /// Reparación o baja: la web las completa sin cobro (`isNoChargeTicket`).
  bool get sinCobro => esReparacion || esBaja;

  /// `isRepairTicket` de la web.
  bool get esReparacion => _texto('serviceType') == 'falla' || RegExp('falla|reparacion').hasMatch(plano(servicio));

  /// `isBajaTicket` de la web.
  bool get esBaja {
    final nombre = plano(servicio);
    final equipoBaja = datos['bajaEquipment'];
    return (equipoBaja != null && equipoBaja != false && equipoBaja != '') ||
        RegExp(r'\bbajas?\b').hasMatch(nombre) ||
        (nombre.contains('cancel') && nombre.contains('definitiv'));
  }

  /// Con cobro esperando autorización de la oficina: la app no la completa.
  bool get esperaAutorizacion => datos['payAuthStatus'] == 'solicitada';

  /// Día de servicio como en la web (`ticketWorkDay`): workDate, o el día en que se registró.
  String get dia {
    final w = _diaDe(datos['workDate']);
    return w.isNotEmpty ? w : _diaDe(datos['createdAt']);
  }

  /// Coordenadas para el mapa: latitude/longitude, o el texto «lat, lng» de `coordinates`.
  ({double lat, double lng})? get ubicacion {
    final lat = _numero(datos['latitude']), lng = _numero(datos['longitude']);
    if (lat != null && lng != null) return (lat: lat, lng: lng);
    final m = RegExp(r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)').firstMatch(_texto('coordinates'));
    if (m == null) return null;
    return (lat: double.parse(m[1]!), lng: double.parse(m[2]!));
  }

  static double? _numero(Object? v) => v is num ? v.toDouble() : double.tryParse((v ?? '').toString().trim());

  static String _diaDe(Object? v) {
    if (v is Timestamp) return textoDia(v.toDate());
    if (v is DateTime) return textoDia(v);
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch((v ?? '').toString().trim());
    return m == null ? '' : m[0]!;
  }
}

/// Órdenes abiertas separadas por día: atrasadas, de hoy y de los próximos días.
class OrdenesDelTecnico {
  OrdenesDelTecnico(Iterable<Orden> todas, String hoy) {
    final abiertas = todas.where((o) => o.estado == 'pendiente' || o.estado == 'en_proceso').toList()
      ..sort((a, b) {
        final porDia = a.dia.compareTo(b.dia);
        if (porDia != 0) return porDia;
        // las que ya se están atendiendo, primero; luego por hora
        if (a.estado != b.estado) return a.estado == 'en_proceso' ? -1 : 1;
        return a.hora.compareTo(b.hora);
      });
    for (final o in abiertas) {
      if (o.dia.isNotEmpty && o.dia.compareTo(hoy) < 0) {
        atrasadas.add(o);
      } else if (o.dia.isEmpty || o.dia == hoy) {
        deHoy.add(o);
      } else {
        proximas.add(o);
      }
    }
  }

  final atrasadas = <Orden>[];
  final deHoy = <Orden>[];
  final proximas = <Orden>[];

  bool get vacio => atrasadas.isEmpty && deHoy.isEmpty && proximas.isEmpty;
}

/// Búsqueda como la de la web: folio, cliente, teléfono, dirección, servicio, técnico, quién la cambió, localidad y
/// descripción. Con varias palabras tienen que estar todas; el teléfono se encuentra aunque tenga espacios o guiones.
bool coincideBusqueda(Orden o, String buscar, {String zona = ''}) {
  final q = plano(buscar.trim());
  if (q.isEmpty) return true;
  final texto = plano(
    [
      o.folio,
      o.datos['folio'],
      o.cliente,
      o.telefono,
      o.direccion,
      o.servicio,
      o.tecnicoNombre,
      o.datos['lastChangedByName'],
      zona,
      o.descripcion,
    ].join(' '),
  );
  if (q.split(RegExp(r'\s+')).every(texto.contains)) return true;
  final digitos = q.replaceAll(RegExp(r'\D'), '');
  return digitos.length >= 3 && o.telefono.replaceAll(RegExp(r'\D'), '').contains(digitos);
}

/// Como `sortList` de la web: por `order` (los que no tienen, al final) y luego el más viejo primero.
int compararOrdenWeb(Map<String, dynamic> a, Map<String, dynamic> b) {
  double orden(Map<String, dynamic> d) => num.tryParse('${d['order'] ?? ''}')?.toDouble() ?? 1e9;
  double creado(Map<String, dynamic> d) => switch (d['createdAt']) {
    final Timestamp t => t.millisecondsSinceEpoch.toDouble(),
    final num n => n.toDouble(),
    _ => double.infinity,
  };
  final c = orden(a).compareTo(orden(b));
  return c != 0 ? c : creado(a).compareTo(creado(b));
}

/// Como `plain` de la web: minúsculas y sin acentos.
String plano(Object? s) => _sinAcentos('${s ?? ''}'.toLowerCase());

String _sinAcentos(String s) {
  const de = 'áéíóúüàèìòùñ', a = 'aeiouuaeioun';
  final b = StringBuffer();
  for (final c in s.split('')) {
    final i = de.indexOf(c);
    b.write(i < 0 ? c : a[i]);
  }
  return b.toString();
}
