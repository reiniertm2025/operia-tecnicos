import '../servicios/sesion.dart';
import 'sistema.dart';

/// Qué ve cada quien en el menú (☰). Decisión del dueño (3 nov 2026): el técnico (o el de consulta) solo atiende sus
/// órdenes —crearlas, aceptarlas y culminarlas, con sus inconclusas— y ve Herramientas › IPs libres, la Ayuda y lo
/// demás de la app. Todo lo del jefe (Dashboard, Nuevos Servicios, Cancelados, Finanzas, Pago de comisiones, Recuperar
/// módem, Por autorizar, Mapa del día) es solo del administrador.

enum OpcionMenu {
  dashboard,
  delDia,
  mapaDia,
  historico,
  inconclusas,
  futuro,
  nsPendientes,
  facturaIsp,
  prospectos,
  nsHistorico,
  ncNuevos,
  tvCable,
  tvDoblePlay,
  definitivos,
  temporales,
  modems,
  finanzas,
  porAutorizar,
  comisiones,
  sisUsuarios,
  sisRoles,
  sisOcupaciones,
  sisLocalidades,
  sisFechasPago,
  sisZonas,
  sisServicios,
  sisComisiones,
  sisComisionistas,
  sisActivos,
  sisInsumos,
  sisMotivosCancelacion,
  sisCobros,
  sisFormasPago,
  sisPartidasGasto,
  ips,
}

/// Grupos que se abren y cierran, como el menú de la web; null = la opción va suelta.
enum GrupoMenu {
  ordenesTrabajo,
  nuevosServicios,
  cancelados,
  recuperarModem,
  finanzas,
  reportes,
  sistema,
  herramientas,
}

typedef SeccionMenu = ({GrupoMenu? grupo, List<OpcionMenu> opciones});

List<SeccionMenu> menuPara(Tecnico t) => t.esAdmin
    ? const [
        (grupo: null, opciones: [OpcionMenu.dashboard]),
        (
          grupo: GrupoMenu.ordenesTrabajo,
          opciones: [OpcionMenu.delDia, OpcionMenu.mapaDia, OpcionMenu.historico, OpcionMenu.inconclusas],
        ),
        (
          grupo: GrupoMenu.nuevosServicios,
          opciones: [
            OpcionMenu.futuro,
            OpcionMenu.nsPendientes,
            OpcionMenu.facturaIsp,
            OpcionMenu.prospectos,
            OpcionMenu.nsHistorico,
          ],
        ),
        (
          grupo: GrupoMenu.cancelados,
          opciones: [
            OpcionMenu.ncNuevos,
            OpcionMenu.tvCable,
            OpcionMenu.tvDoblePlay,
            OpcionMenu.definitivos,
            OpcionMenu.temporales,
          ],
        ),
        (grupo: GrupoMenu.recuperarModem, opciones: [OpcionMenu.modems]),
        (grupo: GrupoMenu.finanzas, opciones: [OpcionMenu.finanzas, OpcionMenu.porAutorizar]),
        (grupo: GrupoMenu.reportes, opciones: [OpcionMenu.comisiones]),
        (
          grupo: GrupoMenu.sistema,
          opciones: [
            OpcionMenu.sisUsuarios,
            OpcionMenu.sisRoles,
            OpcionMenu.sisOcupaciones,
            OpcionMenu.sisLocalidades,
            OpcionMenu.sisFechasPago,
            OpcionMenu.sisZonas,
            OpcionMenu.sisServicios,
            OpcionMenu.sisComisiones,
            OpcionMenu.sisComisionistas,
            OpcionMenu.sisActivos,
            OpcionMenu.sisInsumos,
            OpcionMenu.sisMotivosCancelacion,
            OpcionMenu.sisCobros,
            OpcionMenu.sisFormasPago,
            OpcionMenu.sisPartidasGasto,
          ],
        ),
        (grupo: GrupoMenu.herramientas, opciones: [OpcionMenu.ips]),
      ]
    : const [
        (grupo: null, opciones: [OpcionMenu.inconclusas]),
        (grupo: GrupoMenu.herramientas, opciones: [OpcionMenu.ips]),
      ];

/// Si la opción le toca (para no abrir pantallas del jefe por otro camino).
bool puedeVer(Tecnico t, OpcionMenu o) => menuPara(t).any((s) => s.opciones.contains(o));

/// La lista de Sistema que abre cada opción (null si no es de Sistema).
Catalogo? catalogoDe(OpcionMenu o) => switch (o) {
  OpcionMenu.sisUsuarios => Catalogo.usuarios,
  OpcionMenu.sisRoles => Catalogo.roles,
  OpcionMenu.sisOcupaciones => Catalogo.ocupaciones,
  OpcionMenu.sisLocalidades => Catalogo.localidades,
  OpcionMenu.sisFechasPago => Catalogo.fechasPago,
  OpcionMenu.sisZonas => Catalogo.zonas,
  OpcionMenu.sisServicios => Catalogo.servicios,
  OpcionMenu.sisComisiones => Catalogo.comisiones,
  OpcionMenu.sisComisionistas => Catalogo.comisionistas,
  OpcionMenu.sisActivos => Catalogo.activos,
  OpcionMenu.sisInsumos => Catalogo.insumos,
  OpcionMenu.sisMotivosCancelacion => Catalogo.motivosCancelacion,
  OpcionMenu.sisCobros => Catalogo.cobros,
  OpcionMenu.sisFormasPago => Catalogo.formasPago,
  OpcionMenu.sisPartidasGasto => Catalogo.partidasGasto,
  _ => null,
};
