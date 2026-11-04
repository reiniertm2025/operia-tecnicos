import 'dart:isolate';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../logica/contrasena.dart';
import '../logica/errores.dart';
import 'ordenes.dart';

/// Quien inició sesión: su id en `users`, su nombre, su rol y sus localidades.
class Tecnico {
  const Tecnico({
    required this.userId,
    required this.nombre,
    this.zonas = const [],
    this.rol = '',
    this.esAdmin = false,
    this.soloMirar = false,
    this.terminosAceptados = '',
  });
  final String userId;
  final String nombre;

  /// Localidades donde trabaja (`zoneIds`, o `zoneId` en fichas viejas), como las lee la web.
  final List<String> zonas;

  /// Nombre del rol (p. ej. «Técnico», «Administrador»).
  final String rol;

  /// Su rol tiene el permiso `admin` de la web: ve todas las localidades y puede crear órdenes.
  final bool esAdmin;

  /// Rol de consulta (permiso `consultor` de la web): ve, pero no aparta IPs.
  final bool soloMirar;

  /// Versión de los términos y condiciones que aceptó (`appTermsVersion` en su ficha); vacío si nunca los aceptó.
  final String terminosAceptados;

  /// Lo que cambia lo que ve en la app (no cuenta los términos): si cambia, la pantalla principal se arma de nuevo.
  String get firma => [userId, nombre, rol, esAdmin, soloMirar, ...zonas].join('|');
}

List<String> zonasDeUsuario(Map<String, dynamic> usuario) {
  final lista = usuario['zoneIds'];
  if (lista is List) {
    final ids = [
      for (final z in lista)
        if (z is String && z.isNotEmpty) z,
    ];
    if (ids.isNotEmpty) return ids;
  }
  final una = usuario['zoneId'];
  return una is String && una.isNotEmpty ? [una] : const [];
}

/// Inicio de sesión igual que la web Torrexi (ver CLAUDE.md):
/// appLogin/{usuario} → PBKDF2 → Firebase Auth → appAuth/{uid} → users/{userId} → roles/{role}.
class Sesion {
  Sesion({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<Tecnico> iniciar(String usuario, String contrasena) async {
    final nombreUsuario = normalizarUsuario(usuario);
    if (nombreUsuario.isEmpty || contrasena.isEmpty) throw const ErrorDeSesion(FalloSesion.faltanDatos);
    try {
      final acceso = await _db.collection('appLogin').doc(nombreUsuario).get();
      final datos = acceso.data();
      if (datos == null || datos['email'] is! String || datos['salt'] is! String) {
        throw const ErrorDeSesion(FalloSesion.datosIncorrectos);
      }
      final algo = datos['algo'] ?? 'PBKDF2-SHA256';
      if (algo != 'PBKDF2-SHA256') throw ErrorDeSesion(FalloSesion.tipoDesconocido, '$algo');
      final sal = datos['salt'] as String;
      final vueltas = (datos['iterations'] as num?)?.toInt() ?? vueltasPorDefecto;
      // 100 000 vueltas tardan un momento: se calculan aparte para que la pantalla no se congele
      final cifrada = await Isolate.run(() => cifrarContrasena(contrasena, sal, vueltas: vueltas));
      await _auth.signInWithEmailAndPassword(email: datos['email'] as String, password: cifrada);
      final tecnico = await actual();
      if (tecnico == null) {
        await _auth.signOut();
        throw const ErrorDeSesion(FalloSesion.sinAccesoApp);
      }
      return tecnico;
    } on FirebaseException catch (e) {
      throw ErrorDeSesion(falloDeCodigo(e.code), e.code);
    }
  }

  /// Quien tiene la sesión abierta en este celular, o null si no hay o ya no tiene acceso.
  Future<Tecnico?> actual() async {
    final cuenta = _auth.currentUser;
    if (cuenta == null) return null;
    final enlace = await _db.collection('appAuth').doc(cuenta.uid).get();
    final userId = enlace.data()?['userId'];
    if (userId is! String || userId.isEmpty) return null;
    return _deFicha(userId, (await _db.collection('users').doc(userId).get()).data());
  }

  /// Cada vez que la oficina cambia su ficha en la web (localidades, rol, nombre o acceso), el técnico al día; null si
  /// le quitaron el acceso. Escucha solo su documento de `users` (una lectura por cambio): al cambiar el permiso de un
  /// rol, la web también lo escribe en la ficha de cada usuario con ese rol. No repite lo que ya se leyó al entrar.
  Stream<Tecnico?> cambios(Tecnico antes) {
    var ultimo = antes;
    return _db
        .collection('users')
        .doc(antes.userId)
        .snapshots()
        .skip(1)
        // sin señal, que no esté en el teléfono no quiere decir que se borró
        .where((s) => s.exists || !s.metadata.isFromCache)
        .asyncMap((s) async {
          final nuevo = await _deFicha(antes.userId, s.data(), anterior: ultimo);
          if (nuevo != null) ultimo = nuevo;
          return nuevo;
        });
  }

  /// `anterior`: si no se puede leer el rol (sin señal), se conservan los permisos que ya tenía en vez de perderlos.
  Future<Tecnico?> _deFicha(String userId, Map<String, dynamic>? usuario, {Tecnico? anterior}) async {
    if (usuario == null || usuario['appAccess'] == false) return null;
    // como la web (name || username): un nombre vacío no cuenta
    final nombre = [
      usuario['name'],
      usuario['username'],
    ].map((v) => '${v ?? ''}'.trim()).firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final rolId = (usuario['role'] ?? '').toString();
    var rol = <String, dynamic>{};
    var leido = true;
    if (rolId.isNotEmpty) {
      try {
        rol = (await _db.collection('roles').doc(rolId).get()).data() ?? {};
      } on FirebaseException {
        // sin el rol entra como técnico (o, si ya estaba dentro, con lo que tenía)
        leido = false;
      }
    }
    final previo = leido ? null : anterior;
    return Tecnico(
      userId: userId,
      nombre: nombre,
      zonas: zonasDeUsuario(usuario),
      rol: previo?.rol ?? (rol['name'] ?? rolId).toString(),
      esAdmin: previo?.esAdmin ?? rol['permission'] == 'admin',
      soloMirar: previo?.soloMirar ?? rol['permission'] == 'consultor',
      terminosAceptados: '${usuario['appTermsVersion'] ?? ''}',
    );
  }

  /// Guarda en su ficha que aceptó los términos (versión y fecha). Sin señal queda guardado en el teléfono y se sube después.
  Future<void> aceptarTerminos(Tecnico t, String version) => ServicioOrdenes.seguro(
    () => _db
        .collection('users')
        .doc(t.userId)
        .update({'appTermsVersion': version, 'appTermsAcceptedAt': FieldValue.serverTimestamp()})
        .timeout(ServicioOrdenes.espera, onTimeout: () {}),
  );

  Future<void> cerrar() => _auth.signOut();
}
