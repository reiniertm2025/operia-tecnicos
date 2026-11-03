import 'package:cloud_firestore/cloud_firestore.dart';

import 'contrasena.dart';
import 'sistema.dart';

/// Sistema › Usuarios app y Roles: lo que se revisa y se escribe, como el formulario de usuarios de la web
/// (`addUserForm`, `readAppCredentials`) y el de roles (`addRoleForm`). Las cuentas de acceso las arma el servicio
/// (`appSync` de la web).

/// Los permisos de un rol, como `PERMS` de la web. El nombre del permiso se guarda siempre en español.
const permisos = {
  'admin': (
    nombre: 'Administrador del Sistema',
    puede: {
      'view': true,
      'create': true,
      'process': true,
      'edit': true,
      'delete': true,
      'authorize': true,
      'manage': true,
    },
  ),
  'consultor': (
    nombre: 'Consultor',
    puede: {
      'view': true,
      'create': false,
      'process': false,
      'edit': false,
      'delete': false,
      'authorize': false,
      'manage': false,
    },
  ),
  'tecnico': (
    nombre: 'Técnico',
    puede: {
      'view': true,
      'create': true,
      'process': true,
      'edit': true,
      'delete': false,
      'authorize': false,
      'manage': false,
    },
  ),
};

/// `permData`: lo que se copia del permiso a un rol o a un usuario; vacío si el permiso no existe.
Map<String, Object?> datosPermiso(Object? permiso) {
  final p = permisos['${permiso ?? ''}'];
  return p == null
      ? const {}
      : {
          'permission': '$permiso',
          'permissionName': p.nombre,
          'permissions': {...p.puede},
        };
}

/// Lo escrito en el formulario de un usuario. `telefono`: ya en formato internacional, o null si no es válido.
typedef DatosUsuario = ({
  String nombre,
  String? telefono,
  String correo,
  String rol,
  String ocupacion,
  List<String> zonas,
  bool asalariado,
  double? sueldo,
  bool comisionista,
  bool acceso,
  String usuario,
  String contrasena,
});

enum FalloUsuario {
  faltaNombre,
  telefono,
  correo,
  correoRepetido,
  faltaRol,
  sueldo,
  faltaUsuario,
  usuarioFormato,
  usuarioOcupado,
  faltaContrasena,
  contrasenaCorta,
}

final _correo = RegExp(
  r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,}$",
);

/// Si ya tiene contraseña de la app (la vieja en su ficha o su cuenta de Firebase): al cambiarlo no hace falta otra.
bool tieneAcceso(Registro? u) =>
    u != null && (u.datos['passwordHash'] is String || '${u.datos['authUid'] ?? ''}'.isNotEmpty);

/// Revisa lo escrito como la web. `existentes`: todos los usuarios.
FalloUsuario? revisarUsuario(DatosUsuario d, List<Registro> existentes, {Registro? antes}) {
  if (limpiarNombre(d.nombre).isEmpty) return FalloUsuario.faltaNombre;
  if (d.telefono == null) return FalloUsuario.telefono;
  final correo = d.correo.trim();
  if (correo.isNotEmpty && !_correo.hasMatch(correo)) return FalloUsuario.correo;
  bool otro(Registro r) => r.id != antes?.id;
  if (correo.isNotEmpty &&
      existentes.any((r) => otro(r) && '${r.datos['email'] ?? ''}'.toLowerCase() == correo.toLowerCase())) {
    return FalloUsuario.correoRepetido;
  }
  if (d.rol.isEmpty) return FalloUsuario.faltaRol;
  if (d.asalariado && (d.sueldo == null || d.sueldo!.isNaN || d.sueldo! < 0)) return FalloUsuario.sueldo;
  if (!d.acceso) return null;
  final usuario = normalizarUsuario(d.usuario);
  if (usuario.isEmpty) return FalloUsuario.faltaUsuario;
  if (!RegExp(r'^[a-z0-9._-]{3,30}$').hasMatch(usuario)) return FalloUsuario.usuarioFormato;
  if (existentes.any((r) => otro(r) && '${r.datos['username'] ?? ''}'.toLowerCase() == usuario)) {
    return FalloUsuario.usuarioOcupado;
  }
  if (!tieneAcceso(antes) && d.contrasena.isEmpty) return FalloUsuario.faltaContrasena;
  if (d.contrasena.isNotEmpty && d.contrasena.length < 8) return FalloUsuario.contrasenaCorta;
  return null;
}

double _r2(num v) => (v * 100).round() / 100;

/// La contraseña cifrada de la app, como la guarda la web (`appSecrets` y, mientras dure, la ficha del usuario).
typedef SecretoApp = ({String hash, String sal});

Map<String, Object?> datosSecreto(SecretoApp s) => {
  'passwordHash': s.hash,
  'passwordSalt': s.sal,
  'passwordIterations': vueltasPorDefecto,
  'passwordAlgo': 'PBKDF2-SHA256',
};

/// Lo que se escribe en `users/{id}`, como `addUserForm` de la web. `permiso`: el del rol elegido. `secreto`: la
/// contraseña nueva cifrada (null si no se cambió). `conservarClave`: `settings/security.appLegacy` (la web todavía deja
/// la contraseña cifrada en la ficha para las apps viejas).
Map<String, Object?> datosUsuario(
  DatosUsuario d, {
  Registro? antes,
  required String permiso,
  required Map<String, String> nombresZonas,
  SecretoApp? secreto,
  bool conservarClave = true,
}) {
  final nuevo = antes == null;
  final zonas = [
    for (final z in d.zonas)
      if (z.isNotEmpty) z,
  ];
  final nombres = [for (final z in zonas) nombresZonas[z] ?? z];
  final sueldo = d.sueldo == null ? null : _r2(d.sueldo!);
  final viejaClave = antes != null && (antes.datos['passwordHash'] != null || antes.datos['passwordSalt'] != null);
  return {
    'name': d.nombre.trim(),
    'phone': d.telefono ?? '',
    'role': d.rol,
    ...datosPermiso(permiso),
    'occupation': d.ocupacion,
    // `userZoneData`
    'zoneIds': zonas,
    'zoneId': zonas.firstOrNull ?? '',
    'zoneNames': nombres,
    'zoneName': nombres.firstOrNull ?? '',
    if (d.asalariado && sueldo != null) ...{
      'salaryWeekly': sueldo,
      'salary': _r2(sueldo * 52 / 12),
      'salaryDaily': _r2(sueldo / 6),
    } else if (nuevo) ...{
      'salaryWeekly': null,
      'salary': null,
      'salaryDaily': null,
    },
    'salaried': d.asalariado,
    'commissioner': d.comisionista,
    'email': d.correo.trim(),
    if (nuevo) ...{'avatar': '', 'avatarPreset': ''},
    if (d.acceso) ...{
      'username': normalizarUsuario(d.usuario),
      'appAccess': true,
      if (secreto != null && conservarClave) ...datosSecreto(secreto),
    } else ...{
      'appAccess': false,
      if (viejaClave) ...{
        'passwordHash': FieldValue.delete(),
        'passwordSalt': FieldValue.delete(),
        'passwordIterations': FieldValue.delete(),
        'passwordAlgo': FieldValue.delete(),
      },
    },
  };
}

/// Al cambiar el permiso de un rol, la web copia el nuevo permiso a sus usuarios (`queuePermSync`): los que hay que
/// actualizar y con qué.
List<({String id, Map<String, Object?> datos})> usuariosDelRol(String rolId, Object? permiso, List<Registro> usuarios) {
  final quiere = datosPermiso(permiso);
  if (quiere.isEmpty) return const [];
  final puede = quiere['permissions'] as Map<String, bool>;
  return [
    for (final u in usuarios)
      if (u.datos['role'] == rolId &&
          !(u.datos['permission'] == permiso &&
              u.datos['permissionName'] == quiere['permissionName'] &&
              puede.entries.every((e) => (u.datos['permissions'] as Map?)?[e.key] == e.value)))
        (id: u.id, datos: quiere),
  ];
}
