import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Teléfonos de cualquier país, como el campo de teléfono de la web (libphonenumber): se elige el país (bandera y lada),
/// se escribe el número y se guarda en formato internacional («+52 993 123 4567»). El campo no es obligatorio.

/// Bandera del país con sus dos letras («MX» → 🇲🇽).
String bandera(String iso) =>
    iso.length == 2 ? String.fromCharCodes(iso.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41)) : '';

/// Lada internacional del país («MX» → «52»); vacío si el país no existe.
String ladaDe(String iso) {
  final codigo = IsoCode.values.where((c) => c.name == iso.toUpperCase()).firstOrNull;
  if (codigo == null) return '';
  try {
    return PhoneNumber.parse('1', destinationCountry: codigo).countryCode;
  } catch (_) {
    return '';
  }
}

IsoCode? _iso(String iso) => IsoCode.values.where((c) => c.name == iso.toUpperCase()).firstOrNull;

/// El número listo para guardar: «» si está vacío, el internacional si es válido para ese país, o null si no lo es.
/// Escrito con «+» de otro país no vale (como la web: hay que cambiar el país).
String? telefonoInternacional(String texto, String iso) {
  final limpio = texto.trim();
  if (limpio.replaceAll(RegExp(r'\D'), '').isEmpty) return '';
  try {
    final n = limpio.startsWith('+') ? PhoneNumber.parse(limpio) : PhoneNumber.parse(limpio, callerCountry: _iso(iso));
    if (!n.isValid() || n.isoCode.name != iso.toUpperCase()) return null;
    // como formatInternational de la web: «+1 213 373 4253», no «+1 (213) 373-4253»
    return '+${n.countryCode} ${_conEspacios(n)}';
  } catch (_) {
    return null;
  }
}

/// País y número local de un teléfono guardado («+52 993 123 4567» → MX y «993 123 4567»); null si no trae «+».
({String iso, String local})? separarTelefono(String guardado) {
  final v = guardado.trim();
  if (!v.startsWith('+')) return null;
  try {
    final n = PhoneNumber.parse(v);
    return (iso: n.isoCode.name, local: _conEspacios(n));
  } catch (_) {
    return null;
  }
}

/// El número local separado con espacios, como `formatInternational` de la web («213 373 4253», sin guiones ni paréntesis).
String _conEspacios(PhoneNumber n) =>
    n.formatNsn(format: NsnFormat.international).replaceAll(RegExp(r'[-().]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
