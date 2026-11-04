import 'package:cloud_firestore/cloud_firestore.dart';

import 'orden.dart';

/// Qué guarda cada acción del técnico en `tickets/{id}`. Copia lo que hace la web (src/legacy/app.js), para que
/// la oficina vea lo mismo venga de donde venga el cambio.

/// Quién hizo el cambio (`changedBy` de la web).
Map<String, Object?> cambiadoPor(String userId, String nombre) => {
  'lastChangedById': userId,
  'lastChangedByName': nombre,
  'lastChangedAt': FieldValue.serverTimestamp(),
};

/// Tomar una orden pendiente sin técnico: igual que cuando la oficina la asigna (queda en proceso a su nombre).
/// Si es para otro día, todavía no cuenta como iniciada.
Map<String, Object?> datosAlTomar(Orden o, String userId, String nombre, String hoy) {
  final ahora = FieldValue.serverTimestamp();
  return {
    'assignedTechId': userId,
    'assignedTechName': nombre,
    'assignedAt': ahora,
    'assignedById': userId,
    'assignedByName': nombre,
    'status': 'en_proceso',
    if (o.datos.containsKey('estado')) 'estado': 'en_proceso',
    if (!o.iniciada && !(o.dia.compareTo(hoy) > 0)) 'startedAt': ahora,
    ...cambiadoPor(userId, nombre),
  };
}

/// «Empezar»: marca la hora de inicio (la web la muestra como «Iniciada»).
Map<String, Object?> datosAlEmpezar(Orden o, String userId, String nombre) => {
  if (o.estado != 'en_proceso') 'status': 'en_proceso',
  if (o.estado != 'en_proceso' && o.datos.containsKey('estado')) 'estado': 'en_proceso',
  'startedAt': FieldValue.serverTimestamp(),
  ...cambiadoPor(userId, nombre),
};

/// El administrador regresa la orden a «Pendiente» o «En proceso», como los botones de estado de la web (`.statusBtn`):
/// se borra la fecha de culminación; a «Pendiente» además se quita el técnico asignado y la hora de inicio, y a
/// «En proceso» se marca el inicio si no tenía. «Completada» va por el mismo camino que «Terminé» (con cobro si lleva).
Map<String, Object?> datosCambioEstado(Orden o, String estado, String userId, String nombre) => {
  'status': estado,
  if (o.datos.containsKey('estado')) 'estado': estado,
  'completedAt': null,
  if (estado == 'pendiente') ...{'assignedTechId': '', 'assignedTechName': '', 'startedAt': null},
  if (estado == 'en_proceso' && !o.iniciada) 'startedAt': FieldValue.serverTimestamp(),
  ...cambiadoPor(userId, nombre),
};

Map<String, Object?> datosComentarios(String texto, String userId, String nombre) => {
  'techComments': texto.trim(),
  ...cambiadoPor(userId, nombre),
};

/// «Terminé» sin cobro (reparación, baja o servicio que no cobra): se completa como con el botón de estado de la web,
/// que limpia el cobro si había. Las que llevan cobro pasan por la pantalla de cobro (logica/cobro.dart).
Map<String, Object?> datosAlTerminar(Orden o, String userId, String nombre) {
  final ahora = FieldValue.serverTimestamp();
  final d = o.datos;
  final habiaCobro =
      d['paymentMethod'] != null ||
      d['payAuthStatus'] != null ||
      (d['chargeItems'] is List && (d['chargeItems'] as List).isNotEmpty) ||
      d['chargeAmount'] != null;
  return {
    'status': 'completada',
    if (d.containsKey('estado')) 'estado': 'completada',
    'completedAt': ahora,
    if (!o.iniciada) 'startedAt': ahora,
    if (habiaCobro) ...{
      'paymentMethod': null,
      'payAuthStatus': null,
      'chargeItems': <Object>[],
      'chargeAmount': null,
      'chargeName': '',
      'billable': false,
    },
    ...cambiadoPor(userId, nombre),
  };
}
