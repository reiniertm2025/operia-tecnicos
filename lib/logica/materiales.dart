import 'orden.dart';

/// Material al completar una orden, igual que la ventana «¿Quién la completó?» de la web (src/legacy/app.js: openDoneBy,
/// doneByNeedsModem, doneByModemFill, doneBySupFill, ticketSupplyKit, zoneSupply, svcHasMat, svcAftAllowed, isModemAsset,
/// modemUseData, supNewSvc).
///
/// - Solo si el servicio tiene marcada «Lleva materiales» (`services.materialsOn`, o trae `materials`) y no es una
///   cancelación definitiva.
/// - Módem instalado (AFT, de Sistema › Activos con categoría): viene «Ninguno» (sin gasto); si se instaló uno, sale del
///   inventario como nuevo. Se guarda en `tickets.modemUse`: {none: true} o {assetId, condition: 'nuevo'}.
/// - Insumos (activos que no son módem): la cantidad del servicio, o la de la localidad (`zones.supplyQty`) si la tiene;
///   se cambia ahí y queda solo en esa orden (`tickets.materialsUsed` = [{assetId, qty}]; sin la casilla, []).

/// Un artículo de Sistema › Activos (`assets`).
class Activo {
  const Activo({
    required this.id,
    required this.nombre,
    this.categoriaId = '',
    this.precio = 0,
    this.unidad = '',
    this.esModem = false,
  });

  final String id;

  /// Nombre con marca y modelo, como `tcAssetLabel`.
  final String nombre;
  final String categoriaId;
  final double precio;
  final String unidad;
  final bool esModem;
}

/// Lo que hace falta para la ventana: activos, sus categorías (id → nombre) e insumos promedio por localidad.
class CatalogoMateriales {
  const CatalogoMateriales({required this.activos, required this.categorias, required this.insumosPorZona});

  final List<Activo> activos;
  final Map<String, String> categorias;

  /// zoneId → (assetId → cantidad), de `zones.supplyQty`.
  final Map<String, Map<String, double>> insumosPorZona;

  Activo? activo(String id) => activos.where((a) => a.id == id).firstOrNull;

  /// Insumos: los activos que no son módem, por nombre.
  List<Activo> get insumos => [
    for (final a in activos)
      if (!a.esModem) a,
  ]..sort((a, b) => plano(a.nombre).compareTo(plano(b.nombre)));

  /// Pestañas de módem: cada categoría con sus activos (los que el servicio no quitó con `aftOff`), por nombre.
  List<({String id, String nombre, List<Activo> activos})> modemsPara(Map<String, dynamic>? servicio) {
    final fuera = servicio?['aftOff'] is List
        ? (servicio!['aftOff'] as List).map((e) => '$e').toSet()
        : const <String>{};
    final cats = categorias.entries.toList()..sort((a, b) => plano(a.value).compareTo(plano(b.value)));
    return [
      for (final c in cats)
        if ([
              for (final a in activos)
                if (a.categoriaId == c.key && !fuera.contains(a.id)) a,
            ]..sort((a, b) => plano(a.nombre).compareTo(plano(b.nombre)))
            case final lista when lista.isNotEmpty)
          (id: c.key, nombre: c.value, activos: lista),
    ];
  }
}

/// Un activo de `assets` como lo lee la web (`isModemAsset`: su categoría o su nombre dicen «módem»).
Activo activoDe(String id, Map<String, dynamic> d, Map<String, String> categorias) {
  final nombre = '${d['name'] ?? ''}'.trim();
  final marca = [
    d['brand'] ?? d['marca'],
    d['model'] ?? d['modelo'],
  ].where((x) => '${x ?? ''}'.trim().isNotEmpty).join(' ');
  final cat = '${d['categoryId'] ?? ''}';
  final modem = RegExp('m[oó]dem', caseSensitive: false);
  return Activo(
    id: id,
    nombre: [nombre, marca].where((x) => x.isNotEmpty).join(' · '),
    categoriaId: cat,
    precio: num.tryParse('${d['price'] ?? ''}')?.toDouble() ?? 0,
    unidad: '${d['unit'] ?? ''}'.toLowerCase(),
    esModem: modem.hasMatch(categorias[cat] ?? '') || modem.hasMatch(nombre),
  );
}

List<({String assetId, double qty})> _lista(Object? v) => [
  if (v is List)
    for (final m in v)
      if (m is Map && '${m['assetId'] ?? ''}'.isNotEmpty)
        (assetId: '${m['assetId']}', qty: num.tryParse('${m['qty'] ?? ''}')?.toDouble() ?? 0),
];

/// `svcHasMat`: el servicio lleva materiales.
bool servicioLlevaMateriales(Map<String, dynamic>? s) {
  if (s == null) return false;
  if (s['materialsOn'] is bool) return s['materialsOn'] as bool;
  return _lista(s['materials']).any((m) => m.qty > 0);
}

/// `doneByNeedsModem`: al completar se pregunta el material.
bool pideMateriales(Orden o, Map<String, dynamic>? servicio) => !o.esBaja && servicioLlevaMateriales(servicio);

/// `ticketSupplyKit`: los insumos que lleva la orden (lo guardado, o los del servicio con la cantidad de su localidad).
List<({String assetId, double qty})> insumosDeLaOrden(Orden o, Map<String, dynamic>? servicio, CatalogoMateriales cat) {
  final usados = o.datos['materialsUsed'];
  if (usados is List && usados.isNotEmpty) return _lista(usados);
  final porZona = cat.insumosPorZona[o.zonaId] ?? const {};
  return [
    for (final m in _lista(servicio?['materials']))
      if (m.qty > 0 && !(cat.activo(m.assetId)?.esModem ?? true))
        (assetId: m.assetId, qty: porZona[m.assetId] ?? m.qty),
  ];
}

/// La casilla «Lleva insumos» viene marcada si ya se guardaron, o en servicios nuevos y cambios de domicilio (`supNewSvc`).
bool insumosMarcados(Orden o, Map<String, dynamic>? servicio) {
  final usados = o.datos['materialsUsed'];
  if (usados is List && usados.isNotEmpty) return true;
  final nombre = plano(servicio?['name'] ?? o.datos['serviceName'] ?? '');
  final comision = servicio?['commission'];
  return (comision is bool ? comision : RegExp('nuev').hasMatch(nombre)) ||
      RegExp('nuev|cambio de domicilio').hasMatch(nombre);
}

/// Lo que se guarda en la orden al completarla: quién la completó, el módem (`modemId` vacío = ninguno) y los insumos
/// (null si la orden no pide materiales; [] si la casilla de insumos está desmarcada).
Map<String, Object?> datosMateriales({
  required String userId,
  required String nombre,
  String? modemId,
  List<({String assetId, double qty})>? insumos,
}) => {
  'completedByTechId': userId,
  'completedByTechName': nombre,
  if (modemId != null) 'modemUse': modemId.isEmpty ? {'none': true} : {'assetId': modemId, 'condition': 'nuevo'},
  if (insumos != null)
    'materialsUsed': [
      for (final i in insumos)
        if (i.assetId.isNotEmpty && i.qty > 0)
          {'assetId': i.assetId, 'qty': i.qty == i.qty.roundToDouble() ? i.qty.toInt() : i.qty},
    ],
};

/// Gasto en pantalla, como `doneBySupTotal`: el módem nuevo y los insumos (cantidad × precio).
({double modem, double insumos}) gastoMateriales(
  CatalogoMateriales cat, {
  required String modemId,
  required List<({String assetId, double qty})> insumos,
}) {
  double r2(double v) => (v * 100).round() / 100;
  final modem = modemId.isEmpty ? 0.0 : (cat.activo(modemId)?.precio ?? 0);
  final ins = insumos.fold(0.0, (s, i) => s + i.qty * (cat.activo(i.assetId)?.precio ?? 0));
  return (modem: r2(modem), insumos: r2(ins));
}
