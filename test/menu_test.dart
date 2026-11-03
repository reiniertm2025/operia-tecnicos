import 'package:flutter_test/flutter_test.dart';
import 'package:torrexi_tecnicos/logica/menu.dart';
import 'package:torrexi_tecnicos/servicios/sesion.dart';

void main() {
  const tecnico = Tecnico(userId: 'u1', nombre: 'Portela', zonas: ['Tecolutilla']);
  const consulta = Tecnico(userId: 'u2', nombre: 'Ana', soloMirar: true);
  const admin = Tecnico(userId: 'a1', nombre: 'reinier', esAdmin: true);

  List<OpcionMenu> todas(Tecnico t) => [for (final s in menuPara(t)) ...s.opciones];

  test('el técnico solo ve lo suyo: inconclusas y Herramientas › IPs libres', () {
    expect(todas(tecnico), [OpcionMenu.inconclusas, OpcionMenu.ips]);
    expect(menuPara(tecnico).map((s) => s.grupo), [null, GrupoMenu.herramientas]);
    // nada del jefe
    for (final o in [
      OpcionMenu.dashboard,
      OpcionMenu.finanzas,
      OpcionMenu.comisiones,
      OpcionMenu.modems,
      OpcionMenu.prospectos,
      OpcionMenu.porAutorizar,
      OpcionMenu.mapaDia,
    ]) {
      expect(puedeVer(tecnico, o), isFalse, reason: '$o es del administrador');
      expect(puedeVer(consulta, o), isFalse, reason: '$o es del administrador');
    }
  });

  test('el administrador ve todo, en grupos como la web', () {
    expect(todas(admin).toSet(), OpcionMenu.values.toSet());
    expect(menuPara(admin).map((s) => s.grupo), [
      null,
      GrupoMenu.ordenesTrabajo,
      GrupoMenu.nuevosServicios,
      GrupoMenu.cancelados,
      GrupoMenu.recuperarModem,
      GrupoMenu.finanzas,
      GrupoMenu.reportes,
      GrupoMenu.sistema,
      GrupoMenu.herramientas,
    ]);
  });
}
