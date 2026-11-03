import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/textos.dart';
import '../logica/ips.dart';
import '../servicios/ips.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'diseno.dart';

/// IPs libres que publicó la oficina para las localidades del técnico. Se aparta la que se va a usar (queda «Ocupada»
/// con su nombre, en la web también) y se libera si ya no hace falta.
class PantallaIps extends StatefulWidget {
  const PantallaIps({super.key, required this.tecnico, required this.nombresZonas, this.servicio});

  final Tecnico tecnico;
  final Map<String, String> nombresZonas;
  final ServicioIps? servicio;

  @override
  State<PantallaIps> createState() => _PantallaIpsState();
}

class _PantallaIpsState extends State<PantallaIps> {
  late final ServicioIps _servicio = widget.servicio ?? ServicioIps();
  late final Stream<List<SegmentoIp>> _segmentos = _servicio.segmentos(widget.tecnico);
  final _enCurso = <String>{};
  String? _zona;
  String? _vlan;
  final _marcados = <String>{};
  MostrarIps _mostrar = MostrarIps.libres;
  String _buscar = '';

  /// La misma IP puede estar en dos localidades: se distingue por su segmento.
  static String _clave(FilaIp f) => '${f.segmento.id}|${f.ip}';

  String _nombreZona(String id) => widget.nombresZonas[id] ?? id;

  Future<void> _cambiar(FilaIp f, {required bool apartar}) async {
    final t = Textos.of(context);
    final si = await confirmar(
      context,
      icono: apartar ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
      titulo: apartar ? t.ipsApartarPregunta(f.ip) : t.ipsLiberarPregunta(f.ip),
      texto: apartar ? t.ipsApartarTexto : t.ipsLiberarTexto,
      boton: apartar ? t.ipsApartar : t.ipsLiberar,
    );
    if (!si || !mounted) return;
    setState(() => _enCurso.add(_clave(f)));
    final avisos = ScaffoldMessenger.of(context);
    try {
      if (apartar) {
        await _servicio.apartar(f.segmento, f.ip, widget.tecnico);
      } else {
        await _servicio.liberar(f.segmento, f.ip, widget.tecnico);
      }
      avisos.showSnackBar(SnackBar(content: Text(apartar ? t.ipsApartadaOk(f.ip) : t.ipsLiberadaOk(f.ip))));
    } on ErrorDeOrden catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(textoFalloOrden(t, e))));
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(t.errOtro('$e'))));
    } finally {
      if (mounted) setState(() => _enCurso.remove(_clave(f)));
    }
  }

  Future<void> _copiar(String ip) async {
    final t = Textos.of(context);
    final avisos = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: ip));
    avisos.showSnackBar(SnackBar(content: Text(t.ipsCopiada(ip))));
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return StreamBuilder<List<SegmentoIp>>(
      stream: _segmentos,
      builder: (context, foto) {
        final todos = ordenarSegmentos(foto.data ?? const [], widget.nombresZonas);
        final zonas = {for (final s in todos) s.zonaId}.toList();
        final zona = zonas.contains(_zona) ? _zona : null;
        final deZona = [
          for (final s in todos)
            if (zona == null || s.zonaId == zona) s,
        ];
        final vlanes = {for (final s in deZona) s.vlan}.toList()..sort(compararNumerico);
        // con una sola VLAN no hace falta escogerla
        final vlan = vlanes.length == 1 ? vlanes.first : (vlanes.contains(_vlan) ? _vlan : null);
        final deVlan = [
          for (final s in deZona)
            if (vlan == null || s.vlan == vlan) s,
        ];
        final marcados = {for (final s in deVlan) s.id}.intersection(_marcados);
        final elegidos = [
          for (final s in deVlan)
            if (marcados.isEmpty || marcados.contains(s.id)) s,
        ];
        int cuantas(MostrarIps m) => filasIp(elegidos, userId: widget.tecnico.userId, mostrar: m).length;
        final filas = filasIp(elegidos, userId: widget.tecnico.userId, mostrar: _mostrar, buscar: _buscar);
        final Widget cuerpo;
        final cargando = cargaOError(t, foto);
        if (cargando != null) {
          cuerpo = cargando;
        } else if (todos.isEmpty) {
          cuerpo = AvisoCentral(icono: Icons.lan_outlined, texto: t.ipsVacio);
        } else {
          cuerpo = _lista(
            t,
            filas,
            filtros: _filtros(t, vlanes, vlan, vlan == null ? const [] : deVlan, marcados),
            verZona: zona == null && zonas.length > 1,
          );
        }
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [_encabezado(t, zonas, zona, elegidos, cuantas)],
            body: cuerpo,
          ),
        );
      },
    );
  }

  Widget _encabezado(
    Textos t,
    List<String> zonas,
    String? zona,
    List<SegmentoIp> elegidos,
    int Function(MostrarIps) cuantas,
  ) {
    final conFiltro = zonas.length > 1;
    final fechas = [for (final s in elegidos) ?s.arpEn]..sort();
    Widget total(String texto, MostrarIps m, Color color) => TotalCristal(
      texto: texto,
      cuantas: cuantas(m),
      color: color,
      elegido: _mostrar == m,
      alTocar: () => setState(() => _mostrar = m),
    );
    return encabezadoAzul(
      alto: 236 + (conFiltro ? 56 : 0),
      titulo: Text(t.menuIps),
      abajo: conFiltro
          ? filtroZonas(
              t,
              zonas: zonas,
              nombres: widget.nombresZonas,
              elegida: zona,
              alElegir: (z) => setState(() {
                _zona = z;
                _vlan = null;
                _marcados.clear();
              }),
            )
          : null,
      relleno: EdgeInsets.fromLTRB(20, kToolbarHeight + 4, 20, conFiltro ? 64 : 18),
      contenido: [
        Text(t.ipsDescripcion, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3)),
        if (fechas.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            t.ipsRouter(fechaHora(context, fechas.last)),
            style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 13),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            total(t.ipsLibres, MostrarIps.libres, const Color(0xFF34D399)),
            const SizedBox(width: 8),
            total(t.ipsOcupadas, MostrarIps.ocupadas, const Color(0xFFFBBF24)),
            const SizedBox(width: 8),
            total(t.ipsMias, MostrarIps.mias, const Color(0xFF7DD3FC)),
            const SizedBox(width: 8),
            total(t.ipsTodas, MostrarIps.todas, Colors.white),
          ],
        ),
      ],
    );
  }

  Widget _lista(Textos t, List<FilaIp> filas, {required Widget filtros, required bool verZona}) {
    // título de cada segmento seguido de sus IPs
    final grupos = <SegmentoIp, List<FilaIp>>{};
    for (final f in filas) {
      (grupos[f.segmento] ??= []).add(f);
    }
    final renglones = <Widget>[
      filtros,
      if (filas.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: AvisoCentral(icono: Icons.search_off_rounded, texto: t.ipsSinFiltro),
        ),
      for (final MapEntry(key: s, value: lista) in grupos.entries) ...[
        TituloSeccion(
          texto: [if (verZona) _nombreZona(s.zonaId), t.ipsVlan(s.vlan), s.etiqueta].join(' · '),
          cuantas: lista.length,
        ),
        for (var i = 0; i < lista.length; i++)
          _FilaIp(
            key: ValueKey('${s.id}-${lista[i].ip}'),
            fila: lista[i],
            tecnico: widget.tecnico,
            ocupado: _enCurso.contains(_clave(lista[i])),
            posicion: i,
            alApartar: () => _cambiar(lista[i], apartar: true),
            alLiberar: () => _cambiar(lista[i], apartar: false),
            alCopiar: () => _copiar(lista[i].ip),
          ),
      ],
    ];
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      itemCount: renglones.length,
      itemBuilder: (context, i) => renglones[i],
    );
  }

  /// Buscador, VLAN (una o todas) y, dentro de la VLAN, los segmentos que se quieran ver (uno o varios).
  Widget _filtros(Textos t, List<String> vlanes, String? vlan, List<SegmentoIp> segmentos, Set<String> marcados) {
    final estiloTitulo = Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (v) => setState(() => _buscar = v),
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: t.ipsBuscar),
          ),
          if (vlanes.length > 1) ...[
            const SizedBox(height: 14),
            Text(t.ipsFiltroVlan, style: estiloTitulo),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in <String?>[null, ...vlanes])
                  ChoiceChip(
                    label: Text(v == null ? t.ipsTodasVlan : t.ipsVlan(v)),
                    selected: vlan == v,
                    onSelected: (_) => setState(() {
                      _vlan = v;
                      _marcados.clear();
                    }),
                  ),
              ],
            ),
          ],
          if (segmentos.length > 1) ...[
            const SizedBox(height: 14),
            Text(t.ipsFiltroSegmentos, style: estiloTitulo),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in segmentos)
                  FilterChip(
                    label: Text(
                      [
                        s.etiqueta,
                        t.ipsCuantasLibres(s.libres.where((ip) => s.apartadaDe(ip) == null).length),
                      ].join(' · '),
                    ),
                    selected: marcados.contains(s.id),
                    onSelected: (si) => setState(() => si ? _marcados.add(s.id) : _marcados.remove(s.id)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Una IP: libre (verde) u ocupada (ámbar, tachada, con quién la apartó), con copiar y apartar o liberar.
class _FilaIp extends StatelessWidget {
  const _FilaIp({
    super.key,
    required this.fila,
    required this.tecnico,
    required this.ocupado,
    required this.posicion,
    required this.alApartar,
    required this.alLiberar,
    required this.alCopiar,
  });

  final FilaIp fila;
  final Tecnico tecnico;
  final bool ocupado;
  final int posicion;
  final VoidCallback alApartar;
  final VoidCallback alLiberar;
  final VoidCallback alCopiar;

  static const _verde = Color(0xFF10B981);
  static const _ambar = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final colores = Theme.of(context).colorScheme;
    final a = fila.apartada;
    final color = a == null ? _verde : _ambar;
    final estado = a == null
        ? t.ipsLibre
        : [
            t.ipsOcupada,
            if (a.porNombre.isNotEmpty) a.porNombre,
            a.desdeApp ? t.ipsDesdeApp : t.ipsDesdeWeb,
            if (a.dia.isNotEmpty) fechaCorta(context, a.dia),
          ].join(' · ');
    final Widget accion;
    if (ocupado) {
      accion = const SizedBox(
        width: 40,
        height: 40,
        child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    } else if (a == null && !tecnico.soloMirar) {
      accion = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _ambar,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: alApartar,
        icon: const Icon(Icons.back_hand_rounded, size: 18),
        label: Text(t.ipsApartar),
      );
    } else if (a != null && !tecnico.soloMirar && puedeLiberar(a, tecnico.userId, esAdmin: tecnico.esAdmin)) {
      accion = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
        onPressed: alLiberar,
        icon: const Icon(Icons.undo_rounded, size: 18),
        label: Text(t.ipsLiberar),
      );
    } else {
      accion = const SizedBox.shrink();
    }
    return Aparecer(
      orden: posicion,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Superficie(
          radio: 18,
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a == null ? Icons.lan_rounded : Icons.lock_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        fila.ip,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: a == null ? null : colores.onSurfaceVariant,
                          decoration: a == null ? null : TextDecoration.lineThrough,
                          decorationColor: _ambar,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      estado,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(tooltip: t.ipsCopiar, onPressed: alCopiar, icon: const Icon(Icons.copy_rounded, size: 20)),
              AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: accion),
            ],
          ),
        ),
      ),
    );
  }
}
