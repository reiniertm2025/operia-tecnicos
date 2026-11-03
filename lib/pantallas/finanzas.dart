import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/cobro.dart';
import '../logica/finanzas.dart';
import '../logica/modems.dart';
import '../logica/orden.dart';
import '../logica/tablero.dart';
import '../servicios/ordenes.dart';
import 'comun.dart';
import 'diseno.dart';

/// Finanzas › Resumen (solo el administrador, solo ver): entradas (ingresos de servicios y cobros de órdenes), salidas
/// (gastos y comisiones) y el resultado del periodo, por localidad. Un resumen del Estado financiero de la web.
class PantallaFinanzas extends StatefulWidget {
  const PantallaFinanzas({super.key, required this.servicio, required this.nombresZonas});

  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaFinanzas> createState() => _PantallaFinanzasState();
}

typedef _Datos = ({
  List<Map<String, dynamic>> ingresos,
  List<Map<String, dynamic>> gastos,
  List<Map<String, dynamic>> partidas,
  List<Orden> ordenes,
  List<Comision> comisiones,
  Catalogos cat,
});

class _PantallaFinanzasState extends State<PantallaFinanzas> with LecturaPorPeriodo<PantallaFinanzas, _Datos> {
  String? _zona;

  @override
  Future<_Datos> leer({bool recargar = false}) async {
    final r = fijarRango();
    final s = widget.servicio;
    final todo = await Future.wait<Object>([
      s.finanzas(r.desde, r.hastaExclusivo, recargar: recargar),
      s.comisionesDelPeriodo(r.desde, r.hastaExclusivo, recargar: recargar),
      s.catalogos(),
      s.comisiones().catchError((_) => const <Map<String, dynamic>>[]),
    ]);
    final f =
        todo[0]
            as ({
              List<Map<String, dynamic>> ingresos,
              List<Map<String, dynamic>> gastos,
              List<Map<String, dynamic>> partidas,
              List<Orden> cobradas,
            });
    final o = todo[1] as ({List<Orden> ordenes, List<Orden> isp});
    return (
      ingresos: f.ingresos,
      gastos: f.gastos,
      partidas: f.partidas,
      ordenes: unirSinRepetir([o.ordenes, f.cobradas]),
      comisiones: pagoDeComisiones(
        ordenes: o.ordenes,
        isp: o.isp,
        comisiones: todo[3] as List<Map<String, dynamic>>,
        comisionistas: const {},
        desde: r.desde,
        hastaExclusivo: r.hastaExclusivo,
      ),
      cat: todo[2] as Catalogos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Scaffold(
      body: FutureBuilder(
        future: carga,
        builder: (context, foto) {
          final d = foto.data;
          final f = d == null
              ? null
              : Finanzas(
                  ingresos: d.ingresos,
                  gastos: d.gastos,
                  partidas: d.partidas,
                  ordenes: d.ordenes,
                  comisiones: d.comisiones,
                  cat: d.cat,
                  desde: rango.desde,
                  hastaExclusivo: rango.hastaExclusivo,
                  zona: _zona,
                  sinFormaDePago: t.finSinFormaPago,
                  otrosGastos: t.finOtrosGastos,
                );
          final Widget cuerpo;
          if (foto.hasError) {
            cuerpo = errorDelPeriodo(t, foto.error!);
          } else if (f == null) {
            cuerpo = const ListaEsqueleto();
          } else {
            cuerpo = listaDelPeriodo(t, [
              _caja(t.finIngresosServicios, f.ingresosServicios, f.porFormaDePago, const Color(0xFF059669)),
              _caja(
                t.finCobrosOrdenes,
                f.cobros,
                const [],
                const Color(0xFF059669),
                nota: t.finCobrosDetalle(f.cobrosCuantos),
              ),
              _caja(t.finGastos, f.gastosRegistrados, f.porPartida, const Color(0xFFE11D48)),
              _caja(
                t.finComisiones,
                f.comisionesTotal,
                const [],
                const Color(0xFFE11D48),
                nota: f.cuentanComisiones ? null : t.finComisionesNoCuentan,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(t.finNota, style: Theme.of(context).textTheme.bodySmall),
              ),
            ]);
          }
          return NestedScrollView(headerSliverBuilder: (context, _) => [_encabezado(t, f)], body: cuerpo);
        },
      ),
    );
  }

  Widget _encabezado(Textos t, Finanzas? f) => encabezadoAzul(
    alto: 226 + 56,
    titulo: Text(t.menuFinanzas),
    abajo: filtroZonas(
      t,
      zonas: widget.nombresZonas.keys.toList(),
      nombres: widget.nombresZonas,
      elegida: _zona,
      alElegir: (z) => setState(() => _zona = z),
    ),
    relleno: const EdgeInsets.fromLTRB(20, kToolbarHeight + 4, 20, 64),
    contenido: importeConDatos(
      t.finResultado,
      f?.resultado ?? 0,
      DatoCristal(texto: t.finEntradas, valor: dinero(context, f?.entradas ?? 0), color: const Color(0xFF34D399)),
      DatoCristal(texto: t.finSalidas, valor: dinero(context, f?.salidas ?? 0), color: const Color(0xFFFDA4AF)),
    ),
  );

  /// Un bloque: título y total, y abajo sus líneas (forma de pago o partida) o una nota.
  Widget _caja(String titulo, double total, List<Linea> lineas, Color color, {String? nota}) {
    final t = Textos.of(context);
    final chico = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Superficie(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  dinero(context, total),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: color),
                ),
              ],
            ),
            if (lineas.isEmpty && nota == null && total == 0) ...[
              const SizedBox(height: 6),
              Text(t.finNada, style: chico),
            ],
            for (final l in lineas)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(l.nombre)),
                    Text(dinero(context, l.importe), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if (nota != null) ...[const SizedBox(height: 6), Text(nota, style: chico)],
          ],
        ),
      ),
    );
  }
}
