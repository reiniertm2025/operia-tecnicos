import 'package:flutter_test/flutter_test.dart';
import 'package:operia_tecnicos/logica/avisos.dart';
import 'package:operia_tecnicos/logica/orden.dart';
import 'package:operia_tecnicos/servicios/sesion.dart';

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

  test('avisa cuando le asignan una orden (nueva o que ya estaba)', () {
    final v = Vigia(tecnico)..revisar([orden('a')]);
    final avisos = v.revisar([orden('a', tecnico: 'u1'), orden('d', zona: 'Otra', tecnico: 'u1')]);
    expect(avisos.map((a) => (a.orden.id, a.tipo)), [('a', TipoAviso.asignada), ('d', TipoAviso.asignada)]);
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
}
