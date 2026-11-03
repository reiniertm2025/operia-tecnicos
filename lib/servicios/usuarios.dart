import 'dart:isolate';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../logica/contrasena.dart';
import '../logica/sistema.dart';
import '../logica/usuarios.dart';
import 'ordenes.dart';
import 'sesion.dart';

/// No se pudo crear, cambiar o quitar la cuenta de acceso a la app (la ficha del usuario sí se guardó).
class ErrorDeCuenta implements Exception {
  const ErrorDeCuenta(this.codigo);
  final String codigo;
  @override
  String toString() => codigo;
}

/// Las cuentas de Firebase Authentication de los usuarios de la app. Se hacen con una segunda conexión a Firebase para
/// no cerrar la sesión del administrador (como `secondaryAuth` de la web).
abstract class CuentasApp {
  /// Crea la cuenta y devuelve su uid.
  Future<String> crear(String correo, String clave);
  Future<void> cambiarClave(String correo, String vieja, String nueva);

  /// Borra la cuenta; si no se puede (ya no existe o la clave no coincide), no pasa nada.
  Future<void> quitar(String correo, String clave);
}

class CuentasFirebase implements CuentasApp {
  Future<FirebaseAuth> _auth() async {
    final app =
        Firebase.apps.where((a) => a.name == 'cuentas').firstOrNull ??
        await Firebase.initializeApp(name: 'cuentas', options: firebaseOptions);
    return FirebaseAuth.instanceFor(app: app);
  }

  Future<T> _conCuenta<T>(Future<T> Function(FirebaseAuth a) hacer) async {
    final a = await _auth();
    try {
      return await hacer(a);
    } on FirebaseException catch (e) {
      throw ErrorDeCuenta(e.code);
    } finally {
      try {
        await a.signOut();
      } catch (_) {}
    }
  }

  @override
  Future<String> crear(String correo, String clave) =>
      _conCuenta((a) async => (await a.createUserWithEmailAndPassword(email: correo, password: clave)).user!.uid);

  @override
  Future<void> cambiarClave(String correo, String vieja, String nueva) async {
    if (vieja.isEmpty) throw const ErrorDeCuenta('sin-clave-anterior');
    await _conCuenta((a) async {
      final c = await a.signInWithEmailAndPassword(email: correo, password: vieja);
      await c.user!.updatePassword(nueva);
    });
  }

  @override
  Future<void> quitar(String correo, String clave) async {
    if (correo.isEmpty || clave.isEmpty) return;
    try {
      await _conCuenta((a) async {
        final c = await a.signInWithEmailAndPassword(email: correo, password: clave);
        await c.user!.delete();
      });
    } on ErrorDeCuenta {
      // como `fbRemove` de la web: si no se puede, se deja
    }
  }
}

/// Sistema › Usuarios app (solo el administrador): guardar y borrar como la web, con su acceso a la app (`appSync` y
/// `appUnlink`): appLogin/{usuario}, appAuth/{uid} y appSecrets/{userId}.
class ServicioUsuarios {
  ServicioUsuarios(this._ordenes, {FirebaseFirestore? db, CuentasApp? cuentas, String? dominio})
    : _db = db ?? FirebaseFirestore.instance,
      _cuentas = cuentas ?? CuentasFirebase(),
      _dominio = dominio ?? '${firebaseOptions.projectId}.web.app';

  final ServicioOrdenes _ordenes;
  final FirebaseFirestore _db;
  final CuentasApp _cuentas;
  final String _dominio;

  static String _salNueva() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Guarda la ficha y su acceso a la app. Devuelve false si no hubo señal (la ficha se sube después; el acceso se arma
  /// cuando la web la vea, como `protectAccounts`). Lanza [ErrorDeCuenta] si la ficha se guardó pero el acceso no.
  Future<bool> guardar(
    DatosUsuario d, {
    Registro? antes,
    required String permiso,
    required Map<String, String> nombresZonas,
  }) async {
    SecretoApp? secreto;
    if (d.acceso && d.contrasena.isNotEmpty) {
      final sal = _salNueva();
      final clave = d.contrasena;
      // 100 000 vueltas tardan un momento: aparte, para que la pantalla no se congele
      secreto = (hash: await Isolate.run(() => cifrarContrasena(clave, sal)), sal: sal);
    }
    final legado = await _legado();
    final datos = datosUsuario(
      d,
      antes: antes,
      permiso: permiso,
      nombresZonas: nombresZonas,
      secreto: secreto,
      conservarClave: legado,
    );
    final col = _db.collection('users');
    final id = antes?.id ?? col.doc().id;
    var enLinea = true;
    await ServicioOrdenes.seguro(
      () =>
          (antes != null
                  ? col.doc(id).update(datos)
                  : col.doc(id).set({'uid': id, ...datos, 'createdAt': FieldValue.serverTimestamp()}))
              .timeout(ServicioOrdenes.espera, onTimeout: () => enLinea = false),
    );
    _ordenes.olvidar('users');
    if (!enLinea) return false;
    if ('${antes?.datos['authUid'] ?? ''}'.isNotEmpty || d.acceso) {
      await _sincronizar(id, antes?.datos ?? const {}, {...?antes?.datos, ...datos}, secreto, legado);
    }
    return true;
  }

  /// Quita su acceso a la app y manda la ficha a la Papelera.
  Future<bool> borrar(Registro u, Tecnico t) async {
    await _quitarAcceso(u.id, u.datos);
    return _ordenes.borrarRegistro(Catalogo.usuarios, u, t);
  }

  /// `settings/security.appLegacy`: mientras no se quite en la web, la contraseña cifrada también queda en la ficha.
  Future<bool> _legado() async {
    try {
      return (await _db.collection('settings').doc('security').get()).data()?['appLegacy'] != false;
    } catch (_) {
      return true;
    }
  }

  Future<Map<String, dynamic>?> _secreto(String id) async {
    try {
      return (await _db.collection('appSecrets').doc(id).get()).data();
    } catch (_) {
      return null;
    }
  }

  /// `appSync` de la web.
  Future<void> _sincronizar(
    String id,
    Map<String, dynamic> antes,
    Map<String, Object?> ahora,
    SecretoApp? secreto,
    bool legado,
  ) async {
    final usuario = '${ahora['username'] ?? ''}';
    if (ahora['appAccess'] != true || usuario.isEmpty) return _quitarAcceso(id, antes);
    final viejo = antes['passwordHash'] is String
        ? {'passwordHash': antes['passwordHash'], 'passwordSalt': antes['passwordSalt']}
        : await _secreto(id);
    final nuevo = secreto != null ? datosSecreto(secreto) : viejo;
    final hash = nuevo?['passwordHash'];
    if (hash is! String) return;
    var correo = '${antes['authEmail'] ?? ''}';
    var uid = '${antes['authUid'] ?? ''}';
    try {
      if (uid.isEmpty) {
        correo = 'a-${_salNueva().substring(0, 16)}@app.$_dominio';
        uid = await _cuentas.crear(correo, hash);
      } else if (secreto != null && viejo?['passwordHash'] != secreto.hash) {
        await _cuentas.cambiarClave(correo, '${viejo?['passwordHash'] ?? ''}', secreto.hash);
      }
    } on FirebaseException catch (e) {
      throw ErrorDeCuenta(e.code);
    }
    final sal = '${nuevo!['passwordSalt'] ?? ''}';
    final vueltas = nuevo['passwordIterations'] ?? vueltasPorDefecto;
    final algo = nuevo['passwordAlgo'] ?? 'PBKDF2-SHA256';
    final lote = _db.batch()
      ..set(_db.collection('appSecrets').doc(id), {
        'passwordHash': hash,
        'passwordSalt': sal,
        'passwordIterations': vueltas,
        'passwordAlgo': algo,
      })
      ..set(_db.collection('appAuth').doc(uid), {'userId': id});
    final usuarioAntes = '${antes['username'] ?? ''}';
    if ('${antes['authUid'] ?? ''}'.isNotEmpty && usuarioAntes.isNotEmpty && usuarioAntes != usuario) {
      lote.delete(_db.collection('appLogin').doc(usuarioAntes));
    }
    lote.set(_db.collection('appLogin').doc(usuario), {
      'email': correo,
      'salt': sal,
      'iterations': vueltas,
      'algo': algo,
      'userId': id,
    });
    final cambio = <String, Object?>{
      if (antes['authUid'] != uid || antes['authEmail'] != correo) ...{'authUid': uid, 'authEmail': correo},
      if (!legado && (ahora['passwordHash'] is String || antes['passwordHash'] is String)) ...{
        'passwordHash': FieldValue.delete(),
        'passwordSalt': FieldValue.delete(),
        'passwordIterations': FieldValue.delete(),
        'passwordAlgo': FieldValue.delete(),
      },
    };
    if (cambio.isNotEmpty) lote.update(_db.collection('users').doc(id), cambio);
    try {
      await lote.commit();
    } on FirebaseException catch (e) {
      throw ErrorDeCuenta(e.code);
    }
  }

  /// `appUnlink` de la web: borra su usuario de la app, su enlace, su contraseña cifrada y su cuenta de Firebase.
  Future<void> _quitarAcceso(String id, Map<String, dynamic> u) async {
    final secreto = await _secreto(id);
    final uid = '${u['authUid'] ?? ''}';
    final usuario = '${u['username'] ?? ''}';
    Future<void> borrar(String col, String doc) async {
      if (doc.isEmpty) return;
      try {
        await _db.collection(col).doc(doc).delete();
      } catch (_) {}
    }

    await Future.wait([
      if (uid.isNotEmpty) borrar('appLogin', usuario),
      borrar('appAuth', uid),
      borrar('appSecrets', id),
    ]);
    if (uid.isEmpty) return;
    final clave = secreto?['passwordHash'] ?? (u['passwordHash'] is String ? u['passwordHash'] : '');
    await _cuentas.quitar('${u['authEmail'] ?? ''}', '$clave');
    try {
      await _db.collection('users').doc(id).update({'authUid': FieldValue.delete(), 'authEmail': FieldValue.delete()});
    } catch (_) {}
  }
}
