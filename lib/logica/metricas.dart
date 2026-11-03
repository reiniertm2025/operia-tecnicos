import 'cobro.dart';
import 'orden.dart';

/// Números del Dashboard del administrador, con las mismas cuentas que el Dashboard de la web
/// (src/legacy/app.js: anStats, anPaid, anPost, anHours, anBuckets, renderAnZoneTable, anTechChart;
/// src/features/charges/logic.ts: chargeAmountOf).
///
/// Un periodo cuenta las órdenes CREADAS esos días (createdAt); los técnicos, las COMPLETADAS esos días (completedAt).

/// Importe cobrado de una orden (`chargeAmountOf`): la suma de chargeItems (con su importe a mano); si no hay,
/// chargeAmount más chargeManual; si tampoco, el importe del cobro de su servicio; o null.
double? importeCobrado(Orden o, Catalogos cat) {
  final d = o.datos;
  double? numero(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.trim());
  double r2(double v) => (v * 100).round() / 100;
  final items = d['chargeItems'];
  if (items is List && items.isNotEmpty) {
    return r2(
      items.whereType<Map>().fold(0.0, (a, i) => a + r2((numero(i['amount']) ?? 0) + (numero(i['manualAmount']) ?? 0))),
    );
  }
  final manual = numero(d['chargeManual']);
  final extra = manual != null && manual.isFinite ? manual : 0.0;
  if (d['chargeAmount'] != null && d['chargeAmount'] != '') return r2((numero(d['chargeAmount']) ?? 0) + extra);
  final cobro = cat.cobros.where((c) => c['serviceId'] == d['serviceType']).firstOrNull;
  if (cobro != null) return r2((numero(cobro['amount']) ?? 0) + extra);
  return manual != null && manual.isFinite ? extra : null;
}

/// Cobrada (`anPaid`): lleva cobro y se pagó en efectivo o transferencia.
bool cobrada(Orden o) => !o.sinCobro && const ['efectivo', 'transferencia'].contains(o.datos['paymentMethod']);

/// Pospuesta alguna vez (`anPost`).
bool pospuesta(Orden o) =>
    (num.tryParse('${o.datos['postponeCount'] ?? ''}') ?? 0) > 0 ||
    '${o.datos['postponeReason'] ?? ''}'.trim().isNotEmpty;

/// Horas de atención (`anHours`): de que se creó a que se completó.
double? horasDeAtencion(Orden o) {
  final a = o.creadaEn, b = o.completadaEn;
  return a != null && b != null && b.isAfter(a) ? b.difference(a).inSeconds / 3600 : null;
}

/// Espera que la oficina autorice el cobro (`needsPayAuth`): lo pidió el técnico y no está completada, o se completó
/// como «pendiente de pago» o «sin costo» y nadie lo ha autorizado.
bool esperaAutorizar(Orden o) {
  if (o.sinCobro) return false;
  final d = o.datos;
  return (d['payAuthStatus'] == 'solicitada' && o.estado != 'completada') ||
      (o.estado == 'completada' &&
          const ['pendiente', 'sin_costo'].contains(d['paymentMethod']) &&
          d['payAuthStatus'] != 'autorizada');
}

bool _entre(DateTime? d, DateTime desde, DateTime hastaExclusivo) =>
    d != null && !d.isBefore(desde) && d.isBefore(hastaExclusivo);

double? _promedio(List<double> v) => v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;

/// Las tarjetas del Dashboard para un periodo.
class Resumen {
  Resumen(Iterable<Orden> base, DateTime desde, DateTime hastaExclusivo, Catalogos cat)
    : lista = [
        for (final o in base)
          if (_entre(o.creadaEn, desde, hastaExclusivo)) o,
      ] {
    final horas = <double>[];
    for (final o in lista) {
      switch (o.estado) {
        case 'pendiente':
          pendientes++;
        case 'en_proceso':
          enProceso++;
        case 'completada':
          completadas++;
        case 'cancelada':
          canceladas++;
      }
      if (esServicioNuevo(o, cat)) nuevos++;
      if (pospuesta(o)) pospuestas++;
      if (o.estado != 'completada') continue;
      final h = horasDeAtencion(o);
      if (h != null) horas.add(h);
      if (o.sinCobro) continue;
      final importe = importeCobrado(o, cat) ?? 0;
      if (cobrada(o)) {
        ingresos += importe;
        cobros++;
      } else if (o.datos['paymentMethod'] == 'pendiente') {
        porCobrar += importe;
      }
    }
    horasPromedio = _promedio(horas);
    medidas = horas.length;
    ingresos = (ingresos * 100).round() / 100;
    porCobrar = (porCobrar * 100).round() / 100;
  }

  /// Las órdenes creadas en el periodo.
  final List<Orden> lista;
  int pendientes = 0,
      enProceso = 0,
      completadas = 0,
      canceladas = 0,
      nuevos = 0,
      pospuestas = 0,
      cobros = 0,
      medidas = 0;
  double ingresos = 0, porCobrar = 0;
  double? horasPromedio;

  int get total => lista.length;
  int get abiertas => pendientes + enProceso;

  /// Porcentaje de cumplimiento: completadas entre recibidas.
  double get cumplimiento => total == 0 ? 0 : completadas / total * 100;
}

/// Cambio en porcentaje contra el periodo anterior: null sin dato de antes, infinito si antes era 0 (es nuevo).
double? cambio(num actual, num? antes) {
  if (antes == null) return null;
  if (antes == 0) return actual == 0 ? 0 : double.infinity;
  return (actual - antes) / antes * 100;
}

/// El periodo anterior del mismo largo, justo antes de `desde` (como la web).
({DateTime desde, DateTime hastaExclusivo}) periodoAnterior(DateTime desde, DateTime hastaExclusivo) =>
    (desde: desde.subtract(hastaExclusivo.difference(desde)), hastaExclusivo: desde);

/// Un tramo de la gráfica: día, semana (desde el lunes) o mes, según lo largo del periodo (`anBuckets`).
class Tramo {
  Tramo(this.desde, this.hastaExclusivo);
  final DateTime desde;
  final DateTime hastaExclusivo;
  int recibidas = 0;
  int completadas = 0;
}

enum UnidadTramo { dia, semana, mes }

UnidadTramo unidadDe(DateTime desde, DateTime hastaExclusivo) {
  final dias = hastaExclusivo.difference(desde).inHours / 24;
  return dias <= 62 ? UnidadTramo.dia : (dias <= 400 ? UnidadTramo.semana : UnidadTramo.mes);
}

/// Recibidas (por createdAt) y completadas (por completedAt) en cada tramo del periodo.
List<Tramo> tramos(Iterable<Orden> base, DateTime desde, DateTime hastaExclusivo) {
  final unidad = unidadDe(desde, hastaExclusivo);
  var d = DateTime(desde.year, desde.month, desde.day);
  if (unidad == UnidadTramo.semana) d = d.subtract(Duration(days: d.weekday - 1));
  if (unidad == UnidadTramo.mes) d = DateTime(d.year, d.month);
  final lista = <Tramo>[];
  while (d.isBefore(hastaExclusivo)) {
    final fin = switch (unidad) {
      UnidadTramo.dia => DateTime(d.year, d.month, d.day + 1),
      UnidadTramo.semana => DateTime(d.year, d.month, d.day + 7),
      UnidadTramo.mes => DateTime(d.year, d.month + 1),
    };
    lista.add(Tramo(d, fin));
    d = fin;
  }
  Tramo? de(DateTime? f) => f == null ? null : lista.where((t) => _entre(f, t.desde, t.hastaExclusivo)).firstOrNull;
  for (final o in base) {
    if (_entre(o.creadaEn, desde, hastaExclusivo)) de(o.creadaEn)?.recibidas++;
    if (o.estado == 'completada' && _entre(o.completadaEn, desde, hastaExclusivo)) de(o.completadaEn)?.completadas++;
  }
  return lista;
}

/// Una fila de «Por localidad» (`renderAnZoneTable`).
class FilaLocalidad {
  FilaLocalidad(this.zonaId);
  final String zonaId;
  int recibidas = 0, completadas = 0, pospuestas = 0;
  double ingresos = 0;
  final _horas = <double>[];
  double? get horasPromedio => _promedio(_horas);
}

List<FilaLocalidad> porLocalidad(Resumen r, Catalogos cat) {
  final filas = <String, FilaLocalidad>{};
  for (final o in r.lista) {
    final f = filas.putIfAbsent(o.zonaId, () => FilaLocalidad(o.zonaId));
    f.recibidas++;
    if (pospuesta(o)) f.pospuestas++;
    if (o.estado != 'completada') continue;
    f.completadas++;
    final h = horasDeAtencion(o);
    if (h != null) f._horas.add(h);
    if (cobrada(o)) f.ingresos += importeCobrado(o, cat) ?? 0;
  }
  return filas.values.toList()..sort((a, b) => b.recibidas.compareTo(a.recibidas));
}

/// Una fila de «Por técnico» (`anTechChart`): las que completó en el periodo y su tiempo promedio.
class FilaTecnico {
  FilaTecnico(this.id, this.nombre);
  final String id;
  final String nombre;
  int completadas = 0;
  final _horas = <double>[];
  double? get horasPromedio => _promedio(_horas);
}

/// Campos donde la web guarda el correo del técnico (TECH_EMAIL_FIELDS).
const _camposCorreo = ['assignedTechEmail', 'technicianEmail', 'techEmail', 'tecnicoEmail', 'acceptedByEmail'];

/// El técnico que muestra la web (`shownTech`): el usuario de algún campo de técnico (por id o por correo); si no,
/// `assignedTechId`/`assignedTechName`; y si no tiene nombre, quien la cambió en la web (`lastChangedByName`).
({String id, String nombre}) tecnicoMostrado(Orden o, Map<String, String> nombres, Map<String, String> idPorCorreo) {
  final d = o.datos;
  String texto(String c) => '${d[c] ?? ''}'.trim();
  ({String id, String nombre})? tk;
  for (final c in camposTecnico) {
    if (nombres.containsKey(texto(c))) {
      tk = (id: texto(c), nombre: nombres[texto(c)]!);
      break;
    }
  }
  if (tk == null) {
    for (final c in _camposCorreo) {
      final id = idPorCorreo[texto(c).toLowerCase()];
      if (texto(c).isNotEmpty && id != null) {
        tk = (id: id, nombre: nombres[id] ?? '');
        break;
      }
    }
  }
  tk ??= (id: texto('assignedTechId'), nombre: texto('assignedTechName'));
  if (tk.nombre.isNotEmpty) return tk;
  final web = texto('lastChangedByName');
  if (web.isNotEmpty) {
    return (id: 'web:${texto('lastChangedById').isNotEmpty ? texto('lastChangedById') : web}', nombre: web);
  }
  return (id: '', nombre: '');
}

/// `nombres`: id del usuario → nombre (de `users`); `idPorCorreo`: correo en minúsculas → id.
List<FilaTecnico> porTecnico(
  Iterable<Orden> base,
  DateTime desde,
  DateTime hastaExclusivo,
  Map<String, String> nombres, {
  Map<String, String> idPorCorreo = const {},
}) {
  final filas = <String, FilaTecnico>{};
  for (final o in base) {
    if (o.estado != 'completada' || !_entre(o.completadaEn, desde, hastaExclusivo)) continue;
    final tk = tecnicoMostrado(o, nombres, idPorCorreo);
    final clave = tk.id.isNotEmpty ? tk.id : tk.nombre;
    if (clave.isEmpty) continue;
    final f = filas.putIfAbsent(clave, () => FilaTecnico(clave, tk.nombre));
    f.completadas++;
    final h = horasDeAtencion(o);
    if (h != null) f._horas.add(h);
  }
  return filas.values.toList()..sort((a, b) => b.completadas.compareTo(a.completadas));
}
