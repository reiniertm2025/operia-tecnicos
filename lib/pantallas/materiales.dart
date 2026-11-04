import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/materiales.dart';
import '../logica/orden.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'diseno.dart';

/// Ventana de materiales al completar (como «¿Quién la completó?» de la web): el módem que se instaló y los insumos que se
/// usaron. Devuelve lo que se guarda en la orden (`datosMateriales`), o null si se regresa sin continuar.
/// El gasto (precio de Activos) solo lo ve el administrador.
class PantallaMateriales extends StatefulWidget {
  const PantallaMateriales({
    super.key,
    required this.orden,
    required this.servicio,
    required this.catalogo,
    required this.tecnico,
  });

  final Orden orden;

  /// El servicio de la orden (`services/{serviceType}`).
  final Map<String, dynamic>? servicio;
  final CatalogoMateriales catalogo;
  final Tecnico tecnico;

  @override
  State<PantallaMateriales> createState() => _PantallaMaterialesState();
}

class _Fila {
  _Fila(this.assetId, double qty) : cantidad = TextEditingController(text: qty > 0 ? _texto(qty) : '');
  String assetId;
  final TextEditingController cantidad;

  double get qty => double.tryParse(cantidad.text.trim().replaceAll(',', '.')) ?? 0;

  static String _texto(double v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}

class _PantallaMaterialesState extends State<PantallaMateriales> {
  late final _modems = widget.catalogo.modemsPara(widget.servicio);

  /// Módem elegido ('' = ninguno) y la pestaña abierta (null = Ninguno).
  String _modem = '';
  String? _pestana;
  late bool _conInsumos = insumosMarcados(widget.orden, widget.servicio);
  late final List<_Fila> _filas = [
    for (final i in insumosDeLaOrden(widget.orden, widget.servicio, widget.catalogo)) _Fila(i.assetId, i.qty),
  ];
  late final bool _sinPredeterminados = _filas.isEmpty;

  @override
  void initState() {
    super.initState();
    if (_filas.isEmpty) _filas.add(_Fila('', 0));
  }

  @override
  void dispose() {
    for (final f in _filas) {
      f.cantidad.dispose();
    }
    super.dispose();
  }

  List<({String assetId, double qty})> get _insumos => [
    for (final f in _filas)
      if (f.assetId.isNotEmpty) (assetId: f.assetId, qty: f.qty),
  ];

  void _continuar() {
    // como la web: las filas sin insumo o sin cantidad no se guardan
    Navigator.pop(
      context,
      datosMateriales(
        userId: widget.tecnico.userId,
        nombre: widget.tecnico.nombre,
        modemId: _modem,
        insumos: _conInsumos ? _insumos : const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final o = widget.orden;
    return Scaffold(
      appBar: AppBar(title: Text(t.matTitulo)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          ClienteYDetalle(orden: o, detalle: [o.folio, o.servicio].where((x) => x.isNotEmpty).join(' · ')),
          const SizedBox(height: 8),
          Text(t.matExplica, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          _seccion(t.matModem, _modemElegir(t)),
          const SizedBox(height: 12),
          _seccion(t.matInsumos, _insumosElegir(t), interruptor: true),
          if (widget.tecnico.esAdmin) ...[const SizedBox(height: 12), _gasto(t)],
        ],
      ),
      bottomNavigationBar: BarraInferior(
        child: BotonPrincipal(
          texto: t.matContinuar,
          icono: Icons.arrow_forward_rounded,
          ocupado: false,
          alTocar: _continuar,
        ),
      ),
    );
  }

  Widget _seccion(String titulo, Widget hijo, {bool interruptor = false}) => Superficie(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (interruptor)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            value: _conInsumos,
            onChanged: (v) => setState(() => _conInsumos = v),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        hijo,
      ],
    ),
  );

  /// «Ninguno» y una pestaña por categoría de Activos; en la pestaña abierta, sus módems.
  Widget _modemElegir(Textos t) {
    final abierta = _modems.where((m) => m.id == _pestana).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.block_rounded, size: 18),
              label: Text(t.matModemNinguno),
              selected: _modem.isEmpty,
              onSelected: (_) => setState(() {
                _modem = '';
                _pestana = null;
              }),
            ),
            for (final m in _modems)
              ChoiceChip(
                label: Text('${m.nombre} (${m.activos.length})'),
                selected: _pestana == m.id,
                onSelected: (_) => setState(() => _pestana = m.id),
              ),
          ],
        ),
        if (_modem.isEmpty && abierta == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.matModemNingunoSub, style: Theme.of(context).textTheme.bodySmall),
          ),
        if (abierta != null)
          RadioGroup<String>(
            groupValue: _modem,
            onChanged: (v) => setState(() => _modem = v ?? ''),
            child: Column(
              children: [
                for (final a in abierta.activos)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: a.id,
                    title: Text(a.nombre),
                    subtitle: widget.tecnico.esAdmin && a.precio > 0 ? Text(dinero(context, a.precio)) : null,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _insumosElegir(Textos t) {
    if (!_conInsumos) return const SizedBox.shrink();
    final opciones = widget.catalogo.insumos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_sinPredeterminados)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(t.matSinPred, style: const TextStyle(color: Color(0xFFB45309))),
          ),
        for (final f in _filas)
          Padding(
            key: ObjectKey(f),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: f.assetId.isEmpty || widget.catalogo.activo(f.assetId) == null ? null : f.assetId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.matInsumoElige, isDense: true),
                    items: [
                      for (final a in opciones)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(a.nombre, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => f.assetId = v ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                // la cantidad comparte el ancho con el insumo: caben 3 cifras y la unidad («150 metro»)
                Expanded(
                  child: TextField(
                    controller: f.cantidad,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.end,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: t.matCantidad,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      suffixText: widget.catalogo.activo(f.assetId)?.unidad,
                      suffixStyle: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t.matQuitar,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    setState(() => _filas.remove(f));
                    WidgetsBinding.instance.addPostFrameCallback((_) => f.cantidad.dispose());
                  },
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() => _filas.add(_Fila('', 0))),
          icon: const Icon(Icons.add_rounded),
          label: Text(t.matAgregar),
        ),
      ],
    );
  }

  /// Gasto de materiales (solo el administrador), como el total de la web.
  Widget _gasto(Textos t) {
    final g = gastoMateriales(widget.catalogo, modemId: _modem, insumos: _conInsumos ? _insumos : const []);
    Widget linea(String texto, double v, {bool fuerte = false}) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(texto, style: TextStyle(fontWeight: fuerte ? FontWeight.w700 : null)),
          ),
          Text(dinero(context, v), style: TextStyle(fontWeight: fuerte ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
    return Superficie(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        children: [
          linea(t.matGastoModem, g.modem),
          linea(t.matGastoInsumos, g.insumos),
          const Divider(height: 16),
          linea(t.matTotal, g.modem + g.insumos, fuerte: true),
        ],
      ),
    );
  }
}
