import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/avisos.dart';
import 'package:torrexi_tecnicos/logica/orden.dart';
import 'package:torrexi_tecnicos/servicios/sesion.dart';

void main() {
  const tecnico = Tecnico(userId: 'u1', nombre: 'Portela', zonas: ['Tecolutilla']);
  const admin = Tecnico(userId: 'a1', nombre: 'reinier', esAdmin: true);
  Orden orden(String id, {String zona = 'Tecolutilla', String? tecnico, String estado = 'pendiente'}) =>
      Orden(id, {'status': estado, 'zoneId': zona, 'assignedTechId': ?tecnico});

  test('la primera foto no avisa; después avisa las nuevas de sus localidades', () {
    final v = Vigia(tecnico);
    expect(v.revisar([orden('a')]), isEmpty);
    final avisos = v.revisar([orden('a'), orden('b'), orden('c', zona: 'Otra')]);
    expect(avisos.map((a) => (a.orden.id, a.tipo)), [('b', TipoAviso.nueva)]);
    expect(v.pendientes, 2);
    // la misma foto otra vez no repite el aviso
    expect(v.revisar([orden('a'), orden('b')]), isEmpty);
  });

  test('una orden nueva que ya viene a su nombre avisa «asignada»; asignarle una que ya estaba no avisa', () {
    final v = Vigia(tecnico)..revisar([orden('a')]);
    final avisos = v.revisar([orden('a', tecnico: 'u1'), orden('d', zona: 'Otra', tecnico: 'u1')]);
    expect(avisos.map((a) => (a.orden.id, a.tipo)), [('d', TipoAviso.asignada)]);
  });

  test('solo avisa nuevas y las que regresan de estado (no cuando avanzan)', () {
    final encendido = DateTime(2026, 11, 3, 9);
    Orden vieja(String id, String estado) =>
        Orden(id, {'status': estado, 'zoneId': 'Tecolutilla', 'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1))});
    Orden recien(String id) =>
        Orden(id, {'status': 'pendiente', 'zoneId': 'Tecolutilla', 'createdAt': Timestamp.fromDate(encendido)});
    final v = Vigia(admin, desde: encendido)..revisar([vieja('a', 'pendiente')]);
    // de pendiente a en proceso: avanza, no avisa
    expect(v.revisar([vieja('a', 'en_proceso')], hoy: '2026-11-03'), isEmpty);
    // una creada con el aviso encendido es nueva; una vieja que aparece regresó de Completada
    final avisos = v.revisar([
      vieja('a', 'en_proceso'),
      recien('n'),
      vieja('c', 'en_proceso'),
      vieja('p', 'pendiente'),
    ], hoy: '2026-11-03');
    expect(avisos.map((a) => (a.orden.id, a.tipo)), [
      ('n', TipoAviso.nueva),
      ('c', TipoAviso.regreso),
      ('p', TipoAviso.regreso),
    ]);
    // que se complete (sale de las abiertas) no avisa
    expect(v.revisar([recien('n')], hoy: '2026-11-03'), isEmpty);
  });

  test('no avisa órdenes de otro técnico; el administrador ve todas', () {
    final v = Vigia(tecnico)..revisar(const []);
    expect(v.revisar([orden('e', tecnico: 'u2')]), isEmpty);
    final a = Vigia(admin)..revisar(const []);
    expect(a.revisar([orden('e', tecnico: 'u2'), orden('f', zona: 'Otra')]).length, 2);
  });

  test('avisa cuando la oficina regresa a pendiente una orden que estaba en proceso', () {
    final v = Vigia(admin)..revisar([orden('a', estado: 'en_proceso', tecnico: 'u2'), orden('b')]);
    final avisos = v.revisar([orden('a'), orden('b')]);
    expect(avisos.map((a) => (a.orden.id, a.tipo)), [('a', TipoAviso.regreso)]);
    // el técnico al que se la quitaron también se entera, si es de su localidad
    final t = Vigia(tecnico)..revisar([orden('c', estado: 'en_proceso', tecnico: 'u1')]);
    expect(t.revisar([orden('c')]).map((a) => a.tipo), [TipoAviso.regreso]);
  });

  test('al posponer para otro día no avisa «regresó»', () {
    final v = Vigia(admin)..revisar([orden('a', estado: 'en_proceso', tecnico: 'u2')]);
    final pospuesta = Orden('a', const {'status': 'pendiente', 'zoneId': 'Tecolutilla', 'workDate': '2026-11-09'});
    expect(v.revisar([pospuesta], hoy: '2026-11-02'), isEmpty);
  });

  test('solo avisa de las localidades marcadas, también al administrador (sin ninguna marcada, de todas)', () {
    const adminTeco = Tecnico(userId: 'a2', nombre: 'Julio', esAdmin: true, zonas: ['Tecolutilla']);
    final v = Vigia(adminTeco)..revisar(const []);
    expect(v.revisar([orden('x', zona: 'Comalcalco'), orden('y')]).map((a) => a.orden.id), ['y']);
    final t = Vigia(tecnico)..revisar(const []);
    expect(t.revisar([orden('z', zona: 'Comalcalco')]), isEmpty);
    expect(t.revisar([orden('z', zona: 'Comalcalco', tecnico: 'u1')]).map((a) => a.tipo), [TipoAviso.asignada]);
  });

  test('el número del aviso fijo cuenta las pendientes como la pestaña, aunque avise solo de sus localidades', () {
    // administrador con localidades marcadas: suena solo por las suyas, pero el número cuenta todas las pendientes
    const jefe = Tecnico(userId: 'a1', nombre: 'reinier', esAdmin: true, zonas: ['Tecolutilla']);
    final v = Vigia(jefe)..revisar(const []);
    final avisos = v.revisar([orden('a'), orden('b', zona: 'Otra'), orden('c', zona: 'Otra', estado: 'en_proceso')]);
    expect(avisos.map((a) => a.orden.id), ['a']);
    expect(v.pendientes, 2);
    // técnico: las suyas y las sin técnico de sus localidades, como su pestaña
    final t = Vigia(tecnico)..revisar(const []);
    t.revisar([
      orden('a'),
      orden('b', zona: 'Otra'),
      orden('d', zona: 'Otra', tecnico: 'u1'),
      orden('e', tecnico: 'u2'),
    ]);
    expect(t.pendientes, 2);
  });
}
