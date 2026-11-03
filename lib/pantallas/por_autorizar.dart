import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'detalle_orden.dart';
import 'diseno.dart';

/// Cobros que esperan que la oficina los autorice (Finanzas › Pendientes de pago de la web). Solo se ven: se autorizan
/// en la web.
class PantallaPorAutorizar extends StatefulWidget {
  const PantallaPorAutorizar({super.key, required this.tecnico, required this.servicio, required this.nombresZonas});

  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaPorAutorizar> createState() => _PantallaPorAutorizarState();
}

class _PantallaPorAutorizarState extends State<PantallaPorAutorizar> {
  late Stream<List<Orden>> _lista = widget.servicio.porAutorizar();

  void _abrir(Orden o, String hero) => abrirDetalle(
    context,
    o,
    hero: hero,
    tecnico: widget.tecnico,
    servicio: widget.servicio,
    zonas: widget.nombresZonas,
  );

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.menuPorAutorizar)),
      body: StreamBuilder<List<Orden>>(
        stream: _lista,
        builder: (context, foto) {
          if (foto.hasError) {
            return AvisoCentral(icono: Icons.cloud_off_rounded, texto: textoErrorCarga(t, foto.error!));
          }
          final lista = foto.data;
          if (lista == null) return const ListaEsqueleto();
          return listaRecargable(
            alRecargar: () async => setState(() => _lista = widget.servicio.porAutorizar(recargar: true)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(t.autNota, style: Theme.of(context).textTheme.bodySmall),
              ),
              if (lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: AvisoCentral(icono: Icons.verified_rounded, texto: t.autVacio),
                ),
              for (var i = 0; i < lista.length; i++)
                TarjetaOrden(
                  key: ValueKey(lista[i].id),
                  orden: lista[i],
                  zona: widget.nombresZonas[lista[i].zonaId] ?? lista[i].zonaId,
                  verTecnico: true,
                  hero: heroDe('autorizar', lista[i]),
                  posicion: i,
                  alTocar: () => _abrir(lista[i], heroDe('autorizar', lista[i])),
                ),
            ],
          );
        },
      ),
    );
  }
}
