import '../servicios/sesion.dart';

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
  ips,
}

/// Grupos que se abren y cierran, como el menú de la web; null = la opción va suelta.
enum GrupoMenu { ordenesTrabajo, nuevosServicios, cancelados, recuperarModem, finanzas, reportes, herramientas }

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
        (grupo: GrupoMenu.herramientas, opciones: [OpcionMenu.ips]),
      ]
    : const [
        (grupo: null, opciones: [OpcionMenu.inconclusas]),
        (grupo: GrupoMenu.herramientas, opciones: [OpcionMenu.ips]),
      ];

/// Si la opción le toca (para no abrir pantallas del jefe por otro camino).
bool puedeVer(Tecnico t, OpcionMenu o) => menuPara(t).any((s) => s.opciones.contains(o));
