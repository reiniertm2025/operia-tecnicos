import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/contrasena.dart';
import 'package:operia_tecnicos/logica/sistema.dart';
import 'package:operia_tecnicos/logica/usuarios.dart';
import 'package:operia_tecnicos/servicios/ordenes.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';
import 'package:operia_tecnicos/servicios/usuarios.dart';

/// Cuentas de Firebase de mentira: anota lo que se pidió.
class _Cuentas implements CuentasApp {
  final hechas = <String, String>{};
  final pasos = <String>[];
  @override
  Future<String> crear(String correo, String clave) async {
    hechas[correo] = clave;
    pasos.add('crear');
    return 'uid${hechas.length}';
  }

  @override
  Future<void> cambiarClave(String correo, String vieja, String nueva) async {
    expect(hechas[correo], vieja);
    hechas[correo] = nueva;
    pasos.add('cambiar');
  }

  @override
  Future<void> quitar(String correo, String clave) async {
    if (hechas[correo] == clave) hechas.remove(correo);
    pasos.add('quitar');
  }
}

DatosUsuario _datos({
  String nombre = 'Juan Pérez',
  String? telefono = '',
  String correo = '',
  String rol = 'tec',
  bool asalariado = false,
  double? sueldo,
  bool acceso = true,
  String usuario = 'juan',
  String contrasena = 'secreta123',
  List<String> zonas = const ['Paraíso'],
}) => (
  nombre: nombre,
  telefono: telefono,
  correo: correo,
  rol: rol,
  ocupacion: '',
  zonas: zonas,
  asalariado: asalariado,
  sueldo: sueldo,
  comisionista: false,
  acceso: acceso,
  usuario: usuario,
  contrasena: contrasena,
);

void main() {
  setUpAll(FakeFirebaseFirestore.new);
  const admin = Tecnico(userId: 'a1', nombre: 'reinier', esAdmin: true);

  test('revisar: como el formulario de usuarios de la web', () {
    const otros = [
      (id: 'u2', datos: <String, dynamic>{'username': 'pedro', 'email': 'pedro@correo.com'}),
    ];
    expect(revisarUsuario(_datos(nombre: ' '), otros), FalloUsuario.faltaNombre);
    expect(revisarUsuario(_datos(telefono: null), otros), FalloUsuario.telefono);
    expect(revisarUsuario(_datos(correo: 'sin arroba'), otros), FalloUsuario.correo);
    expect(revisarUsuario(_datos(correo: 'Pedro@Correo.com'), otros), FalloUsuario.correoRepetido);
    expect(revisarUsuario(_datos(rol: ''), otros), FalloUsuario.faltaRol);
    expect(revisarUsuario(_datos(asalariado: true), otros), FalloUsuario.sueldo);
    expect(revisarUsuario(_datos(usuario: ' '), otros), FalloUsuario.faltaUsuario);
    expect(revisarUsuario(_datos(usuario: 'jo sé'), otros), FalloUsuario.usuarioFormato);
    expect(revisarUsuario(_datos(usuario: 'PEDRO'), otros), FalloUsuario.usuarioOcupado);
    expect(revisarUsuario(_datos(contrasena: ''), otros), FalloUsuario.faltaContrasena);
    expect(revisarUsuario(_datos(contrasena: 'corta'), otros), FalloUsuario.contrasenaCorta);
    expect(revisarUsuario(_datos(acceso: false, usuario: ''), otros), isNull);
    expect(revisarUsuario(_datos(correo: 'juan@correo.com'), otros), isNull);
    // al cambiar, si ya tiene acceso no hace falta otra contraseña; y su propio usuario no está «ocupado»
    expect(
      revisarUsuario(
        _datos(usuario: 'pedro', contrasena: ''),
        otros,
        antes: otros.first,
      ),
      FalloUsuario.faltaContrasena,
    );
    const conCuenta = (id: 'u2', datos: <String, dynamic>{'username': 'pedro', 'authUid': 'x'});
    expect(
      revisarUsuario(
        _datos(usuario: 'pedro', contrasena: ''),
        otros,
        antes: conCuenta,
      ),
      isNull,
    );
  });

  test('datos: permiso del rol, localidades, sueldo y contraseña como la web', () {
    final d = datosUsuario(
      _datos(asalariado: true, sueldo: 1200, usuario: ' Juan '),
      permiso: 'tecnico',
      nombresZonas: const {'Paraíso': 'Paraíso Centro'},
      secreto: (hash: 'h', sal: 's'),
    );
    expect(d['permission'], 'tecnico');
    expect(d['permissionName'], 'Técnico');
    expect((d['permissions'] as Map)['delete'], isFalse);
    expect((d['zoneId'], d['zoneName']), ('Paraíso', 'Paraíso Centro'));
    expect((d['salaryWeekly'], d['salary'], d['salaryDaily']), (1200, 5200, 200));
    expect((d['username'], d['appAccess'], d['passwordHash'], d['passwordIterations']), ('juan', true, 'h', 100000));
    expect(d['avatar'], '');
    final sinClave = datosUsuario(
      _datos(),
      permiso: 'tecnico',
      nombresZonas: const {},
      secreto: (hash: 'h', sal: 's'),
      conservarClave: false,
    );
    expect(sinClave.containsKey('passwordHash'), isFalse, reason: 'sin appLegacy la clave solo va en appSecrets');
    final cambio = datosUsuario(
      _datos(acceso: false),
      antes: (id: 'u', datos: const {'passwordHash': 'h', 'salaryWeekly': 900}),
      permiso: '',
      nombresZonas: const {},
    );
    expect(cambio['appAccess'], isFalse);
    expect(cambio.containsKey('salaryWeekly'), isFalse, reason: 'al cambiar sin sueldo, el de antes se queda');
    expect(cambio.containsKey('passwordHash'), isTrue, reason: 'se borra la contraseña vieja');
    expect(cambio.containsKey('permission'), isFalse);
  });

  test('roles: permiso obligatorio y sus usuarios toman el permiso nuevo', () {
    expect(revisarRegistro(Catalogo.roles, {'name': 'Jefe', 'permission': 'otro'}, const []), FalloSistema.permiso);
    expect(revisarRegistro(Catalogo.roles, {'name': 'Jefe', 'permission': 'admin'}, const []), isNull);
    final rol = datosRegistro(
      Catalogo.roles,
      {'name': 'Jefe', 'description': '', 'permission': 'consultor'},
      existentes: const [],
      userId: 'a1',
      nombre: 'r',
    );
    expect((rol['permissionName'], (rol['permissions'] as Map)['view']), ('Consultor', true));
    final usuarios = [
      (id: 'u1', datos: <String, dynamic>{'role': 'jefe', ...datosPermiso('tecnico')}),
      (id: 'u2', datos: <String, dynamic>{'role': 'jefe', ...datosPermiso('admin')}),
      (id: 'u3', datos: <String, dynamic>{'role': 'otro'}),
    ];
    expect([for (final u in usuariosDelRol('jefe', 'admin', usuarios)) u.id], ['u1']);
  });

  test('servicio: crea la cuenta, cambia usuario y contraseña, quita el acceso y borra a la Papelera', () async {
    final db = FakeFirebaseFirestore();
    final cuentas = _Cuentas();
    final s = ServicioUsuarios(
      ServicioOrdenes(db: db),
      db: db,
      cuentas: cuentas,
      dominio: 'prueba.web.app',
    );
    await s.guardar(_datos(), permiso: 'tecnico', nombresZonas: const {});
    final u = (await db.collection('users').get()).docs.single;
    final login = (await db.collection('appLogin').doc('juan').get()).data()!;
    expect(login['userId'], u.id);
    expect((await db.collection('appAuth').doc(u.data()['authUid']).get()).data(), {'userId': u.id});
    final secreto = (await db.collection('appSecrets').doc(u.id).get()).data()!;
    // la cuenta de Firebase usa como clave el cifrado de la contraseña, igual que al entrar
    expect(cuentas.hechas[login['email']], cifrarContrasena('secreta123', login['salt']));
    expect(secreto['passwordHash'], cuentas.hechas[login['email']]);
    expect(u.data()['uid'], u.id);

    var antes = (id: u.id, datos: (await db.collection('users').doc(u.id).get()).data()!);
    await s.guardar(
      _datos(usuario: 'juanito', contrasena: 'otra-clave-1'),
      antes: antes,
      permiso: 'tecnico',
      nombresZonas: const {},
    );
    expect((await db.collection('appLogin').doc('juan').get()).exists, isFalse);
    expect((await db.collection('appLogin').doc('juanito').get()).exists, isTrue);
    expect(cuentas.pasos, ['crear', 'cambiar']);

    antes = (id: u.id, datos: (await db.collection('users').doc(u.id).get()).data()!);
    await s.guardar(_datos(acceso: false), antes: antes, permiso: 'tecnico', nombresZonas: const {});
    expect((await db.collection('appLogin').get()).docs, isEmpty);
    expect((await db.collection('appAuth').get()).docs, isEmpty);
    expect((await db.collection('appSecrets').get()).docs, isEmpty);
    expect(cuentas.hechas, isEmpty, reason: 'se borró su cuenta de Firebase');
    final sinAcceso = (await db.collection('users').doc(u.id).get()).data()!;
    expect((sinAcceso['appAccess'], sinAcceso.containsKey('authUid')), (false, false));

    await s.borrar((id: u.id, datos: sinAcceso), admin);
    expect((await db.collection('users').doc(u.id).get()).exists, isFalse);
    expect((await db.collection('trash').get()).docs.single.data()['col'], 'users');
  });

  test('servicio: al cambiar el permiso de un rol, sus usuarios lo llevan', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('roles').doc('Jefe').set({'name': 'Jefe', ...datosPermiso('tecnico')});
    await db.collection('users').doc('u1').set({'role': 'Jefe', ...datosPermiso('tecnico')});
    final s = ServicioOrdenes(db: db);
    await s.guardarRegistro(
      Catalogo.roles,
      {'name': 'Jefe', 'description': 'Encargado', 'permission': 'admin'},
      admin,
      antes: (id: 'Jefe', datos: (await db.collection('roles').doc('Jefe').get()).data()!),
      existentes: const [],
    );
    expect((await db.collection('roles').doc('Jefe').get()).data()!['permissionName'], 'Administrador del Sistema');
    expect((await db.collection('users').doc('u1').get()).data()!['permission'], 'admin');
  });
}
