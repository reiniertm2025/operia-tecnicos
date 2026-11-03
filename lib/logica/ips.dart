import 'orden.dart';

/// IPs libres que publica el administrador desde la web (Herramientas › IPs libres › «Publicar en la app»).
/// Cada documento de `ipSegments` es un segmento (192.168.88.x) de una VLAN de una localidad, con sus IPs libres según el
/// ARP del router (`free`) y las apartadas (`taken.<ip con _>` = { byId, byName, day, at, from }), como en la web.

/// Quién apartó una IP.
class Apartado {
  const Apartado({required this.porId, required this.porNombre, required this.dia, required this.desdeApp});

  factory Apartado.deMapa(Map<String, dynamic> m) => Apartado(
    porId: '${m['byId'] ?? ''}',
    porNombre: '${m['byName'] ?? ''}',
    dia: '${m['day'] ?? ''}',
    desdeApp: m['from'] == 'app',
  );

  final String porId;
  final String porNombre;

  /// Día en que la apartó (AAAA-MM-DD).
  final String dia;
  final bool desdeApp;
}

class SegmentoIp {
  SegmentoIp(this.id, Map<String, dynamic> d)
    : segmento = '${d['segment'] ?? ''}',
      etiqueta = '${d['label'] ?? d['segment'] ?? ''}',
      vlan = '${d['vlan'] ?? ''}',
      zonaId = '${d['zoneId'] ?? ''}',
      arpEn = DateTime.tryParse('${d['arpAt'] ?? ''}'),
      libres = [
        for (final ip in (d['free'] is List ? d['free'] as List : const []))
          if (ip is String && ip.isNotEmpty) ip,
      ],
      apartadas = {
        if (d['taken'] is Map)
          for (final e in (d['taken'] as Map).entries)
            if (e.value is Map) '${e.key}': Apartado.deMapa(Map<String, dynamic>.from(e.value as Map)),
      };

  final String id;
  final String segmento;

  /// Como lo ve el técnico: «192.168.88.x».
  final String etiqueta;
  final String vlan;
  final String zonaId;

  /// Cuándo generó el router el ARP de esta lista.
  final DateTime? arpEn;
  final List<String> libres;

  /// Por clave de IP (`claveIp`).
  final Map<String, Apartado> apartadas;

  Apartado? apartadaDe(String ip) => apartadas[claveIp(ip)];
}

/// La web guarda cada IP apartada con los puntos cambiados por guiones bajos («192_168_88_5»).
String claveIp(String ip) => ip.replaceAll('.', '_');

enum MostrarIps { libres, ocupadas, mias, todas }

class FilaIp {
  const FilaIp(this.ip, this.segmento, this.apartada);
  final String ip;
  final SegmentoIp segmento;
  final Apartado? apartada;
}

/// Compara textos con números como números («VLAN 9» antes de «VLAN 10», «…88.x» antes de «…100.x»).
int compararNumerico(String a, String b) {
  final pa = RegExp(r'\d+|\D+').allMatches(a).map((m) => m[0]!).toList();
  final pb = RegExp(r'\d+|\D+').allMatches(b).map((m) => m[0]!).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final na = int.tryParse(pa[i]), nb = int.tryParse(pb[i]);
    final c = na != null && nb != null ? na.compareTo(nb) : pa[i].compareTo(pb[i]);
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}

/// Segmentos ordenados como en la web: por localidad (en el orden de `nombresZonas`, que es el de la web), VLAN y segmento.
List<SegmentoIp> ordenarSegmentos(Iterable<SegmentoIp> segmentos, Map<String, String> nombresZonas) {
  return [...segmentos]..sort((a, b) {
    final orden = nombresZonas.keys.toList();
    int lugar(String id) => orden.contains(id) ? orden.indexOf(id) : orden.length;
    final z = lugar(a.zonaId).compareTo(lugar(b.zonaId));
    if (z != 0) return z;
    final v = compararNumerico(a.vlan, b.vlan);
    return v != 0 ? v : compararNumerico(a.segmento, b.segmento);
  });
}

/// Las IPs a mostrar con los filtros de la pantalla (la búsqueda es como la de la web: IP, segmento o «vlan20»).
List<FilaIp> filasIp(
  List<SegmentoIp> segmentos, {
  required String userId,
  String? zona,
  String? segmentoId,
  MostrarIps mostrar = MostrarIps.todas,
  String buscar = '',
}) {
  final q = plano(buscar.trim());
  return [
    for (final s in segmentos)
      if ((zona == null || s.zonaId == zona) && (segmentoId == null || s.id == segmentoId))
        for (final ip in s.libres)
          if (_seMuestra(s.apartadaDe(ip), mostrar, userId) &&
              (q.isEmpty || plano('$ip ${s.etiqueta} vlan${s.vlan}').contains(q)))
            FilaIp(ip, s, s.apartadaDe(ip)),
  ];
}

bool _seMuestra(Apartado? a, MostrarIps mostrar, String userId) => switch (mostrar) {
  MostrarIps.libres => a == null,
  MostrarIps.ocupadas => a != null,
  MostrarIps.mias => a?.porId == userId,
  MostrarIps.todas => true,
};

/// La libera quien la apartó o un administrador (como en la web).
bool puedeLiberar(Apartado a, String userId, {required bool esAdmin}) => esAdmin || a.porId == userId;

/// Lo que se guarda al apartar, igual que la web pero con `from: 'app'` (la web lo muestra como «desde la app»).
Map<String, Object?> datosApartar(String ip, String userId, String nombre, DateTime ahora) => {
  'taken.${claveIp(ip)}': {
    'byId': userId,
    'byName': nombre,
    'day': textoDia(ahora),
    'at': ahora.millisecondsSinceEpoch,
    'from': 'app',
  },
};
