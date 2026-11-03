import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/textos.dart';
import '../logica/cobro.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'campos.dart';
import 'comun.dart';
import 'diseno.dart';

/// Cobro al terminar una orden: paso 1 qué se cobró, paso 2 cómo pagó el cliente (igual que la web).
/// Devuelve true si se guardó.
class PantallaCobro extends StatefulWidget {
  const PantallaCobro({
    super.key,
    required this.orden,
    required this.catalogos,
    required this.tecnico,
    required this.servicio,
    this.comentarios,
    this.materiales,
  });

  final Orden orden;
  final Catalogos catalogos;
  final Tecnico tecnico;
  final ServicioOrdenes servicio;

  /// Comentarios escritos y sin guardar: se mandan junto con el cobro.
  final String? comentarios;

  /// Lo de la ventana de materiales (quién la completó, módem e insumos): se guarda con el cobro.
  final Map<String, Object?>? materiales;

  @override
  State<PantallaCobro> createState() => _PantallaCobroState();
}

class _PantallaCobroState extends State<PantallaCobro> with GuardarYCerrar {
  late final List<Concepto> _filas = conceptosPara(widget.orden, widget.catalogos);
  late final List<TextEditingController> _importes = [
    for (final f in _filas) TextEditingController(text: f.importe == null ? '' : f.importe!.toStringAsFixed(2)),
  ];
  late final List<TextEditingController> _notas = [for (final f in _filas) TextEditingController(text: f.nota)];
  int _paso = 1;
  FormaPago? _forma;

  /// Foto del comprobante, si eligió transferencia (`data:image/jpeg;base64,…`).
  String? _comprobante;

  @override
  void dispose() {
    for (final c in [..._importes, ..._notas]) {
      c.dispose();
    }
    super.dispose();
  }

  String _dinero(double v) => dinero(context, v);

  void _siguiente() {
    final t = Textos.of(context);
    final problema = revisarConceptos(_filas);
    if (problema != null) {
      final (fallo, fila) = problema;
      setState(
        () => error = fallo == FalloConcepto.importe ? t.errImporteCobro(fila.nombre) : t.errNotaCobro(fila.nombre),
      );
      return;
    }
    setState(() => error = null);
    if (!pideFormaPago(widget.orden, widget.catalogos, _filas)) {
      _guardar(null);
      return;
    }
    setState(() => _paso = 2);
  }

  Future<void> _guardar(FormaPago? forma) {
    final t = Textos.of(context);
    final completa = forma == null || forma == FormaPago.efectivo;
    return guardarYCerrar(
      () => widget.servicio.cobrar(
        widget.orden,
        _filas,
        forma,
        widget.tecnico,
        comentarios: widget.comentarios,
        materiales: widget.materiales,
        comprobante: _comprobante,
      ),
      listo: () => completa ? t.ordenCompletada : t.cobroEnviado,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final o = widget.orden;
    return PopScope(
      canPop: _paso == 1,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) setState(() => _paso = 1);
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            encabezadoAzul(
              alto: 170,
              titulo: Text(t.cobroTitulo),
              relleno: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 20),
              contenido: [
                Text(
                  t.cobroPaso(_paso),
                  style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _paso == 1 ? t.cobroQueSeCobro : t.cobroComoPago,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _paso / 2),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Marca.cielo),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (hijo, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                    child: hijo,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_paso), child: _paso == 1 ? _conceptos(t, o) : _formas(t)),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _barra(t),
      ),
    );
  }

  Widget _conceptos(Textos t, Orden o) {
    final cliente = o.cliente.isEmpty ? t.elCliente : o.cliente;
    final colores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            esServicioNuevo(o, widget.catalogos) ? t.cobroMarcaPlan(cliente) : t.cobroMarcaServicio(cliente),
            style: TextStyle(color: colores.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (_filas.isEmpty) AvisoCentral(icono: Icons.receipt_long_outlined, texto: t.cobroSinConceptos),
          for (var i = 0; i < _filas.length; i++) Aparecer(orden: i, child: _concepto(t, i)),
        ],
      ),
    );
  }

  Widget _concepto(Textos t, int i) {
    final f = _filas[i];
    final colores = Theme.of(context).colorScheme;
    const verde = Color(0xFF10B981);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: f.marcado ? verde.withValues(alpha: 0.08) : colores.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f.marcado ? verde : colores.outlineVariant, width: f.marcado ? 2 : 1),
          boxShadow: f.marcado ? sombra(context, 1) : null,
        ),
        child: Column(
          children: [
            Presionable(
              radio: 16,
              alTocar: () => setState(() {
                f.marcado = !f.marcado;
                error = null;
              }),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                child: Row(
                  children: [
                    Checkbox(
                      value: f.marcado,
                      activeColor: verde,
                      onChanged: (v) => setState(() {
                        f.marcado = v ?? false;
                        error = null;
                      }),
                    ),
                    Expanded(
                      child: Text(f.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                    if (!f.editable)
                      Text(
                        _dinero(f.importe ?? 0),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: f.marcado ? colores.onSurface : colores.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (f.editable && f.marcado)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _importes[i],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  decoration: InputDecoration(labelText: t.importe, prefixText: r'$ ', isDense: true),
                  onChanged: (v) => setState(() {
                    final n = double.tryParse(v);
                    f.importe = n == null ? null : (n * 100).round() / 100;
                    error = null;
                  }),
                ),
              ),
            if (f.pideNota && f.marcado)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: TextField(
                  controller: _notas[i],
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: '${t.comentarioCobro} *', isDense: true),
                  onChanged: (v) => setState(() {
                    f.nota = v;
                    error = null;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _formas(Textos t) {
    final opciones = [
      (FormaPago.efectivo, Icons.payments_rounded, t.pagoEfectivo, t.notaEfectivo, const Color(0xFF10B981)),
      (
        FormaPago.transferencia,
        Icons.account_balance_rounded,
        t.pagoTransferencia,
        t.notaTransferencia,
        const Color(0xFF0EA5E9),
      ),
      (FormaPago.pendiente, Icons.hourglass_top_rounded, t.pagoPendiente, t.notaPendiente, const Color(0xFFF59E0B)),
      (FormaPago.sinCosto, Icons.card_giftcard_rounded, t.pagoSinCosto, t.notaSinCosto, const Color(0xFF8B5CF6)),
    ];
    final colores = Theme.of(context).colorScheme;
    final marcados = _filas.where((f) => f.marcado).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (marcados.isNotEmpty)
            Aparecer(
              child: Superficie(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final f in marcados)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(f.nombre)),
                            Text(_dinero(f.importe ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    Divider(color: colores.outlineVariant),
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.total, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Text(
                          _dinero(totalConceptos(_filas)),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              for (var i = 0; i < opciones.length; i++)
                Aparecer(
                  orden: i + 1,
                  child: _tarjetaForma(opciones[i].$1, opciones[i].$2, opciones[i].$3, opciones[i].$5),
                ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _forma == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(_forma),
                    padding: const EdgeInsets.only(top: 14),
                    child: Builder(
                      builder: (context) {
                        final (_, icono, _, nota, color) = opciones.firstWhere((x) => x.$1 == _forma);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(icono, color: color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  nota,
                                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (_forma == FormaPago.transferencia) _cajaComprobante(t),
        ],
      ),
    );
  }

  /// Foto del comprobante de la transferencia: se guarda con el cobro y la oficina la ve al completar en la web.
  Widget _cajaComprobante(Textos t) {
    final foto = _comprobante;
    Future<void> elegir(ImageSource fuente) async {
      final f = await tomarFoto(fuente);
      if (!mounted || f == '') return;
      if (f == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.prosFotoError)));
      } else {
        setState(() => _comprobante = f);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Superficie(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.compTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(t.compExplica, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            if (foto != null) ...[Miniatura(foto: foto, tamano: 120), const SizedBox(height: 10)],
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => elegir(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: Text(t.prosTomarFoto),
                ),
                OutlinedButton.icon(
                  onPressed: () => elegir(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(t.prosGaleria),
                ),
                if (foto != null)
                  TextButton(onPressed: () => setState(() => _comprobante = null), child: Text(t.fotQuitar)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaForma(FormaPago forma, IconData icono, String texto, Color color) {
    final elegida = _forma == forma;
    final colores = Theme.of(context).colorScheme;
    return Presionable(
      radio: 18,
      alTocar: () => setState(() {
        _forma = forma;
        error = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: elegida ? color.withValues(alpha: 0.12) : colores.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: elegida ? color : colores.outlineVariant, width: elegida ? 2 : 1),
          boxShadow: elegida
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: -6)]
              : sombra(context, 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: elegida ? 1.15 : 1,
              duration: const Duration(milliseconds: 220),
              child: Icon(icono, size: 32, color: elegida ? color : colores.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: elegida ? color : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barra(Textos t) {
    final colores = Theme.of(context).colorScheme;
    final total = totalConceptos(_filas);
    final String boton;
    if (_paso == 1) {
      boton = pideFormaPago(widget.orden, widget.catalogos, _filas) ? t.continuar : t.completarSinCobro;
    } else {
      boton = _forma == null || _forma == FormaPago.efectivo ? t.guardarCompletar : t.enviarOficina;
    }
    return BarraInferior(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                error!,
                style: TextStyle(color: colores.error, fontWeight: FontWeight.w600),
              ),
            ),
          if (_paso == 1 && _filas.any((f) => f.marcado))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(
                    t.total,
                    style: TextStyle(color: colores.onSurfaceVariant, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  NumeroDinero(total, formato: _dinero),
                ],
              ),
            ),
          Row(
            children: [
              if (_paso == 2) ...[
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    onPressed: guardando ? null : () => setState(() => _paso = 1),
                    child: Text(t.atras),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: BotonPrincipal(
                  icono: _paso == 1 && pideFormaPago(widget.orden, widget.catalogos, _filas)
                      ? Icons.arrow_forward_rounded
                      : Icons.task_alt_rounded,
                  texto: boton,
                  ocupado: guardando,
                  alTocar: () {
                    if (_paso == 1) return _siguiente();
                    final forma = _forma;
                    if (forma == null) return setState(() => error = t.elegirFormaPago);
                    _guardar(forma);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Importe que cambia contando, para el total.
class NumeroDinero extends StatelessWidget {
  const NumeroDinero(this.valor, {super.key, required this.formato});

  final double valor;
  final String Function(double) formato;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: valor),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(formato(v), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
    );
  }
}
