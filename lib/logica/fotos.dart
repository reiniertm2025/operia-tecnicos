import 'package:cloud_firestore/cloud_firestore.dart';

import 'orden.dart';

/// Fotos de la orden, igual que la web (src/legacy/app.js: PH, phFetch, phSave, phData): hasta 6, cada una en
/// `orderPhotos/tickets__<id>_<n>` ({photo: 'data:image/jpeg;base64,…', updatedAt, byName}); la orden guarda
/// `photoCount` y `hasPhoto`. Las órdenes viejas con una sola foto la tienen en `orderPhotos/tickets__<id>`.

const maxFotos = 6;

String claveFotos(String ticketId) => 'tickets__$ticketId';

/// Cuántas fotos tiene (`phCount`).
int cuantasFotos(Orden o) => (num.tryParse('${o.datos['photoCount'] ?? ''}') ?? 0).toInt() > 0
    ? (num.tryParse('${o.datos['photoCount']}') ?? 0).toInt()
    : (o.datos['hasPhoto'] == true ? 1 : 0);

/// Una sola foto guardada a la antigua (sin `photoCount`).
bool fotoVieja(Orden o) => o.datos['hasPhoto'] == true && (num.tryParse('${o.datos['photoCount'] ?? ''}') ?? 0) == 0;

/// Lo que se escribe para pasar de `antes` a `ahora` (como `phSave`): las fotos que cambiaron, las que sobran se borran
/// (null) y la vieja sin número también; y los datos de la orden.
({Map<String, Map<String, Object?>?> fotos, Map<String, Object?> orden}) cambiosDeFotos(
  Orden o,
  List<String> antes,
  List<String> ahora, {
  required String userId,
  required String nombre,
}) {
  final clave = claveFotos(o.id);
  // la foto vieja (sin número) no está en `_0`: se escriben todas con número y luego se borra la vieja
  final guardadas = fotoVieja(o) ? const <String>[] : antes;
  final fotos = <String, Map<String, Object?>?>{
    for (var i = 0; i < ahora.length; i++)
      if (i >= guardadas.length || ahora[i] != guardadas[i])
        '${clave}_$i': {'photo': ahora[i], 'updatedAt': FieldValue.serverTimestamp(), 'byName': nombre},
    for (var i = ahora.length; i < guardadas.length; i++) '${clave}_$i': null,
    if (fotoVieja(o)) clave: null,
  };
  return (
    fotos: fotos,
    orden: {
      'hasPhoto': ahora.isNotEmpty,
      'photoCount': ahora.length,
      'lastChangedById': userId,
      'lastChangedByName': nombre,
      'lastChangedAt': FieldValue.serverTimestamp(),
    },
  );
}
