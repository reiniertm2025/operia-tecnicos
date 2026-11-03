import 'package:cloud_firestore/cloud_firestore.dart';

import 'modems.dart';
import 'orden.dart';
import 'telefono.dart';

/// Crear y editar órdenes igual que la web (addTicketForm y editTicketForm de src/legacy/app.js), con todos los servicios:
/// - servicio nuevo: quién lo consiguió (comisionista y su comisión) y el plan (categoría de módem; TV si es Doble Play);
/// - cancelación definitiva: motivo y módem a recuperar (sale en Recuperar Módem);
/// - cancelación temporal: motivo y si se recoge el módem (cuál) o la fecha de regreso (también en Cancelados › Temporales);
/// - cancelación de TV Doble Play: el módem a recuperar.
/// La orden llega sin técnico: el primero que la acepta se la queda.

enum TipoServicio { sencillo, nuevo, baja, temporal, tvFibra, tvCable }

/// Qué datos extra pide el servicio (isCommissionService, isBajaService, isTempCancelService, cancelKindName de la web).
TipoServicio tipoServicio(Map<String, dynamic>? s) {
  if (s == null) return TipoServicio.sencillo;
  final n = plano(s['name']);
  final temporal = RegExp(r'\btemporal(es)?\b|\bsuspension\b').hasMatch(n);
  final cancela = RegExp('cancel|canel').hasMatch(n);
  // cancelKindName: solo cuenta como TV si dice de cuál (Doble Play o cable)
  final tvDe = cancela && RegExp(r'\btv\b|television').hasMatch(n)
      ? (RegExp('fibra|doble|double|play').hasMatch(n)
            ? TipoServicio.tvFibra
            : (RegExp('cable').hasMatch(n) ? TipoServicio.tvCable : null))
      : null;
  final tv = tvDe != null;
  final baja = (RegExp(r'\bbajas?\b').hasMatch(n) || (cancela && RegExp('definitiv').hasMatch(n))) && !temporal && !tv;
  final comision = s['commission'] is bool ? s['commission'] == true : RegExp('nuev').hasMatch(n);
  if (temporal) return TipoServicio.temporal;
  if (tvDe != null) return tvDe;
  if (baja) return TipoServicio.baja;
  if (comision) return TipoServicio.nuevo;
  return TipoServicio.sencillo;
}

/// Categoría de módem (Sistema › Activos › categorías), como `modemCats` y `catKind` de la web.
class CategoriaModem {
  const CategoriaModem(this.id, this.nombre, {required this.doblePlay});
  final String id;
  final String nombre;
  final bool doblePlay;
  String get tipo => doblePlay ? 'doble_play' : 'internet';
}

List<CategoriaModem> categoriasModem(List<Map<String, dynamic>> categorias) {
  final modem = categorias.where((c) => RegExp('m[oó]dem', caseSensitive: false).hasMatch('${c['name'] ?? ''}')).toList();
  final lista = [...(modem.isNotEmpty ? modem : categorias)]
    ..sort((a, b) {
      final o = (num.tryParse('${a['order'] ?? ''}') ?? 0).compareTo(num.tryParse('${b['order'] ?? ''}') ?? 0);
      return o != 0 ? o : '${a['name'] ?? ''}'.compareTo('${b['name'] ?? ''}');
    });
  return [
    for (final c in lista)
      CategoriaModem(
        '${c['id']}',
        '${c['name'] ?? '-'}',
        doblePlay: RegExp(r'doble|double|play|\bdp\b|\btv\b|television')
            .hasMatch(plano('${c['name'] ?? ''} ${c['description'] ?? ''}')),
      ),
  ];
}

/// Comisionista (Sistema › Comisionistas): quién consiguió un servicio nuevo y qué comisiones tiene marcadas.
class Comisionista {
  const Comisionista(this.id, this.nombre, this.zonas, this.comisionIds);
  final String id;
  final String nombre;
  final List<String> zonas;
  final List<String> comisionIds;

  bool atiende(String? zona) => zona == null || zonas.isEmpty || zonas.contains(zona);
}

/// Motivo de cancelación definitiva (`bajaReasons`); el de `other` pide escribir el motivo.
class MotivoBaja {
  const MotivoBaja(this.id, this.nombre, {this.otro = false});
  final String id;
  final String nombre;
  final bool otro;
}

/// Catálogos que usa el formulario, leídos de la base.
class CatalogosOrden {
  const CatalogosOrden({
    this.servicios = const {},
    this.modems = const [],
    this.comisionistas = const [],
    this.comisiones = const [],
    this.motivos = const [],
    this.precioTv,
  });
  final Map<String, Map<String, dynamic>> servicios;
  final List<CategoriaModem> modems;
  final List<Comisionista> comisionistas;
  final List<Map<String, dynamic>> comisiones;

  /// Motivos en el orden de la web; si ninguno es «Otros», la pantalla agrega uno (id vacío).
  final List<MotivoBaja> motivos;

  /// Cobro «TV Adicional», para avisar cuánto se cobra por cada TV con costo.
  final double? precioTv;

  /// Las comisiones del comisionista (sin las de recuperar módem, que se pagan aparte), como `cmrComs` + `refAutoRate`.
  List<Map<String, dynamic>> comisionesDe(String comisionistaId) {
    final c = comisionistas.where((x) => x.id == comisionistaId).firstOrNull;
    return [
      for (final id in c?.comisionIds ?? const <String>[]) ?comisiones.where((x) => x['id'] == id && !_esDeModem(x)).firstOrNull,
    ];
  }

  /// La que se elige sola: si solo tiene una, o la única del tipo de plan elegido.
  String? comisionSugerida(String comisionistaId, CategoriaModem? plan) {
    final mias = comisionesDe(comisionistaId);
    if (mias.length == 1) return '${mias.first['id']}';
    if (plan == null) return null;
    final delPlan = mias.where((c) => _tipoPlan(c) == plan.tipo).toList();
    return delPlan.length == 1 ? '${delPlan.first['id']}' : null;
  }
}

bool _esDeModem(Map<String, dynamic> c) => RegExp(r'\bbajas?\b|\bcancelad|\brecuper|\bmodem').hasMatch(plano(c['name']));

String _tipoPlan(Map<String, dynamic> c) {
  final n = plano(c['name']);
  return RegExp('doble|dobleplay|double').hasMatch(n) ? 'doble_play' : (RegExp('internet').hasMatch(n) ? 'internet' : '');
}

/// Prefijo del folio: las primeras 4 letras de la localidad, sin acentos y en mayúsculas («Tecolutilla» → «TECO»).
String prefijoFolio(String nombreZona) => plano(nombreZona).toUpperCase().replaceAll(RegExp('[^A-Z]'), '');

String folioNuevo(int numero, String nombreZona) {
  final p = prefijoFolio(nombreZona);
  return '${numero.toString().padLeft(3, '0')}-${p.length > 4 ? p.substring(0, 4) : p}';
}

/// Al cambiar de localidad la web cambia la parte de letras del folio («012-TECO» → «012-COMA»).
String folioParaZona(String folio, String nombreZona) {
  final p = prefijoFolio(nombreZona);
  final m = RegExp(r'^(\d+)-[A-Z]*$').firstMatch(folio) ?? RegExp(r'^[A-Z]+(\d+)$').firstMatch(folio);
  if (p.isEmpty || m == null) return folio;
  return folioNuevo(int.parse(m[1]!), nombreZona);
}

/// Id del documento como `nameId` de la web: el folio tal cual (sin «/» ni espacios dobles).
String idDeFolio(String folio) {
  final x = folio.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll('/', '-');
  return x.isEmpty ? 'Sin nombre' : (x.length > 300 ? x.substring(0, 300) : x);
}

/// Coordenadas como `parseCoords` de la web: «18.1, -93.2», «(18.1; -93.2)» o un enlace de Google Maps.
/// Vacío → (lat: null, lng: null); null si no se entiende o está fuera de rango.
({double? lat, double? lng})? coordenadas(String texto) {
  final v = texto.trim();
  if (v.isEmpty) return (lat: null, lng: null);
  final m =
      RegExp(r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)').firstMatch(v) ??
      RegExp(r'[?&](?:q|query|ll)=(-?\d+(?:\.\d+)?)(?:,|%2C)\s*(-?\d+(?:\.\d+)?)', caseSensitive: false).firstMatch(v) ??
      RegExp(r'^\(?\s*(-?\d+(?:\.\d+)?)\s*[,;\s]\s*(-?\d+(?:\.\d+)?)\s*\)?$').firstMatch(v);
  if (m == null) return null;
  final lat = double.parse(m[1]!), lng = double.parse(m[2]!);
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return (lat: lat, lng: lng);
}

/// Texto de las coordenadas como lo guarda la web (`${lat}, ${lng}`, sin ceros de más).
String textoCoordenadas(double lat, double lng) {
  String n(double x) => x == x.roundToDouble() ? x.toInt().toString() : x.toString();
  return '${n(lat)}, ${n(lng)}';
}

/// Lo que se escribe en el formulario.
class DatosOrden {
  String cliente = '';

  /// Número como se escribe y país de la lada (dos letras, «MX»).
  String telefono = '';
  String pais = 'MX';
  String direccion = '';
  String coordenadas = '';
  String? zonaId;
  String? servicioId;
  String descripcion = '';

  /// Día de servicio (sin hora) y hora «HH:mm» o vacío.
  DateTime dia = DateTime.now();
  String hora = '';

  /// Día y hora con que se abrió para editar: si no se cambian, no se guardan (como la web).
  String diaAlAbrir = '';
  String horaAlAbrir = '';

  // servicio nuevo
  CategoriaModem? plan;
  int tvPagadas = 0;
  int tvGratis = 0;

  /// Quién lo consiguió (vacío = ninguno, sin comisión) y la comisión elegida.
  String comisionistaId = '';
  String? comisionId;

  // cancelación definitiva
  String? motivoId;
  bool motivoOtro = false;
  String motivoTexto = '';
  CategoriaModem? modemBaja;

  // cancelación temporal
  String temporalMotivo = '';
  bool? recogeModem;
  CategoriaModem? modemTemporal;
  String fechaRegreso = '';

  // cancelación de TV Doble Play
  CategoriaModem? modemTv;

  DatosOrden({String? pais}) {
    if (pais != null && pais.isNotEmpty) this.pais = pais;
  }

  /// Para editar: los datos actuales de la orden.
  factory DatosOrden.de(Orden o, {String? pais}) {
    CategoriaModem? cat(Object? id, Object? nombre, Object? tipo) =>
        '${id ?? ''}'.isEmpty ? null : CategoriaModem('$id', '${nombre ?? ''}', doblePlay: tipo == 'doble_play');
    final x = o.datos;
    final tel = separarTelefono(o.telefono);
    final tc = x['tempCancel'] is Map ? Map<String, dynamic>.from(x['tempCancel'] as Map) : null;
    final d = DatosOrden(pais: tel?.iso ?? pais)
      ..cliente = o.cliente
      ..telefono = tel?.local ?? o.telefono
      ..direccion = o.direccion
      ..coordenadas = '${x['coordinates'] ?? ''}'
      ..zonaId = o.zonaId.isEmpty ? null : o.zonaId
      ..servicioId = '${x['serviceType'] ?? ''}'.isEmpty ? null : '${x['serviceType']}'
      ..descripcion = o.descripcion
      ..hora = o.hora
      ..plan = cat(x['planCatId'], x['planCatName'], x['plan'])
      ..tvPagadas = (x['tvPaidQty'] as num?)?.toInt() ?? 0
      ..tvGratis = (x['tvFreeQty'] as num?)?.toInt() ?? 0
      ..comisionistaId = x['commission'] == true ? '${x['referrerId'] ?? ''}' : ''
      ..comisionId = '${x['commissionRateId'] ?? ''}'.isEmpty ? null : '${x['commissionRateId']}'
      ..motivoId = '${x['bajaReasonId'] ?? ''}'.isEmpty ? null : '${x['bajaReasonId']}'
      ..motivoOtro = x['bajaReasonId'] == 'otros'
      ..motivoTexto = '${x['bajaReasonOther'] ?? ''}'
      ..modemBaja = cat(x['bajaEquipCatId'], x['bajaEquipmentName'], x['bajaEquipment'])
      ..modemTv = cat(x['equipCatId'], x['equipCatName'], x['equipKind'] ?? 'doble_play');
    if (tc != null) {
      d
        ..temporalMotivo = '${tc['reason'] ?? ''}'
        ..recogeModem = tc['pickupModem'] == true
        ..modemTemporal = tc['pickupModem'] == true ? cat(tc['modemCatId'], tc['modemName'], tc['modemKind']) : null
        ..fechaRegreso = '${tc['activationDate'] ?? ''}';
    }
    final dia = DateTime.tryParse(o.dia);
    if (dia != null) d.dia = dia;
    d
      ..diaAlAbrir = textoDia(d.dia)
      ..horaAlAbrir = d.hora;
    return d;
  }
}

enum FalloNuevaOrden {
  cliente,
  telefono,
  coordenadas,
  localidad,
  servicio,
  plan,
  comision,
  motivoBaja,
  motivoOtro,
  modem,
  recogeModem,
  fechaRegreso,
  fechaRegresoPasada,
  diaPasado,
  horaPasada,
  completadaFutura,
}

/// Revisa el formulario como la web. Al editar (`antes` != null) se puede dejar el día que ya tenía aunque sea anterior,
/// y una orden vieja sin plan se puede guardar sin elegirlo.
FalloNuevaOrden? revisarOrden(DatosOrden d, DateTime ahora, CatalogosOrden cat, {Orden? antes}) {
  if (d.cliente.trim().isEmpty) return FalloNuevaOrden.cliente;
  if (telefonoInternacional(d.telefono, d.pais) == null) return FalloNuevaOrden.telefono;
  if (coordenadas(d.coordenadas) == null) return FalloNuevaOrden.coordenadas;
  if (d.zonaId == null) return FalloNuevaOrden.localidad;
  if (d.servicioId == null) return FalloNuevaOrden.servicio;
  final hoy = textoDia(ahora);
  switch (tipoServicio(cat.servicios[d.servicioId])) {
    case TipoServicio.nuevo:
      if (d.plan == null && antes == null) return FalloNuevaOrden.plan;
      if (d.comisionistaId.isNotEmpty && cat.comisionesDe(d.comisionistaId).isNotEmpty && d.comisionId == null) {
        return FalloNuevaOrden.comision;
      }
    case TipoServicio.baja:
      if (d.motivoId == null && !d.motivoOtro) return FalloNuevaOrden.motivoBaja;
      if (d.motivoOtro && d.motivoTexto.trim().isEmpty) return FalloNuevaOrden.motivoOtro;
      if (d.modemBaja == null) return FalloNuevaOrden.modem;
    case TipoServicio.temporal:
      if (d.recogeModem == null) return FalloNuevaOrden.recogeModem;
      if (d.recogeModem! && d.modemTemporal == null) return FalloNuevaOrden.modem;
      if (!d.recogeModem! && d.fechaRegreso.isEmpty) return FalloNuevaOrden.fechaRegreso;
      if (!d.recogeModem! && antes == null && d.fechaRegreso.compareTo(hoy) < 0) return FalloNuevaOrden.fechaRegresoPasada;
    case TipoServicio.tvFibra:
      if (d.modemTv == null) return FalloNuevaOrden.modem;
    case TipoServicio.sencillo || TipoServicio.tvCable:
      break;
  }
  final dia = textoDia(d.dia);
  final cambioDia = antes == null || dia != d.diaAlAbrir || d.hora != d.horaAlAbrir;
  if (cambioDia && dia.compareTo(hoy) < 0) return FalloNuevaOrden.diaPasado;
  if (cambioDia && dia == hoy && d.hora.isNotEmpty && d.hora.compareTo(_hhmm(ahora)) < 0) return FalloNuevaOrden.horaPasada;
  if (antes?.estado == 'completada' && dia.compareTo(hoy) > 0) return FalloNuevaOrden.completadaFutura;
  return null;
}

String _hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Map<String, Object?> _quien(String prefijo, String userId, String nombre) => {'${prefijo}Id': userId, '${prefijo}Name': nombre};

Map<String, Object?> _coords(DatosOrden d) {
  final c = coordenadas(d.coordenadas)!;
  return {'coordinates': c.lat == null ? '' : textoCoordenadas(c.lat!, c.lng!), 'latitude': c.lat, 'longitude': c.lng};
}

/// Cancelación temporal como la guarda la web en la orden (`tempCancel`); null si el servicio no es temporal.
Map<String, Object?>? datosTemporal(DatosOrden d, CatalogosOrden cat) {
  if (tipoServicio(cat.servicios[d.servicioId]) != TipoServicio.temporal) return null;
  final m = d.recogeModem == true ? d.modemTemporal : null;
  return {
    'reason': d.temporalMotivo.trim().replaceAll(RegExp(r'\s+'), ' '),
    'pickupModem': d.recogeModem == true,
    'modemAssetId': '',
    'modemCatId': m?.id ?? '',
    'modemName': m?.nombre ?? '',
    'modemKind': m?.tipo ?? '',
    'activationDate': d.recogeModem == true ? '' : d.fechaRegreso,
  };
}

/// Lo que cambia según el servicio (referrerData, readPlan, readBaja, readTco y readTvq de la web).
Map<String, Object?> _datosDelServicio(DatosOrden d, CatalogosOrden cat, Orden? antes) {
  final tipo = tipoServicio(cat.servicios[d.servicioId]);
  final previo = antes?.datos ?? const <String, dynamic>{};
  // quién lo consiguió
  final Map<String, Object?> referido;
  if (tipo == TipoServicio.nuevo && d.comisionistaId.isNotEmpty) {
    final c = cat.comisiones.where((x) => x['id'] == d.comisionId).firstOrNull;
    final quien = cat.comisionistas.where((x) => x.id == d.comisionistaId).firstOrNull;
    // la comisión ya entregada no cambia de importe (cashState de la web)
    final entregada =
        previo['cpCashDelivered'] == true &&
        previo['commission'] == true &&
        previo['cancelled'] != true &&
        '${previo['referrerId'] ?? ''}'.isNotEmpty &&
        antes?.estado == 'completada';
    final mismaYEntregada = previo['commissionRateId'] == d.comisionId && entregada && previo['commissionAmount'] != null;
    referido = {
      'commission': true,
      'referrerId': d.comisionistaId,
      'referrerName': quien?.nombre ?? (previo['referrerId'] == d.comisionistaId ? previo['referrerName'] ?? '' : ''),
      'commissionRateId': c?['id'] ?? '',
      'commissionRateName': c?['name'] ?? '',
      'commissionAmount': c == null ? null : (mismaYEntregada ? previo['commissionAmount'] : num.tryParse('${c['amount']}') ?? 0),
    };
  } else {
    referido = {
      'commission': false,
      'referrerId': '',
      'referrerName': '',
      'commissionRateId': '',
      'commissionRateName': '',
      'commissionAmount': null,
    };
  }
  final plan = d.plan;
  final temporal = datosTemporal(d, cat);
  final m = d.modemBaja;
  return {
    ...referido,
    if (tipo != TipoServicio.nuevo)
      'plan': ''
    else if (plan != null) ...{
      'plan': plan.tipo,
      'planCatId': plan.id,
      'planCatName': plan.nombre,
      'tvPaidQty': plan.doblePlay ? d.tvPagadas.clamp(0, 50) : 0,
      'tvFreeQty': plan.doblePlay ? d.tvGratis.clamp(0, 50) : 0,
    },
    if (tipo == TipoServicio.baja && m != null) ...{
      'bajaReasonId': d.motivoOtro ? 'otros' : d.motivoId,
      'bajaReason': d.motivoOtro
          ? d.motivoTexto.trim().replaceAll(RegExp(r'\s+'), ' ')
          : cat.motivos.where((x) => x.id == d.motivoId).firstOrNull?.nombre ?? '',
      'bajaReasonOther': d.motivoOtro ? d.motivoTexto.trim().replaceAll(RegExp(r'\s+'), ' ') : '',
      'bajaEquipment': m.tipo,
      'bajaEquipmentName': m.nombre,
      'bajaEquipCatId': m.id,
      if (antes == null || '${previo['modemStatus'] ?? ''}'.isEmpty) 'modemStatus': 'pendiente',
      // ya tenía quién lo recupera y cambió el tipo de módem: cambia la comisión
      if ('${previo['modemRecoveryById'] ?? ''}'.isNotEmpty && previo['bajaEquipment'] != m.tipo)
        ...(() {
          final c = comisionModem(cat.comisiones, doblePlay: m.doblePlay);
          return <String, Object?>{
            'modemCommissionId': c?['id'] ?? '',
            'modemCommissionName': c?['name'] ?? '',
            'modemCommissionAmount': num.tryParse('${c?['amount'] ?? ''}'),
          };
        })(),
    },
    if (temporal != null) 'tempCancel': temporal else if (previo['tempCancel'] != null) 'tempCancel': FieldValue.delete(),
    if (tipo == TipoServicio.tvFibra && d.modemTv != null) ...{
      'equipCatId': d.modemTv!.id,
      'equipCatName': d.modemTv!.nombre,
      'equipKind': d.modemTv!.tipo,
    },
  };
}

/// Cliente, teléfono, dirección, ubicación y los datos del servicio (igual al crear y al editar).
Map<String, Object?> _cliente(DatosOrden d, CatalogosOrden cat, Orden? antes) => {
  'clientName': d.cliente.trim(),
  'clientPhone': telefonoInternacional(d.telefono, d.pais),
  'address': d.direccion.trim(),
  ..._coords(d),
  ..._datosDelServicio(d, cat, antes),
};

/// Orden nueva como la guarda la web al crearla. Llega sin técnico: el primero que la acepta se la queda.
Map<String, Object?> datosOrdenNueva(
  DatosOrden d,
  CatalogosOrden cat, {
  required String folio,
  required String userId,
  required String nombre,
  required DateTime ahora,
}) {
  final dia = textoDia(d.dia);
  final hoy = textoDia(ahora);
  final ahoraServidor = FieldValue.serverTimestamp();
  return {
    'folio': folio,
    ..._cliente(d, cat, null),
    // hoy sin hora no guarda día; otro día u hora sí (readTicketWhen)
    if (dia != hoy || d.hora.isNotEmpty) ...{
      'workDate': dia,
      'scheduledDate': dia,
      'scheduledTime': d.hora,
      'scheduledAt': ahoraServidor,
      ..._quien('scheduledBy', userId, nombre),
    },
    'serviceType': d.servicioId,
    'serviceName': '${cat.servicios[d.servicioId]?['name'] ?? d.servicioId}',
    'zoneId': d.zonaId,
    'description': d.descripcion.trim(),
    'status': 'pendiente',
    'assignedTechId': '',
    'assignedTechName': '',
    'techComments': '',
    'priority': 'normal',
    'hasPhoto': false,
    'photoCount': 0,
    'createdAt': ahoraServidor,
    ..._quien('createdBy', userId, nombre),
    'startedAt': null,
    'completedAt': null,
  };
}

/// Cambios al editar, como la web: datos del cliente, servicio con sus datos extra, localidad (con su folio) y día.
/// El técnico no se cambia aquí.
Map<String, Object?> datosOrdenEditada(
  Orden o,
  DatosOrden d,
  CatalogosOrden cat, {
  required String nombreZona,
  required String userId,
  required String nombre,
}) {
  final dia = textoDia(d.dia);
  final completada = o.completadaEn;
  final cambioDia = dia != d.diaAlAbrir || d.hora != d.horaAlAbrir;
  return {
    if (cambioDia) ...{
      'workDate': dia,
      'scheduledDate': dia,
      'scheduledTime': d.hora,
      if (o.datos['pastEntry'] == true) 'pastEntry': false,
      // la completada se mueve a ese día, con su misma hora (como readEditWhen)
      if (o.estado == 'completada')
        'completedAt': Timestamp.fromDate(
          DateTime(d.dia.year, d.dia.month, d.dia.day, completada?.hour ?? 12, completada?.minute ?? 0),
        ),
    },
    ..._cliente(d, cat, o),
    'lastChangedById': userId,
    'lastChangedByName': nombre,
    'lastChangedAt': FieldValue.serverTimestamp(),
    'serviceType': d.servicioId,
    'serviceName': '${cat.servicios[d.servicioId]?['name'] ?? o.datos['serviceName'] ?? d.servicioId}',
    'zoneId': d.zonaId,
    'description': d.descripcion.trim(),
    if (o.folio.isNotEmpty && folioParaZona(o.folio, nombreZona) != o.folio) 'folio': folioParaZona(o.folio, nombreZona),
  };
}

/// El registro de Cancelados › Temporales de la orden (`tempCancels/tk_<id>`), como `tcSyncTicket`.
/// `existe` = ya había uno (no se vuelve a poner quién lo creó).
Map<String, Object?> datosRegistroTemporal(
  String ticketId,
  Map<String, Object?> orden,
  Map<String, Object?> temporal, {
  required bool existe,
  required String userId,
  required String nombre,
}) => {
  'ticketId': ticketId,
  'folio': orden['folio'] ?? '',
  'name': orden['clientName'] ?? '',
  'phone': orden['clientPhone'] ?? '',
  'address': orden['address'] ?? '',
  'zoneId': orden['zoneId'] ?? '',
  'reason': temporal['reason'] ?? '',
  'pickupModem': temporal['pickupModem'] == true,
  'modemAssetId': '',
  'modemCatId': temporal['modemCatId'] ?? '',
  'modemName': temporal['modemName'] ?? '',
  'modemKind': temporal['modemKind'] ?? '',
  'activationDate': temporal['activationDate'] ?? '',
  'voided': false,
  'lastChangedById': userId,
  'lastChangedByName': nombre,
  'lastChangedAt': FieldValue.serverTimestamp(),
  if (!existe) ...{'status': 'activo', 'createdAt': FieldValue.serverTimestamp(), ..._quien('createdBy', userId, nombre)},
};

/// Lo que se guarda en la Papelera de la web (`trash`) al eliminar: la orden completa y quién la eliminó.
/// El nombre es «folio · cliente» (o el id si no tiene), de 200 letras como mucho, como `trashDel`.
Map<String, Object?> datosPapelera(Orden o, String userId, String nombre) {
  final etiqueta = [o.folio, o.cliente].where((x) => x.isNotEmpty).join(' · ');
  final label = etiqueta.isEmpty ? o.id : etiqueta;
  return {
    'col': 'tickets',
    'docId': o.id,
    'data': o.datos,
    'label': label.length > 200 ? label.substring(0, 200) : label,
    'relatedIds': const <String>[],
    'deletedAt': FieldValue.serverTimestamp(),
    ..._quien('deletedBy', userId, nombre),
  };
}
