import 'package:cloud_firestore/cloud_firestore.dart';

import 'usuarios.dart';

/// Menú «Sistema» de la web (solo el administrador): de qué colección sale cada lista y en qué
/// orden se muestra, como `sortList` y `orderThenName` de src/legacy/app.js.

enum Catalogo {
  usuarios,
  roles,
  ocupaciones,
  localidades,
  fechasPago,
  zonas,
  servicios,
  comisiones,
  comisionistas,
  activos,
  insumos,
  motivosCancelacion,
  cobros,
  formasPago,
  partidasGasto,
}

/// La colección de Firebase de cada lista (Activos e Insumos salen de la misma: con categoría y sin ella).
String coleccionDe(Catalogo c) => switch (c) {
  Catalogo.usuarios => 'users',
  Catalogo.roles => 'roles',
  Catalogo.ocupaciones => 'occupations',
  Catalogo.localidades => 'zones',
  Catalogo.fechasPago => 'payDates',
  Catalogo.zonas => 'localityZones',
  Catalogo.servicios => 'services',
  Catalogo.comisiones => 'commissions',
  Catalogo.comisionistas => 'commissioners',
  Catalogo.activos || Catalogo.insumos => 'assets',
  Catalogo.motivosCancelacion => 'bajaReasons',
  Catalogo.cobros => 'serviceCharges',
  Catalogo.formasPago => 'paymentMethods',
  Catalogo.partidasGasto => 'expenseCategories',
};

/// Un registro de un catálogo.
typedef Registro = ({String id, Map<String, dynamic> datos});

String nombreDe(Registro r) => '${r.datos['name'] ?? r.datos['serviceName'] ?? ''}'.trim();

double _orden(Registro r) => num.tryParse('${r.datos['order'] ?? ''}')?.toDouble() ?? 1e9;

/// `sortList`: por el orden que se arrastra en la web y luego el más viejo primero; Comisiones y Activos, por nombre.
List<Registro> ordenarCatalogo(Catalogo c, Iterable<Registro> l) {
  final porNombre =
      c == Catalogo.comisiones || c == Catalogo.activos || c == Catalogo.insumos || c == Catalogo.usuarios;
  DateTime creado(Registro r) =>
      r.datos['createdAt'] is Timestamp ? (r.datos['createdAt'] as Timestamp).toDate() : DateTime(9999);
  return [...l]..sort((a, b) {
    final o = _orden(a).compareTo(_orden(b));
    if (o != 0) return o;
    return porNombre ? nombreDe(a).toLowerCase().compareTo(nombreDe(b).toLowerCase()) : creado(a).compareTo(creado(b));
  });
}

/// Los activos van a Activos si tienen categoría (módems, equipos) y a Insumos si no (cable, conectores…).
bool entraEn(Catalogo c, Registro r) => switch (c) {
  Catalogo.activos => '${r.datos['categoryId'] ?? ''}'.isNotEmpty,
  Catalogo.insumos => '${r.datos['categoryId'] ?? ''}'.isEmpty,
  _ => r.id != '_seed',
};

// ---------- Agregar, cambiar y borrar (como los formularios de Sistema de la web) ----------

enum TipoCampo { texto, largo, numero, dia, siNo, localidades, localidad, categoria, comisiones, permiso }

/// Un campo del formulario: su nombre en Firebase y qué se escribe.
typedef Campo = ({String clave, TipoCampo tipo});

/// En estas el nombre es la llave del registro: cambiarlo en la web reescribe las órdenes que lo usan (`moveDoc`), así
/// que en la app el nombre solo se escribe al crear.
bool nombreEsLlave(Catalogo c) => const {
  Catalogo.roles,
  Catalogo.ocupaciones,
  Catalogo.localidades,
  Catalogo.zonas,
  Catalogo.servicios,
  Catalogo.comisiones,
  Catalogo.cobros,
  Catalogo.formasPago,
  Catalogo.partidasGasto,
}.contains(c);

List<Campo> camposDe(Catalogo c) => switch (c) {
  Catalogo.ocupaciones || Catalogo.formasPago => const [(clave: 'name', tipo: TipoCampo.texto)],
  Catalogo.localidades || Catalogo.motivosCancelacion || Catalogo.partidasGasto => const [
    (clave: 'name', tipo: TipoCampo.texto),
    (clave: 'description', tipo: TipoCampo.largo),
  ],
  Catalogo.fechasPago => const [
    (clave: 'payFrom', tipo: TipoCampo.dia),
    (clave: 'payTo', tipo: TipoCampo.dia),
    (clave: 'invoiceDay', tipo: TipoCampo.dia),
    (clave: 'installFrom', tipo: TipoCampo.dia),
    (clave: 'installTo', tipo: TipoCampo.dia),
    (clave: 'zoneIds', tipo: TipoCampo.localidades),
  ],
  Catalogo.zonas => const [(clave: 'name', tipo: TipoCampo.texto), (clave: 'localityId', tipo: TipoCampo.localidad)],
  Catalogo.servicios => const [
    (clave: 'name', tipo: TipoCampo.texto),
    (clave: 'description', tipo: TipoCampo.largo),
    (clave: 'commission', tipo: TipoCampo.siNo),
    (clave: 'billable', tipo: TipoCampo.siNo),
    (clave: 'isp', tipo: TipoCampo.siNo),
  ],
  Catalogo.comisiones => const [(clave: 'name', tipo: TipoCampo.texto), (clave: 'amount', tipo: TipoCampo.numero)],
  Catalogo.cobros => const [(clave: 'serviceName', tipo: TipoCampo.texto), (clave: 'amount', tipo: TipoCampo.numero)],
  Catalogo.comisionistas => const [
    (clave: 'name', tipo: TipoCampo.texto),
    (clave: 'description', tipo: TipoCampo.largo),
    (clave: 'zoneIds', tipo: TipoCampo.localidades),
    (clave: 'commissionIds', tipo: TipoCampo.comisiones),
  ],
  Catalogo.activos => const [
    (clave: 'categoryId', tipo: TipoCampo.categoria),
    (clave: 'name', tipo: TipoCampo.texto),
    (clave: 'brand', tipo: TipoCampo.texto),
    (clave: 'model', tipo: TipoCampo.texto),
    (clave: 'unit', tipo: TipoCampo.texto),
    (clave: 'price', tipo: TipoCampo.numero),
    (clave: 'description', tipo: TipoCampo.largo),
  ],
  Catalogo.insumos => const [
    (clave: 'name', tipo: TipoCampo.texto),
    (clave: 'unit', tipo: TipoCampo.texto),
    (clave: 'price', tipo: TipoCampo.numero),
    (clave: 'description', tipo: TipoCampo.largo),
  ],
  Catalogo.roles => const [
    (clave: 'name', tipo: TipoCampo.texto),
    (clave: 'description', tipo: TipoCampo.largo),
    (clave: 'permission', tipo: TipoCampo.permiso),
  ],
  // Usuarios app tiene su propio formulario (con su acceso a la app): ver usuarios.dart
  Catalogo.usuarios => const [],
};

/// `nameId` de la web: el nombre como llave del registro.
String llaveDeNombre(String v) {
  var x = v.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll('/', '-');
  if (RegExp(r'^__.*__$').hasMatch(x)) x = x.replaceAll(RegExp(r'^_+|_+$'), '');
  if (x.isEmpty || x == '.' || x == '..') x = 'Sin nombre';
  return x.length > 300 ? x.substring(0, 300) : x;
}

/// La llave con que se crea un registro (null = la pone Firebase), como `saveNamed`, `chargeDocName` y `areaDocName`.
String? llaveNueva(Catalogo c, Map<String, Object?> v, {String nombreLocalidad = ''}) => switch (c) {
  Catalogo.cobros => llaveDeNombre('Cobro - ${v['serviceName'] ?? ''}'),
  Catalogo.zonas => llaveDeNombre('${nombreLocalidad.trim()} - ${'${v['name'] ?? ''}'.trim()}'),
  _ when nombreEsLlave(c) || c == Catalogo.motivosCancelacion => llaveDeNombre('${v['name'] ?? ''}'),
  _ => null,
};

/// Por qué no se puede guardar.
enum FalloSistema { faltaNombre, yaExiste, dia, importe, localidad, categoria, fechaChoca, permiso }

/// Los campos que no se cambian al editar: el nombre (y la localidad de una zona) donde es la llave; el nombre de un
/// comisionista (la web lo reescribe en todas sus órdenes) y el del motivo «Otros».
Set<String> camposFijos(Catalogo c, Registro? antes) {
  if (antes == null) return const {};
  if (nombreEsLlave(c)) return const {'name', 'serviceName', 'localityId'};
  if (c == Catalogo.comisionistas || (c == Catalogo.motivosCancelacion && antes.datos['other'] == true)) {
    return const {'name'};
  }
  return const {};
}

/// Si al editar no queda nada que cambiar (Ocupación, Formas de pago, Zonas): solo se puede borrar.
bool nadaQueCambiar(Catalogo c, Registro? antes) =>
    antes != null && camposDe(c).every((x) => camposFijos(c, antes).contains(x.clave));

/// Un nombre como lo guarda la web: sin espacios de más.
String limpiarNombre(Object? v) => '${v ?? ''}'.trim().replaceAll(RegExp(r'\s+'), ' ');

double _r2(num v) => (v * 100).round() / 100;

bool _cobroAbierto(String nombre) => RegExp(r'^otros?$|^re ?conexion(es)?\b').hasMatch(_sinAcentos(nombre));

bool _diaEn(int d, int de, int a) => de <= a ? d >= de && d <= a : d >= de || d <= a;

String _sinAcentos(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[áàä]'), 'a')
    .replaceAll(RegExp('[éèë]'), 'e')
    .replaceAll(RegExp('[íìï]'), 'i')
    .replaceAll(RegExp('[óòö]'), 'o')
    .replaceAll(RegExp('[úùü]'), 'u')
    .replaceAll('ñ', 'n')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Revisa lo escrito como el formulario de la web. `existentes`: toda la colección. `nombreLocalidad`: el de la
/// localidad elegida (para la llave de una zona).
FalloSistema? revisarRegistro(
  Catalogo c,
  Map<String, Object?> v,
  List<Registro> existentes, {
  Registro? antes,
  String nombreLocalidad = '',
}) {
  final campos = camposDe(c);
  final llaveNombre = campos.any((x) => x.clave == 'serviceName') ? 'serviceName' : 'name';
  final nombre = limpiarNombre(v[llaveNombre]);
  if (campos.any((x) => x.clave == llaveNombre) && nombre.isEmpty) return FalloSistema.faltaNombre;
  for (final x in campos) {
    final valor = v[x.clave];
    if (x.tipo == TipoCampo.dia && (valor is! int || valor < 1 || valor > 31)) return FalloSistema.dia;
    if (x.tipo == TipoCampo.numero && valor != null && (valor is! num || valor < 0 || valor.isNaN)) {
      return FalloSistema.importe;
    }
    if (x.tipo == TipoCampo.localidad && '${valor ?? ''}'.isEmpty) return FalloSistema.localidad;
  }
  // la comisión siempre lleva importe; el cobro, salvo «Otros» y «Reconexión» (se escribe al completar)
  if (c == Catalogo.comisiones && v['amount'] == null) return FalloSistema.importe;
  if (c == Catalogo.cobros && v['amount'] == null && !_cobroAbierto(nombre)) return FalloSistema.importe;
  if (c == Catalogo.activos && '${v['categoryId'] ?? ''}'.isEmpty) return FalloSistema.categoria;
  if (c == Catalogo.roles && !permisos.containsKey(v['permission'])) return FalloSistema.permiso;
  if (c == Catalogo.motivosCancelacion && antes?.datos['other'] != true && _sinAcentos(nombre) == 'otros') {
    return FalloSistema.yaExiste;
  }
  if (c == Catalogo.fechasPago) {
    // en una misma localidad, unos días de instalación no pueden entrar en dos fechas de pago
    final zonas = [for (final z in (v['zoneIds'] as List? ?? const [])) '$z'];
    int dia(Map<String, dynamic> d, String k) => (num.tryParse('${d[k] ?? ''}') ?? 0).toInt();
    final choca = existentes.any((o) {
      if (o.id == antes?.id) return false;
      final otras = [for (final z in (o.datos['zoneIds'] as List? ?? const [])) '$z'];
      final comparten = zonas.isEmpty || otras.isEmpty || zonas.any(otras.contains);
      return comparten &&
          List.generate(31, (i) => i + 1).any(
            (d) =>
                _diaEn(d, v['installFrom'] as int, v['installTo'] as int) &&
                _diaEn(d, dia(o.datos, 'installFrom'), dia(o.datos, 'installTo')),
          );
    });
    if (choca) return FalloSistema.fechaChoca;
  }
  // activos e insumos pueden repetir nombre, como en la web
  if (nombre.isNotEmpty &&
      c != Catalogo.activos &&
      c != Catalogo.insumos &&
      !camposFijos(c, antes).contains(llaveNombre)) {
    final clave = _sinAcentos(nombre);
    final mismo = existentes.any(
      (r) =>
          r.id != antes?.id &&
          _sinAcentos('${r.datos[llaveNombre] ?? r.datos['name'] ?? ''}') == clave &&
          (c != Catalogo.zonas || r.datos['localityId'] == v['localityId']),
    );
    if (mismo) return FalloSistema.yaExiste;
  }
  // la llave nueva no puede caer encima de otro registro (como `saveNamed`); un motivo usa otra llave (la pone el servicio)
  final llave = antes == null ? llaveNueva(c, v, nombreLocalidad: nombreLocalidad) : null;
  if (llave != null && c != Catalogo.motivosCancelacion && existentes.any((r) => r.id == llave)) {
    return FalloSistema.yaExiste;
  }
  return null;
}

Map<String, Object?> _cambio(String userId, String nombre) => {
  'lastChangedById': userId,
  'lastChangedByName': nombre,
  'lastChangedAt': FieldValue.serverTimestamp(),
};

/// Lo que se escribe, como cada formulario de Sistema de la web. Al crear se agregan los datos de alta (createdAt,
/// orden, valores por omisión); al cambiar, el nombre de los que lo usan como llave no se toca.
Map<String, Object?> datosRegistro(
  Catalogo c,
  Map<String, Object?> v, {
  Registro? antes,
  required List<Registro> existentes,
  required String userId,
  required String nombre,
  String nombreLocalidad = '',
}) {
  final nuevo = antes == null;
  final ahora = FieldValue.serverTimestamp();
  final fijos = camposFijos(c, antes);
  // como la web: nombres sin espacios de más, importes a 2 decimales y la unidad con mayúscula inicial
  Object? limpio(Campo x) {
    final valor = v[x.clave];
    if (x.clave == 'name' || x.clave == 'serviceName') return limpiarNombre(valor);
    if (x.clave == 'unit') {
      final u = '${valor ?? ''}'.trim();
      return u.isEmpty ? '' : u[0].toUpperCase() + u.substring(1);
    }
    if (valor is num && x.tipo == TipoCampo.numero) return _r2(valor);
    return valor is String ? valor.trim() : valor;
  }

  final valores = {
    for (final x in camposDe(c))
      if (!fijos.contains(x.clave)) x.clave: limpio(x),
  };
  final orden = existentes.fold<num>(0, (m, r) {
    final o = num.tryParse('${r.datos['order'] ?? ''}') ?? 0;
    return r.datos['other'] == true || o <= m ? m : o;
  });
  final cambio = _cambio(userId, nombre);
  return switch (c) {
    Catalogo.localidades => {
      ...valores,
      if (nuevo) ...{
        'payDays': const ['1-5', '6-10', '11-14', '15-19', '20-25', '26-30'],
        'supplyQty': const [],
        'active': true,
        'createdAt': ahora,
      } else
        ...cambio,
    },
    Catalogo.zonas => {
      ...valores,
      if (nuevo) ...{'localityName': nombreLocalidad, 'createdAt': ahora},
      ...cambio,
    },
    Catalogo.servicios => {
      ...valores,
      if (nuevo) ...{'materials': const [], 'materialsOn': false, 'aftOff': const [], 'createdAt': ahora},
    },
    Catalogo.comisionistas => {
      ...valores,
      'updatedAt': ahora,
      'updatedById': userId,
      'updatedByName': nombre,
      if (nuevo) ...{'createdAt': ahora, 'createdById': userId, 'createdByName': nombre},
    },
    Catalogo.activos || Catalogo.insumos => {
      ...valores,
      if (c == Catalogo.insumos) 'categoryId': '',
      'updatedAt': ahora,
      if (nuevo) 'createdAt': ahora,
    },
    Catalogo.motivosCancelacion => {
      ...valores,
      if (nuevo) ...{'order': orden + 1, 'createdAt': ahora},
      ...cambio,
    },
    Catalogo.partidasGasto => {
      ...valores,
      'order': antes?.datos['order'] ?? orden + 1,
      if (nuevo) 'createdAt': ahora,
      ...cambio,
    },
    Catalogo.ocupaciones => {...valores, if (nuevo) 'createdAt': ahora},
    Catalogo.roles => {...valores, ...datosPermiso(v['permission']), if (nuevo) 'createdAt': ahora},
    // al editar un cobro, la web quita el viejo `serviceId` (ahora va por nombre)
    Catalogo.cobros => {...valores, if (nuevo) 'createdAt': ahora else 'serviceId': FieldValue.delete(), ...cambio},
    _ => {...valores, if (nuevo) 'createdAt': ahora, ...cambio},
  };
}

/// Los que la web no deja borrar: el motivo «Otros» y los servicios de siempre (`FIXED_IDS`).
bool sePuedeBorrar(Catalogo c, Registro r) =>
    !(c == Catalogo.motivosCancelacion && r.datos['other'] == true) &&
    !(c == Catalogo.servicios && const ['instalacion', 'falla', 'mantenimiento', 'desactivacion'].contains(r.id));

/// Como `trashDel`: lo que se guarda en la Papelera (y, de una localidad, sus zonas), para restaurarlo desde la web.
Map<String, Object?> datosPapeleraRegistro(
  String coleccion,
  Registro r, {
  required String userId,
  required String nombre,
  String? padre,
  List<String> relacionados = const [],
}) => {
  'col': coleccion,
  'docId': r.id,
  'data': r.datos,
  'label': padre != null ? '' : _etiquetaPapelera(coleccion, r),
  if (padre != null) 'parentId': padre else 'relatedIds': relacionados,
  'deletedAt': FieldValue.serverTimestamp(),
  'deletedById': userId,
  'deletedByName': nombre,
};

/// Como `trashLabel`: el nombre (una fecha de pago, sus días de pago), hasta 200 letras.
String _etiquetaPapelera(String coleccion, Registro r) {
  final d = r.datos;
  final e = coleccion == 'payDates'
      ? '${d['payFrom'] ?? ''}-${d['payTo'] ?? ''}'
      : (nombreDe(r).isEmpty ? r.id : nombreDe(r));
  return e.length > 200 ? e.substring(0, 200) : e;
}

/// El motivo «Otros» va siempre al final: si el nuevo queda en su lugar o después, «Otros» baja uno más (como la web).
Registro? otrosQueBaja(List<Registro> existentes, Object? ordenNuevo) {
  final otros = existentes.where((r) => r.datos['other'] == true).firstOrNull;
  final n = num.tryParse('${ordenNuevo ?? ''}') ?? 0;
  return otros != null && (num.tryParse('${otros.datos['order'] ?? ''}') ?? 0) <= n ? otros : null;
}
