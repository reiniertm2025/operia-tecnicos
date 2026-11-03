import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/textos.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'detalle_orden.dart';

/// Mapa del día: las órdenes de hoy (pendientes y en proceso de hoy o atrasadas, y las culminadas hoy) en el mapa, con el
/// color de su estado, las mismas que ve en la pantalla principal. Mapa de calles (OpenStreetMap) o satélite (Esri),
/// como Herramientas › Mapa de la web. Tocar un punto muestra la orden.
class PantallaMapaDia extends StatefulWidget {
  const PantallaMapaDia({super.key, required this.tecnico, required this.servicio, required this.nombresZonas});

  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaMapaDia> createState() => _PantallaMapaDiaState();
}

// mismas capas que la web (src/config/origins.ts › mapTiles)
const _urlCalles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _urlSatelite = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

// centro de Tabasco, si no hay ningún punto
const _centro = LatLng(18.2, -93.2);

class _PantallaMapaDiaState extends State<PantallaMapaDia> {
  late final Stream<List<Orden>> _abiertas = widget.servicio.abiertas(widget.tecnico);
  late final Stream<List<Orden>> _culminadas = widget.servicio.culminadasHoy();
  final _mapa = MapController();
  bool _satelite = false;
  bool _centrado = false;
  Orden? _elegida;

  static Color colorDe(Orden o) => switch (o.estado) {
    'en_proceso' => const Color(0xFF4F46E5),
    'completada' => const Color(0xFF059669),
    _ => const Color(0xFFD97706),
  };

  void _verTodas(List<LatLng> puntos) {
    if (puntos.isEmpty) return;
    if (puntos.length == 1) {
      _mapa.move(puntos.first, 15);
      return;
    }
    _mapa.fitCamera(CameraFit.coordinates(coordinates: puntos, padding: const EdgeInsets.all(48), maxZoom: 16));
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final hoy = textoDia(DateTime.now());
    return EscuchaTablero(
      tecnico: widget.tecnico,
      abiertas: _abiertas,
      culminadas: _culminadas,
      builder: (context, tablero, estado) {
        final delDia = [
          for (final o in [...tablero.pendientes, ...tablero.enProceso])
            if (o.dia.isEmpty || o.dia.compareTo(hoy) <= 0) o,
          ...tablero.culminadas,
        ];
        final conLugar = [
          for (final o in delDia)
            if (o.ubicacion case final u?) (orden: o, punto: LatLng(u.lat, u.lng)),
        ];
        final sinLugar = delDia.length - conLugar.length;
        final puntos = [for (final c in conLugar) c.punto];
        if (!_centrado && !estado.cargando && puntos.isNotEmpty) {
          _centrado = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _verTodas(puntos));
        }
        final elegida = _elegida;
        return Scaffold(
          appBar: AppBar(
            title: Text(t.menuMapaDia),
            actions: [
              IconButton(
                tooltip: t.mapaCentrar,
                onPressed: () => _verTodas(puntos),
                icon: const Icon(Icons.fit_screen_rounded),
              ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapa,
                options: MapOptions(
                  initialCenter: _centro,
                  initialZoom: 10,
                  onTap: (_, _) => setState(() => _elegida = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _satelite ? _urlSatelite : _urlCalles,
                    userAgentPackageName: 'com.operia.operia_tecnicos',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final c in conLugar)
                        Marker(
                          point: c.punto,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => setState(() => _elegida = c.orden),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 44,
                              color: colorDe(c.orden),
                              shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SimpleAttributionWidget(source: Text(t.mapaCreditos)),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Leyenda(ordenes: delDia, sinLugar: sinLugar),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<bool>(
                      style: SegmentedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
                      segments: [
                        ButtonSegment(value: false, label: Text(t.mapaCalles)),
                        ButtonSegment(value: true, label: Text(t.mapaSatelite)),
                      ],
                      selected: {_satelite},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() => _satelite = s.first),
                    ),
                  ],
                ),
              ),
              if (estado.error != null)
                Center(
                  child: Card(
                    child: Padding(padding: const EdgeInsets.all(16), child: Text(textoErrorCarga(t, estado.error!))),
                  ),
                )
              else if (estado.cargando)
                const Center(child: CircularProgressIndicator())
              else if (conLugar.isEmpty)
                Center(
                  child: Card(
                    child: Padding(padding: const EdgeInsets.all(16), child: Text(t.mapaVacio)),
                  ),
                ),
              if (elegida != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: TarjetaOrden(
                    key: ValueKey(elegida.id),
                    orden: elegida,
                    zona: widget.nombresZonas[elegida.zonaId] ?? elegida.zonaId,
                    verTecnico: widget.tecnico.esAdmin,
                    hero: heroDe('mapa', elegida),
                    alTocar: () => abrirDetalle(
                      context,
                      elegida,
                      hero: heroDe('mapa', elegida),
                      tecnico: widget.tecnico,
                      servicio: widget.servicio,
                      zonas: widget.nombresZonas,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Cuántas hay de cada estado, con su color y su nombre (no solo el color), y las que no tienen ubicación.
class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.ordenes, required this.sinLugar});

  final List<Orden> ordenes;
  final int sinLugar;

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    Widget fila(Color color, String texto, int n) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_rounded, size: 16, color: color),
        const SizedBox(width: 4),
        Text('$texto: $n', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ],
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            fila(const Color(0xFFD97706), t.navPendientes, ordenes.where((o) => o.estado == 'pendiente').length),
            fila(const Color(0xFF4F46E5), t.navEnProceso, ordenes.where((o) => o.estado == 'en_proceso').length),
            fila(const Color(0xFF059669), t.navCulminadas, ordenes.where((o) => o.estado == 'completada').length),
            if (sinLugar > 0) Text(t.mapaSinUbicacion(sinLugar), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
