import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../logica/acciones.dart';
import '../logica/cobro.dart';
import '../logica/fechas.dart';
import '../logica/fotos.dart';
import '../logica/inconclusas.dart';
import '../logica/materiales.dart';
import '../logica/metricas.dart';
import '../logica/modems.dart';
import '../logica/nueva_orden.dart';
import '../logica/orden.dart';
import '../logica/prospectos.dart';
import '../logica/tablero.dart';
import 'sesion.dart';

/// Por qué no se pudo cambiar una orden. La pantalla lo convierte en un mensaje en el idioma del técnico.
enum FalloOrden { yaTomada, ipOcupada, sinInternet, sinPermiso, otro }

class ErrorDeOrden implements Exception {
  const ErrorDeOrden(this.fallo, [this.detalle = '']);
  final FalloOrden fallo;
  final String detalle;

  @override
  String toString() => detalle.isEmpty ? fallo.name : '${fallo.name} ($detalle)';
}

/// La orden que se acaba de crear: su id en `tickets` y su folio.
typedef OrdenCreada = ({String id, String folio});

/// Un usuario al que se le puede asignar una orden.
class UsuarioAsignable {
  const UsuarioAsignable(this.id, this.nombre, this.zonas, {this.email = ''});
  final String id;
  final String nombre;
  final String email;
  final List<String> zonas;

  /// Como la web: sin localidades = sirve en todas.
  bool atiende(String? zona) => zona == null || zonas.isEmpty || zonas.contains(zona);
}

/// Una página del historial y desde dónde seguir.
class PaginaHistorial {
  const PaginaHistorial(this.ordenes, this.ultima, {required this.hayMas});
  final List<Orden> ordenes;
  final DocumentSnapshot<Map<String, dynamic>>? ultima;
  final bool hayMas;
}

/// Órdenes en Firebase. Solo se escucha lo necesario (cuidar el plan gratuito):
/// el administrador, las abiertas de todos; el técnico, las suyas y las de sus localidades; y las culminadas de hoy.
class ServicioOrdenes {
  ServicioOrdenes({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  Map<String, String>? _zonas;
  List<UsuarioAsignable>? _usuarios;
  List<Map<String, dynamic>>? _comisiones;
  CatalogosOrden? _catalogosOrden;
  final _comisionesPeriodo = <String, ({List<Orden> ordenes, List<Orden> isp})>{};
  final _finanzas =
      <
        String,
        ({
          List<Map<String, dynamic>> ingresos,
          List<Map<String, dynamic>> gastos,
          List<Map<String, dynamic>> partidas,
          List<Orden> cobradas,
        })
      >{};
  List<Map<String, dynamic>>? _ingresos, _partidas;
  Catalogos? _catalogos;
  CatalogoMateriales? _materiales;
  final _periodos = <String, List<Orden>>{};
  Future<List<Orden>>? _sinAutorizar;

  CollectionReference<Map<String, dynamic>> get _tickets => _db.collection('tickets');

  static List<Orden> _ordenes(QuerySnapshot<Map<String, dynamic>> s) => [for (final d in s.docs) Orden(d.id, d.data())];

  /// Órdenes abiertas (pendientes y en proceso) que le tocan, en vivo.
  Stream<List<Orden>> abiertas(Tecnico t) {
    final abiertas = _tickets.where('status', whereIn: estadosAbiertos);
    if (t.esAdmin) return abiertas.snapshots().map(_ordenes);
    // la web siempre llena assignedTechId al asignar
    // Firestore acepta hasta 30 combinaciones por consulta: por localidad, solo los dos estados normales (2 × 15)
    final consultas = [
      abiertas.where('assignedTechId', isEqualTo: t.userId),
      if (t.zonas.isNotEmpty)
        _tickets
            .where('status', whereIn: const ['pendiente', 'en_proceso'])
            .where('zoneId', whereIn: t.zonas.take(15).toList()),
    ];
    return _juntar([for (final c in consultas) c.snapshots().map(_ordenes)]);
  }

  /// Órdenes completadas desde las 00:00 de hoy (de todos; la pantalla filtra las que le tocan).
  Stream<List<Orden>> culminadasHoy() {
    final ahora = DateTime.now();
    final inicio = Timestamp.fromDate(DateTime(ahora.year, ahora.month, ahora.day));
    return _tickets.where('completedAt', isGreaterThanOrEqualTo: inicio).snapshots().map(_ordenes);
  }

  /// Historial de la más nueva a la más vieja, de 25 en 25. El técnico ve las suyas; el administrador, todas o las de
  /// una localidad. Con `rango`, solo las creadas esos días (como el Histórico de la web, que filtra por createdAt).
  /// Usa los índices de firestore.indexes.json de la web (assignedTechId/zoneId + createdAt).
  Future<PaginaHistorial> historial(
    Tecnico t, {
    String? zona,
    RangoDias? rango,
    DocumentSnapshot<Map<String, dynamic>>? despuesDe,
  }) async {
    const porPagina = 25;
    Query<Map<String, dynamic>> q = _tickets;
    if (!t.esAdmin) {
      q = q.where('assignedTechId', isEqualTo: t.userId);
    } else if (zona != null) {
      q = q.where('zoneId', isEqualTo: zona);
    }
    if (rango != null) {
      q = q
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(rango.desde))
          .where('createdAt', isLessThan: Timestamp.fromDate(finDeRango(rango)));
    }
    q = q.orderBy('createdAt', descending: true).limit(porPagina);
    if (despuesDe != null) q = q.startAfterDocument(despuesDe);
    final s = await q.get();
    return PaginaHistorial(_ordenes(s), s.docs.isEmpty ? despuesDe : s.docs.last, hayMas: s.docs.length == porPagina);
  }

  /// Una orden en vivo, para el detalle.
  Stream<Orden> orden(String id) => _tickets.doc(id).snapshots().map((d) => Orden(d.id, d.data() ?? const {}));

  /// Acepta la orden solo si sigue sin técnico (por si otro la acepta al mismo tiempo). Necesita internet.
  Future<void> tomar(String id, Tecnico t) => seguro(
    () => _db
        .runTransaction((tx) async {
          final ref = _tickets.doc(id);
          final o = Orden(id, (await tx.get(ref)).data() ?? const {});
          final abierta = o.estado == 'pendiente' || o.estado == 'en_proceso';
          if (!abierta || o.tieneTecnico) throw const ErrorDeOrden(FalloOrden.yaTomada);
          tx.update(ref, datosAlTomar(o, t.userId, t.nombre, textoDia(DateTime.now())));
        })
        .timeout(espera, onTimeout: () => throw const ErrorDeOrden(FalloOrden.sinInternet)),
  );

  /// Los cambios devuelven false si no hubo señal: quedan guardados en el celular y Firebase los sube después.
  Future<bool> empezar(Orden o, Tecnico t) => _guardar(o, datosAlEmpezar(o, t.userId, t.nombre));

  Future<bool> guardarComentarios(Orden o, String texto, Tecnico t) =>
      _guardar(o, datosComentarios(texto, t.userId, t.nombre));

  /// Prospectos en vivo (son pocos: se escucha la colección y se filtra aquí). Sin estado cuenta como pendiente. El
  /// técnico ve los de sus localidades y los que no tienen localidad, como `prosScope` de la web.
  Stream<List<Prospecto>> prospectos(Tecnico t) => _db
      .collection('prospects')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            if (d.id != '_seed')
              if (Prospecto(d.id, d.data()) case final p
                  when t.esAdmin || t.zonas.isEmpty || p.zonaId.isEmpty || t.zonas.contains(p.zonaId))
                p,
        ],
      );

  /// Crea o cambia un prospecto. Devuelve false si no hubo señal (se sube después).
  Future<bool> guardarProspecto(DatosProspecto d, Tecnico t, {Prospecto? antes}) async {
    var enLinea = true;
    final datos = datosProspecto(d, antes: antes, userId: t.userId, nombre: t.nombre);
    final col = _db.collection('prospects');
    Future<void> escribir() async => antes == null ? await col.add(datos) : await col.doc(antes.id).update(datos);
    await seguro(() => escribir().timeout(espera, onTimeout: () => enLinea = false));
    return enLinea;
  }

  /// Ya se creó su orden: el prospecto queda asignado a ella (su id y su folio, como `linkProspectToTicket`).
  Future<void> asignarProspecto(Prospecto p, OrdenCreada orden, Tecnico t) => seguro(
    () =>
        _db.collection('prospects').doc(p.id).update(datosProspectoAsignado(orden.id, orden.folio, t.userId, t.nombre)),
  );

  /// Las fotos de la orden (`phFetch` de la web): las numeradas, o la única vieja sin número.
  Future<List<String>> fotosDeOrden(Orden o) async {
    final fotos = _db.collection('orderPhotos');
    final clave = claveFotos(o.id);
    final docs = fotoVieja(o)
        ? [await fotos.doc(clave).get()]
        : await Future.wait([for (var i = 0; i < cuantasFotos(o); i++) fotos.doc('${clave}_$i').get()]);
    return [
      for (final d in docs)
        if ('${d.data()?['photo'] ?? ''}'.isNotEmpty) '${d.data()!['photo']}',
    ];
  }

  /// Guarda las fotos de la orden de una vez (las que cambiaron, borra las que sobran y pone el total en la orden).
  /// Devuelve false si no hubo señal: quedan en el celular y se suben después.
  Future<bool> guardarFotos(Orden o, List<String> antes, List<String> ahora, Tecnico t) async {
    final c = cambiosDeFotos(o, antes, ahora, userId: t.userId, nombre: t.nombre);
    final lote = _db.batch();
    for (final MapEntry(key: id, value: datos) in c.fotos.entries) {
      final ref = _db.collection('orderPhotos').doc(id);
      datos == null ? lote.delete(ref) : lote.set(ref, datos);
    }
    lote.update(_tickets.doc(o.id), c.orden);
    var enLinea = true;
    await seguro(() => lote.commit().timeout(espera, onTimeout: () => enLinea = false));
    return enLinea;
  }

  /// Inconclusas pendientes, en vivo (pocas: solo las marcadas). El administrador ve todas; el técnico, las de sus
  /// localidades y las suyas, como `incScope` de la web.
  Stream<List<Orden>> inconclusas(Tecnico t) => _tickets
      .where('incPending', isEqualTo: true)
      .snapshots()
      .map(
        (s) => [
          for (final o in _ordenes(s))
            if (o.datos['cancelled'] != true &&
                (t.esAdmin || t.zonas.isEmpty || o.esDe(t.userId) || t.zonas.contains(o.zonaId)))
              o,
        ],
      );

  Future<bool> marcarInconclusa(Orden o, String dia, String motivo, Tecnico t) =>
      _guardar(o, datosInconclusa(o, dia: dia, motivo: motivo, userId: t.userId, nombre: t.nombre));

  Future<bool> resolverInconclusa(Orden o, Tecnico t) => _guardar(o, datosResolverInconclusa(t.userId, t.nombre));

  /// `materiales`: lo de la ventana de materiales (quién la completó, módem e insumos), si se pidió.
  Future<bool> terminar(Orden o, Tecnico t, {String? comentarios, Map<String, Object?>? materiales}) => _guardar(o, {
    ...datosAlTerminar(o, t.userId, t.nombre),
    if (comentarios != null) ...datosComentarios(comentarios, t.userId, t.nombre),
    ...?materiales,
  });

  /// Guarda el cobro de la pantalla de cobro (`forma` null = completar sin cobro), con los comentarios sin guardar.
  /// `comprobante`: la foto del comprobante de una transferencia (`data:image/jpeg;base64,…`), que se guarda junto.
  Future<bool> cobrar(
    Orden o,
    List<Concepto> filas,
    FormaPago? forma,
    Tecnico t, {
    String? comentarios,
    Map<String, Object?>? materiales,
    String? comprobante,
  }) async {
    final datos = {
      ...datosCobro(o, filas, forma, t.userId, t.nombre),
      if (comentarios != null) ...datosComentarios(comentarios, t.userId, t.nombre),
      ...?materiales,
    };
    if (comprobante == null || forma != FormaPago.transferencia) return _guardar(o, datos);
    // el comprobante y el cobro van juntos: o se guardan los dos, o ninguno
    final c = datosComprobante(o, comprobante, userId: t.userId, nombre: t.nombre);
    final lote = _db.batch()
      ..set(_db.collection('payProofs').doc(o.id), c.archivo)
      ..update(_tickets.doc(o.id), {...datos, ...c.resumen});
    var enLinea = true;
    await seguro(() => lote.commit().timeout(espera, onTimeout: () => enLinea = false));
    return enLinea;
  }

  /// Para la ventana de materiales: Sistema › Activos (`assets`), sus categorías e insumos promedio de cada localidad
  /// (`zones.supplyQty`). Se lee una vez mientras la app está abierta.
  Future<CatalogoMateriales> materiales() async {
    final guardado = _materiales;
    if (guardado != null) return guardado;
    final r = await Future.wait([
      _db.collection('assets').get(),
      _db.collection('assetCategories').get(),
      _db.collection('zones').get(),
    ]);
    final categorias = {
      for (final d in r[1].docs)
        if (d.id != '_seed') d.id: '${d.data()['name'] ?? d.id}',
    };
    return _materiales = CatalogoMateriales(
      activos: [
        for (final d in r[0].docs)
          if (d.id != '_seed') activoDe(d.id, d.data(), categorias),
      ],
      categorias: categorias,
      insumosPorZona: {
        for (final d in r[2].docs)
          if (d.data()['supplyQty'] is List)
            d.id: {
              for (final m in d.data()['supplyQty'] as List)
                if (m is Map && '${m['assetId'] ?? ''}'.isNotEmpty && (num.tryParse('${m['qty']}') ?? 0) > 0)
                  '${m['assetId']}': num.parse('${m['qty']}').toDouble(),
            },
      },
    );
  }

  /// Catálogos de cobros (`serviceCharges`) y servicios (`services`), leídos una sola vez.
  Future<Catalogos> catalogos() async {
    final guardados = _catalogos;
    if (guardados != null) return guardados;
    final r = await Future.wait([_db.collection('serviceCharges').get(), _db.collection('services').get()]);
    return _catalogos = Catalogos(
      cobros: [
        for (final d in r[0].docs)
          if (d.id != '_seed') {...d.data(), 'id': d.id},
      ],
      servicios: {for (final d in r[1].docs) d.id: d.data()},
    );
  }

  Future<bool> _guardar(Orden o, Map<String, Object?> datos) async {
    var enLinea = true;
    await seguro(() => _tickets.doc(o.id).update(datos).timeout(espera, onTimeout: () => enLinea = false));
    return enLinea;
  }

  /// Crea la orden como la web: folio con el contador `counters/tickets` y el prefijo de la localidad, y el folio como id.
  /// Necesita internet (el contador no puede quedar a medias). Devuelve la orden creada: su id (casi siempre igual al
  /// folio) y el folio.
  Future<OrdenCreada> crear(DatosOrden d, Tecnico t) async {
    final zonas = await this.zonas();
    final cat = await catalogosOrden();
    late String folio, id;
    await seguro(() async {
      final contador = _db.collection('counters').doc('tickets');
      final n = await _db
          .runTransaction((tx) async {
            final actual = (await tx.get(contador)).data()?['value'];
            final siguiente = (actual is num ? actual.toInt() : 0) + 1;
            tx.set(contador, {'value': siguiente});
            return siguiente;
          })
          .timeout(espera, onTimeout: () => throw const ErrorDeOrden(FalloOrden.sinInternet));
      folio = folioNuevo(n, zonas[d.zonaId] ?? '');
      id = idDeFolio(folio);
      if ((await _tickets.doc(id).get()).exists) id = idDeFolio('$folio ${DateTime.now().millisecondsSinceEpoch}');
      final datos = datosOrdenNueva(d, cat, folio: folio, userId: t.userId, nombre: t.nombre, ahora: DateTime.now());
      await _tickets.doc(id).set(datos).timeout(espera, onTimeout: () {});
      // la orden ya quedó guardada: si falla el registro de Temporales no se avisa como error (se repetiría la orden)
      if (datos['tempCancel'] != null) await _registrarTemporalSinFallar(id, datos, t);
    });
    return (id: id, folio: folio);
  }

  /// Guarda los cambios del administrador (sin señal queda en el teléfono y se sube después).
  Future<bool> editar(Orden o, DatosOrden d, Tecnico t) async {
    final zonas = await this.zonas();
    final cat = await catalogosOrden();
    final datos = datosOrdenEditada(o, d, cat, nombreZona: zonas[d.zonaId] ?? '', userId: t.userId, nombre: t.nombre);
    final enLinea = await _guardar(o, datos);
    if (o.datos['tempCancel'] != null || datos['tempCancel'] != null) {
      await _registrarTemporalSinFallar(o.id, {...o.datos, ...datos}, t);
    }
    return enLinea;
  }

  /// El registro de Temporales es aparte de la orden: si falla (sin señal), la orden igual quedó bien.
  Future<void> _registrarTemporalSinFallar(String ticketId, Map<String, Object?> orden, Tecnico t) async {
    try {
      await _registrarTemporal(ticketId, orden, t);
    } on FirebaseException {
      // se corrige al volver a guardar la orden
    }
  }

  /// Cancelados › Temporales como `tcSyncTicket` de la web: la orden temporal tiene su registro `tk_<id>`; si deja de ser
  /// temporal (o se elimina), su registro se anula.
  Future<void> _registrarTemporal(String ticketId, Map<String, Object?> orden, Tecnico t) async {
    final ref = _db.collection('tempCancels').doc('tk_$ticketId');
    final temporal = orden['tempCancel'];
    final DocumentSnapshot<Map<String, dynamic>> actual;
    try {
      actual = await ref.get().timeout(espera);
    } on TimeoutException {
      return; // sin señal: se corrige al volver a guardar
    }
    if (temporal is Map<String, Object?>) {
      await ref
          .set(
            datosRegistroTemporal(ticketId, orden, temporal, existe: actual.exists, userId: t.userId, nombre: t.nombre),
            SetOptions(merge: true),
          )
          .timeout(espera, onTimeout: () {});
    } else if (actual.exists) {
      await ref
          .update({
            'voided': true,
            'lastChangedById': t.userId,
            'lastChangedByName': t.nombre,
            'lastChangedAt': FieldValue.serverTimestamp(),
          })
          .timeout(espera, onTimeout: () {});
    }
  }

  /// Elimina como la web: primero a la Papelera (se puede restaurar 30 días desde la web) y luego se borra; si era una
  /// cancelación temporal, su registro de Temporales se anula.
  Future<void> eliminar(Orden o, Tecnico t) => seguro(() async {
    // sin señal no se elimina (si no, se borraría sola más tarde aunque dijera «sin internet»)
    await _tickets
        .doc(o.id)
        .get(const GetOptions(source: Source.server))
        .timeout(espera, onTimeout: () => throw const ErrorDeOrden(FalloOrden.sinInternet));
    final lote = _db.batch()
      ..set(_db.collection('trash').doc(), datosPapelera(o, t.userId, t.nombre))
      ..delete(_tickets.doc(o.id));
    await lote.commit().timeout(espera, onTimeout: () => throw const ErrorDeOrden(FalloOrden.sinInternet));
    if (o.datos['tempCancel'] != null) await _registrarTemporalSinFallar(o.id, const {}, t);
  });

  /// Catálogos del formulario de órdenes (servicios, categorías de módem, comisionistas, comisiones, motivos), una vez.
  Future<CatalogosOrden> catalogosOrden() async {
    final guardados = _catalogosOrden;
    if (guardados != null) return guardados;
    final base = await catalogos();
    final r = await Future.wait([
      _db.collection('assetCategories').get(),
      _db.collection('commissioners').get(),
      _db.collection('bajaReasons').get(),
    ]);
    List<Map<String, dynamic>> docs(QuerySnapshot<Map<String, dynamic>> q) => [
      for (final d in q.docs)
        if (d.id != '_seed') {...d.data(), 'id': d.id},
    ];
    final tv = base.cobros.where((c) => plano(c['serviceName'] ?? c['name']) == 'tv adicional').firstOrNull;
    final cat = CatalogosOrden(
      servicios: {
        for (final e in base.servicios.entries)
          if (e.key != '_seed') e.key: e.value,
      },
      modems: categoriasModem(docs(r[0])),
      comisionistas: [
        for (final c in docs(r[1]))
          Comisionista(
            '${c['id']}',
            '${c['name'] ?? ''}',
            [for (final z in (c['zoneIds'] as List? ?? const [])) '$z'],
            [for (final z in (c['commissionIds'] as List? ?? const [])) '$z'],
          ),
      ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase())),
      comisiones: await comisiones(),
      motivos: [
        for (final m in docs(r[2])..sort(compararOrdenWeb))
          MotivoBaja('${m['id']}', '${m['name'] ?? ''}', otro: m['other'] == true),
      ],
      precioTv: num.tryParse('${tv?['amount'] ?? ''}')?.toDouble(),
    );
    // sin señal puede llegar incompleto: solo se guarda si trae servicios
    if (cat.servicios.isNotEmpty) _catalogosOrden = cat;
    return cat;
  }

  /// Módems por recuperar (cancelados definitivos sin recuperar), en vivo. El administrador, todos; el técnico, los de sus
  /// localidades y los que le asignaron a él en cualquier localidad.
  Stream<List<Orden>> modemsPorRecuperar(Tecnico t) {
    final abiertos = _tickets.where('modemStatus', whereIn: const ['pendiente', 'asignado']);
    final consultas = t.esAdmin
        ? [abiertos]
        : [
            _tickets.where('modemStatus', isEqualTo: 'asignado').where('modemRecoveryById', isEqualTo: t.userId),
            if (t.zonas.isNotEmpty) abiertos.where('zoneId', whereIn: t.zonas.take(15).toList()),
          ];
    return _juntar([for (final c in consultas) c.snapshots().map(_ordenes)])
        .map((l) => l.where(esBajaConModem).toList());
  }

  /// Catálogo de Sistema › Comisiones (`commissions`), leído una sola vez.
  Future<List<Map<String, dynamic>>> comisiones() async {
    final guardadas = _comisiones;
    if (guardadas != null) return guardadas;
    final s = await _db.collection('commissions').get();
    final lista = [
      for (final d in s.docs)
        if (d.id != '_seed') {...d.data(), 'id': d.id},
    ];
    // sin señal llega vacío o de la memoria del teléfono: no se guarda, para volver a pedirlo con internet
    if (lista.isNotEmpty && !s.metadata.isFromCache) _comisiones = lista;
    return lista;
  }

  /// Quién va por el módem (uid vacío = nadie). Necesita internet: solo si nadie más lo tomó o lo recuperó.
  Future<void> asignarModem(Orden o, String uid, String uNombre, Tecnico t) => _cambiarModem(o, (actual, cat) {
    final st = estadoModem(actual);
    final otro = st == EstadoModem.asignado && recuperaId(actual) != t.userId && !t.esAdmin;
    if (st == EstadoModem.recuperado || otro) throw const ErrorDeOrden(FalloOrden.yaTomada);
    return datosAsignarModem(actual, cat, uid: uid, uNombre: uNombre, userId: t.userId, nombre: t.nombre);
  });

  /// «Ya lo recuperé». Necesita internet: solo si sigue a su nombre (o es administrador), por si la oficina se lo pasó a otro.
  Future<void> recuperarModem(Orden o, Tecnico t) => _cambiarModem(o, (actual, cat) {
    final suyo = estadoModem(actual) == EstadoModem.asignado && (t.esAdmin || recuperaId(actual) == t.userId);
    if (!suyo) throw const ErrorDeOrden(FalloOrden.yaTomada);
    return datosModemRecuperado(actual, cat, t.userId, t.nombre);
  });

  /// Cambia el módem leyendo cómo está ahora mismo en la base (`cambio` lanza ErrorDeOrden si ya no se puede).
  Future<void> _cambiarModem(
    Orden o,
    Map<String, Object?> Function(Orden actual, List<Map<String, dynamic>> catalogo) cambio,
  ) async {
    final cat = await comisiones();
    await seguro(
      () => _db
          .runTransaction((tx) async {
            final ref = _tickets.doc(o.id);
            tx.update(ref, cambio(Orden(o.id, (await tx.get(ref)).data() ?? const {}), cat));
          })
          .timeout(espera, onTimeout: () => throw const ErrorDeOrden(FalloOrden.sinInternet)),
    );
  }

  /// Pago de comisiones (solo el administrador): las órdenes completadas y los módems recuperados en el periodo, y los
  /// módems de Importados ISP (`ispCancels`, por `recoveredDay`). Se lee una vez por periodo; `recargar` vuelve a pedir.
  Future<({List<Orden> ordenes, List<Orden> isp})> comisionesDelPeriodo(
    DateTime desde,
    DateTime hastaExclusivo, {
    bool recargar = false,
  }) async {
    final clave = 'com|$desde|$hastaExclusivo';
    final guardadas = _comisionesPeriodo[clave];
    if (guardadas != null && !recargar) return guardadas;
    final a = Timestamp.fromDate(desde), b = Timestamp.fromDate(hastaExclusivo);
    final r = await Future.wait([
      _tickets.where('completedAt', isGreaterThanOrEqualTo: a).where('completedAt', isLessThan: b).get(),
      _tickets.where('modemRecoveredAt', isGreaterThanOrEqualTo: a).where('modemRecoveredAt', isLessThan: b).get(),
      _db
          .collection('ispCancels')
          .where('recoveredDay', isGreaterThanOrEqualTo: textoDia(desde))
          .where('recoveredDay', isLessThan: textoDia(hastaExclusivo))
          .get(),
    ]);
    return _comisionesPeriodo[clave] = (
      ordenes: unirSinRepetir([_ordenes(r[0]), _ordenes(r[1])]),
      isp: [
        for (final d in r[2].docs)
          if (d.data()['status'] == 'recuperado' && '${d.data()['reconTicketId'] ?? ''}'.isEmpty)
            ordenDeIsp(d.id, d.data()),
      ],
    );
  }

  /// Quién cobra cada comisión: los comisionistas (id → nombre) y los usuarios, para las órdenes viejas.
  Future<({Map<String, String> comisionistas, Map<String, String> usuarios})> nombresParaComisiones() async {
    final r = await Future.wait([catalogosOrden(), usuarios()]);
    return (
      comisionistas: {for (final c in (r[0] as CatalogosOrden).comisionistas) c.id: c.nombre},
      usuarios: {for (final u in r[1] as List<UsuarioAsignable>) u.id: u.nombre},
    );
  }

  /// Finanzas (solo el administrador; las reglas solo dejan leerlas a él): ingresos de servicios (`serviceIncome`, pocos:
  /// se leen todos una vez) y gastos (`expenses`) de esos días.
  /// También las partidas de gasto (`expenseCategories`), para saber si las comisiones cuentan como gasto.
  Future<
    ({
      List<Map<String, dynamic>> ingresos,
      List<Map<String, dynamic>> gastos,
      List<Map<String, dynamic>> partidas,
      List<Orden> cobradas,
    })
  >
  finanzas(DateTime desde, DateTime hastaExclusivo, {bool recargar = false}) async {
    final clave = 'fin|$desde|$hastaExclusivo';
    final guardadas = _finanzas[clave];
    if (guardadas != null && !recargar) return guardadas;
    if (recargar || _ingresos == null || _partidas == null) {
      List<Map<String, dynamic>> docs(QuerySnapshot<Map<String, dynamic>> s) => [
        for (final d in s.docs)
          if (d.id != '_seed') {...d.data(), 'id': d.id},
      ];
      final r = await Future.wait([_db.collection('serviceIncome').get(), _db.collection('expenseCategories').get()]);
      _ingresos = docs(r[0]);
      _partidas = docs(r[1]);
    }
    final r = await Future.wait([
      _db
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: textoDia(desde))
          .where('date', isLessThan: textoDia(hastaExclusivo))
          .get(),
      // cobradas en el periodo aunque se completaron antes (la web cuenta el cobro por pendingPaidAt primero)
      _tickets
          .where('pendingPaidAt', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
          .where('pendingPaidAt', isLessThan: Timestamp.fromDate(hastaExclusivo))
          .get(),
    ]);
    return _finanzas[clave] = (
      ingresos: _ingresos!,
      partidas: _partidas!,
      gastos: [
        for (final d in r[0].docs) {...d.data(), 'id': d.id},
      ],
      cobradas: _ordenes(r[1]),
    );
  }

  /// Para el Dashboard (solo el administrador): las órdenes creadas desde `desde` (incluye el periodo anterior para
  /// comparar) y las completadas desde `completadasDesde`, hasta `hastaExclusivo`. Se lee una vez (no en vivo) por
  /// periodo y se guarda mientras la app está abierta, para cuidar las lecturas.
  Future<List<Orden>> ordenesDelPeriodo(
    DateTime desde,
    DateTime completadasDesde,
    DateTime hastaExclusivo, {
    bool recargar = false,
  }) async {
    final clave = '$desde|$completadasDesde|$hastaExclusivo';
    final guardadas = _periodos[clave];
    if (guardadas != null && !recargar) return guardadas;
    final hasta = Timestamp.fromDate(hastaExclusivo);
    final r = await Future.wait([
      _tickets
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
          .where('createdAt', isLessThan: hasta)
          .get(),
      _tickets
          .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(completadasDesde))
          .where('completedAt', isLessThan: hasta)
          .get(),
    ]);
    return _periodos[clave] = unirSinRepetir([_ordenes(r[0]), _ordenes(r[1])]);
  }

  /// Cobros que esperan que la oficina los autorice (Finanzas › Pendientes de pago de la web, `needsPayAuth`), la más
  /// nueva primero. Las solicitudes se escuchan en vivo; las completadas «pendiente»/«sin costo» (que crecen con el
  /// tiempo) se leen una vez y se guardan mientras la app está abierta, salvo con `recargar`.
  Stream<List<Orden>> porAutorizar({bool recargar = false}) {
    if (recargar || _sinAutorizar == null) {
      _sinAutorizar = _tickets.where('paymentMethod', whereIn: const ['pendiente', 'sin_costo']).get().then(_ordenes);
      _sinAutorizar!.ignore(); // si falla, el error sale en la pantalla (por el stream), no queda suelto
    }
    DateTime fecha(Orden o) => o.creadaEn ?? DateTime(2000);
    return _juntar([
      _tickets.where('payAuthStatus', isEqualTo: 'solicitada').snapshots().map(_ordenes),
      Stream.fromFuture(_sinAutorizar!),
    ]).map((l) => l.where(esperaAutorizar).toList()..sort((a, b) => fecha(b).compareTo(fecha(a))));
  }

  /// Usuarios a los que se les puede asignar una orden (`users`), leídos una sola vez, como `assignOpts` de la web.
  Future<List<UsuarioAsignable>> usuarios() async {
    final guardados = _usuarios;
    if (guardados != null) return guardados;
    final s = await _db.collection('users').get();
    return _usuarios = [
      for (final d in s.docs)
        if (d.id != '_seed')
          UsuarioAsignable(
            d.id,
            '${d.data()['name'] ?? d.data()['username'] ?? ''}'.trim(),
            zonasDeUsuario(d.data()),
            email: '${d.data()['email'] ?? ''}',
          ),
    ]..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
  }

  /// Nombre de cada localidad (`zones`), leído una sola vez y en el orden de la web (el que se arrastra en
  /// Sistema › Localidades: `order`, y si no tiene, la más vieja primero).
  Future<Map<String, String>> zonas() async {
    final guardadas = _zonas;
    if (guardadas != null) return guardadas;
    final s = await _db.collection('zones').get();
    final activas = [
      for (final d in s.docs)
        if (d.data()['active'] != false) d,
    ]..sort((a, b) => compararOrdenWeb(a.data(), b.data()));
    return _zonas = {for (final d in activas) d.id: (d.data()['name'] ?? d.id).toString()};
  }

  static const espera = Duration(seconds: 10);

  /// Cambia los errores de Firebase por un `ErrorDeOrden` que la pantalla sabe explicar.
  static Future<void> seguro(Future<void> Function() accion) async {
    try {
      await accion();
    } on FirebaseException catch (e) {
      throw ErrorDeOrden(switch (e.code) {
        'unavailable' || 'network-request-failed' => FalloOrden.sinInternet,
        'permission-denied' => FalloOrden.sinPermiso,
        _ => FalloOrden.otro,
      }, e.code);
    }
  }

  /// Junta varias consultas en vivo en una sola lista (sin repetir); espera a que todas respondan la primera vez.
  static Stream<List<Orden>> _juntar(List<Stream<List<Orden>>> fuentes) {
    if (fuentes.length == 1) return fuentes.first;
    final ultimas = List<List<Orden>?>.filled(fuentes.length, null);
    final subs = <StreamSubscription<List<Orden>>>[];
    late final StreamController<List<Orden>> salida;
    salida = StreamController(
      onListen: () {
        for (var i = 0; i < fuentes.length; i++) {
          subs.add(
            fuentes[i].listen((lista) {
              ultimas[i] = lista;
              if (ultimas.every((l) => l != null)) salida.add(unirSinRepetir(ultimas.cast<List<Orden>>()));
            }, onError: salida.addError),
          );
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return salida.stream;
  }
}
