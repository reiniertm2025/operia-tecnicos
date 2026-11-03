import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/modems.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import 'comun.dart';
import 'diseno.dart';

/// Pago de comisiones (solo el administrador, solo ver): lo que gana cada comisionista en el periodo por las instalaciones
/// que consiguió y los módems que recuperó (también los de Importados ISP), y si la oficina ya se lo entregó. Es Reportes ›
/// Pago de comisiones de la web; las comisiones las cobran los comisionistas, no los usuarios de la app.
/// Se filtra por fechas, por localidad (o todas) y por comisionista (o todos); los totales de arriba siguen el filtro.
class PantallaComisiones extends StatefulWidget {
  const PantallaComisiones({super.key, required this.servicio, required this.nombresZonas});

  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaComisiones> createState() => _PantallaComisionesState();
}

class _PantallaComisionesState extends State<PantallaComisiones>
    with LecturaPorPeriodo<PantallaComisiones, List<Comision>> {
  String? _zona;

  /// Clave del comisionista elegido (null = todos).
  String? _quien;

  @override
  Future<List<Comision>> leer({bool recargar = false}) async {
    final r = fijarRango();
    final todo = await Future.wait<Object>([
      widget.servicio.comisionesDelPeriodo(r.desde, r.hastaExclusivo, recargar: recargar),
      widget.servicio.nombresParaComisiones(),
      widget.servicio.comisiones().catchError((_) => const <Map<String, dynamic>>[]),
    ]);
    final o = todo[0] as ({List<Orden> ordenes, List<Orden> isp});
    final quien = todo[1] as ({Map<String, String> comisionistas, Map<String, String> usuarios});
    return pagoDeComisiones(
      ordenes: o.ordenes,
      isp: o.isp,
      comisiones: todo[2] as List<Map<String, dynamic>>,
      comisionistas: quien.comisionistas,
      usuarios: quien.usuarios,
      desde: r.desde,
      hastaExclusivo: r.hastaExclusivo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Scaffold(
      body: FutureBuilder(
        future: carga,
        builder: (context, foto) {
          final deZona = [
            for (final c in foto.data ?? const <Comision>[])
              if (_zona == null || c.orden.zonaId == _zona) c,
          ];
          final grupos = porComisionista(deZona);
          final quien = grupos.any((g) => g.filas.first.clave == _quien) ? _quien : null;
          final lista = [
            for (final c in deZona)
              if (quien == null || c.clave == quien) c,
          ];
          final Widget cuerpo;
          if (foto.hasError) {
            cuerpo = errorDelPeriodo(t, foto.error!);
          } else if (foto.data == null) {
            cuerpo = const ListaEsqueleto();
          } else {
            var posicion = 0;
            cuerpo = listaDelPeriodo(t, [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(t.comNota, style: Theme.of(context).textTheme.bodySmall),
              ),
              if (grupos.length > 1) _filtroComisionistas(t, grupos, quien),
              if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: AvisoCentral(icono: Icons.savings_outlined, texto: t.comVacio),
                ),
              for (final g in porComisionista(lista)) ...[
                TituloSeccion(
                  texto: t.comDeQuien(
                    g.quien.isEmpty ? t.comSinNombre : g.quien,
                    dinero(context, totalComisiones(g.filas)),
                  ),
                  cuantas: g.filas.length,
                ),
                for (final c in g.filas) _fila(t, c, posicion++),
              ],
            ]);
          }
          return NestedScrollView(headerSliverBuilder: (context, _) => [_encabezado(t, lista)], body: cuerpo);
        },
      ),
    );
  }

  Widget _encabezado(Textos t, List<Comision> lista) {
    final total = totalComisiones(lista);
    final porEntregar = totalComisiones(lista, entregada: false);
    final zonas = widget.nombresZonas.keys.toList();
    final conFiltro = zonas.length > 1;
    return encabezadoAzul(
      alto: 250 + (conFiltro ? 56 : 0),
      titulo: Text(t.menuComisiones),
      abajo: filtroSiHayVarias(
        t,
        zonas: zonas,
        nombres: widget.nombresZonas,
        elegida: _zona,
        alElegir: (z) => setState(() => _zona = z),
      ),
      relleno: EdgeInsets.fromLTRB(20, kToolbarHeight + 4, 20, conFiltro ? 64 : 20),
      contenido: importeConDatos(
        t.comTotalPeriodo,
        total,
        DatoCristal(texto: t.comPorEntregar, valor: dinero(context, porEntregar), color: const Color(0xFFFBBF24)),
        DatoCristal(
          texto: t.comEntregadas,
          valor: dinero(context, total - porEntregar),
          color: const Color(0xFF34D399),
        ),
      ),
    );
  }

  /// Todos los comisionistas o uno, cada uno con lo que gana en el periodo (y la localidad elegida).
  Widget _filtroComisionistas(Textos t, List<({String quien, List<Comision> filas})> grupos, String? elegido) {
    Widget chip(String texto, bool marcado, String? clave) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(texto), selected: marcado, onSelected: (_) => setState(() => _quien = clave)),
    );
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
        children: [
          chip(t.comTodos, elegido == null, null),
          for (final g in grupos)
            chip(
              t.comDeQuien(g.quien.isEmpty ? t.comSinNombre : g.quien, dinero(context, totalComisiones(g.filas))),
              elegido == g.filas.first.clave,
              g.filas.first.clave,
            ),
        ],
      ),
    );
  }

  Widget _fila(Textos t, Comision c, int posicion) {
    final colores = Theme.of(context).colorScheme;
    final o = c.orden;
    final (icono, color, tipo) = switch (c.tipo) {
      TipoComision.instalacion => (Icons.wifi_rounded, const Color(0xFF2563EB), t.comTipoInstalacion),
      TipoComision.modem => (Icons.inventory_2_rounded, const Color(0xFF7C3AED), t.comTipoModem),
      TipoComision.modemIsp => (Icons.inventory_2_outlined, const Color(0xFF0891B2), t.comTipoIsp),
    };
    final fecha = c.fecha;
    return Aparecer(
      orden: posicion,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Superficie(
          radio: 18,
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClienteYDetalle(
                  orden: o,
                  detalle: [
                    tipo,
                    if (o.folio.isNotEmpty) o.folio,
                    if (fecha != null) fechaCorta(context, textoDia(fecha)),
                  ].join(' · '),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    c.importe == null ? t.comSinImporte : dinero(context, c.importe!),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: c.importe == null ? colores.onSurfaceVariant : null,
                    ),
                  ),
                  Text(
                    c.entregada ? t.comEntregada : t.comPorEntregar,
                    style: TextStyle(
                      color: c.entregada ? const Color(0xFF059669) : const Color(0xFFD97706),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
