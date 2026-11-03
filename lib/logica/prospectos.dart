import 'package:cloud_firestore/cloud_firestore.dart';

import 'nueva_orden.dart';
import 'orden.dart';
import 'telefono.dart';

/// Órdenes de trabajo › Prospectos, igual que la web (src/legacy/app.js: prospectForm, assignProspect,
/// linkProspectToTicket; src/features/prospects/logic.ts: dueLight). Posibles clientes de un servicio nuevo.
/// Campos de `prospects`: name, phone, address, coordinates/latitude/longitude, zoneId, photo (JPEG reducido, en el mismo
/// documento) y photoCount, comment, installDate (AAAA-MM-DD), prospectorId/prospectorName (un comisionista),
/// status ('pendiente' | 'asignado'), ticketId/ticketFolio al asignarlo. Ningún campo es obligatorio.

class Prospecto extends RegistroCliente {
  const Prospecto(super.id, super.datos);

  String _t(String c) => texto(c);
  String get coordenadas => _t('coordinates');
  String get comentario => _t('comment');
  String get diaInstalacion => _t('installDate');
  String get prospectorId => _t('prospectorId');
  String get prospectorNombre => _t('prospectorName');
  String get foto => _t('photo');
  bool get asignado => datos['status'] == 'asignado';
  String get folio => folioVisible(datos['ticketFolio']);

  /// Para «Ver en mapa» y llamar, igual que una orden.
  Orden get comoOrden => Orden(id, {
    'clientName': nombre,
    'clientPhone': telefono,
    'address': direccion,
    'coordinates': coordenadas,
    'latitude': datos['latitude'],
    'longitude': datos['longitude'],
    'zoneId': zonaId,
  });
}

/// Luz (`dueLight`): roja si la instalación es hoy o ya pasó, amarilla si es mañana; los asignados no llevan.
enum LuzProspecto { ninguna, manana, hoy }

LuzProspecto luzProspecto(Prospecto p, String hoy) {
  final d = p.diaInstalacion;
  if (p.asignado || d.isEmpty) return LuzProspecto.ninguna;
  if (d.compareTo(hoy) <= 0) return LuzProspecto.hoy;
  final h = DateTime.parse(hoy);
  return d == textoDia(DateTime(h.year, h.month, h.day + 1)) ? LuzProspecto.manana : LuzProspecto.ninguna;
}

/// Como `prospectRows`: por día de instalación (los que no tienen al final) y luego el más nuevo primero.
List<Prospecto> ordenarProspectos(Iterable<Prospecto> l) => [...l]
  ..sort((a, b) {
    String d(Prospecto p) => p.diaInstalacion.isEmpty ? '9999' : p.diaInstalacion;
    final c = d(a).compareTo(d(b));
    if (c != 0) return c;
    DateTime f(Prospecto p) =>
        p.datos['createdAt'] is Timestamp ? (p.datos['createdAt'] as Timestamp).toDate() : DateTime(2000);
    return f(b).compareTo(f(a));
  });

/// Lo escrito en el formulario.
class DatosProspecto {
  String nombre = '';
  String telefono = '';
  String pais = 'MX';
  String direccion = '';
  String coordenadas = '';
  String zonaId = '';
  String prospectorId = '';
  String prospectorNombre = '';
  String dia = '';
  String comentario = '';

  /// Foto como la guarda la web: `data:image/jpeg;base64,…` (vacía = sin foto).
  String foto = '';

  DatosProspecto();

  DatosProspecto.de(Prospecto p) {
    nombre = p.nombre;
    final tel = separarTelefono(p.telefono);
    pais = tel?.iso ?? 'MX';
    telefono = tel?.local ?? p.telefono;
    direccion = p.direccion;
    coordenadas = p.coordenadas;
    zonaId = p.zonaId;
    prospectorId = p.prospectorId;
    prospectorNombre = p.prospectorNombre;
    dia = p.diaInstalacion;
    comentario = p.comentario;
    foto = p.foto;
  }
}

enum FalloProspecto { telefono, coordenadas, diaPasado }

/// Revisa lo escrito, como el formulario de la web (la fecha no puede ser pasada, salvo que ya la tuviera).
FalloProspecto? revisarProspecto(DatosProspecto d, String hoy, {Prospecto? antes}) {
  if (telefonoInternacional(d.telefono, d.pais) == null) return FalloProspecto.telefono;
  if (coordenadas(d.coordenadas) == null) return FalloProspecto.coordenadas;
  if (d.dia.isNotEmpty && d.dia.compareTo(hoy) < 0 && d.dia != antes?.diaInstalacion) return FalloProspecto.diaPasado;
  return null;
}

/// Lo que se guarda (al crear, también status pendiente y quién lo creó).
Map<String, Object?> datosProspecto(
  DatosProspecto d, {
  Prospecto? antes,
  required String userId,
  required String nombre,
}) {
  final c = coordenadas(d.coordenadas)!;
  final fotos = (num.tryParse('${antes?.datos['photoCount'] ?? ''}') ?? 0).toInt();
  return {
    'name': d.nombre.trim(),
    'phone': telefonoInternacional(d.telefono, d.pais) ?? '',
    'address': d.direccion.trim(),
    'coordinates': c.lat == null ? '' : textoCoordenadas(c.lat!, c.lng!),
    'latitude': c.lat,
    'longitude': c.lng,
    'zoneId': d.zonaId,
    // la primera foto va en el documento; si había más (en orderPhotos, desde la web) se conservan
    'photo': d.foto,
    // la web lee las fotos 1 a photoCount-1 de orderPhotos: sin la primera, el número no cambia para no perder la última
    'photoCount': d.foto.isEmpty ? (fotos > 1 ? fotos : 0) : (fotos > 1 ? fotos : 1),
    'comment': d.comentario.trim(),
    'installDate': d.dia,
    'prospectorId': d.prospectorId,
    'prospectorName': d.prospectorId.isEmpty ? '' : d.prospectorNombre,
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedById': userId,
    'updatedByName': nombre,
    if (antes == null) ...{
      'status': 'pendiente',
      'createdAt': FieldValue.serverTimestamp(),
      'createdById': userId,
      'createdByName': nombre,
    },
  };
}

/// Al crear su orden queda «asignado» (`linkProspectToTicket`).
Map<String, Object?> datosProspectoAsignado(String ticketId, String folio, String userId, String nombre) => {
  'status': 'asignado',
  'ticketId': ticketId,
  'ticketFolio': folio,
  'assignedAt': FieldValue.serverTimestamp(),
  'assignedById': userId,
  'assignedByName': nombre,
};

/// La orden nueva con los datos del prospecto (`assignProspect`): el primer servicio nuevo, quien lo prospectó como
/// comisionista y el comentario en la descripción.
DatosOrden ordenDeProspecto(Prospecto p, CatalogosOrden cat, String Function(String) descripcion) {
  final tel = separarTelefono(p.telefono);
  final nuevo = (cat.servicios.entries.toList()..sort((a, b) => compararOrdenWeb(a.value, b.value)))
      .where((e) => tipoServicio(e.value) == TipoServicio.nuevo)
      .firstOrNull;
  return DatosOrden(pais: tel?.iso ?? 'MX')
    ..cliente = p.nombre
    ..telefono = tel?.local ?? p.telefono
    ..direccion = p.direccion
    ..coordenadas = p.coordenadas
    ..zonaId = p.zonaId.isEmpty ? null : p.zonaId
    ..servicioId = nuevo?.key
    ..comisionistaId = cat.comisionistas.any((c) => c.id == p.prospectorId) ? p.prospectorId : ''
    ..descripcion = p.comentario.isEmpty ? '' : descripcion(p.comentario);
}
