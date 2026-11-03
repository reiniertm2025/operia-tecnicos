import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/sistema.dart';
import '../logica/usuarios.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'comun.dart';
import 'diseno.dart';

/// Agregar o cambiar un registro de Sistema (solo el administrador), con los mismos campos que el formulario de la web.
/// Borrar lo manda a la Papelera de la web. Devuelve true si se guardó o se borró.
class PantallaFormCatalogo extends StatefulWidget {
  const PantallaFormCatalogo({
    super.key,
    required this.catalogo,
    required this.titulo,
    required this.servicio,
    required this.tecnico,
    required this.nombresZonas,
    required this.existentes,
    this.registro,
    this.categorias = const {},
    this.comisiones = const [],
  });

  final Catalogo catalogo;
  final String titulo;
  final ServicioOrdenes servicio;
  final Tecnico tecnico;
  final Map<String, String> nombresZonas;
  final List<Registro> existentes;

  /// null = nuevo.
  final Registro? registro;

  /// Categorías de Activos (id → nombre) y Comisiones, para elegir.
  final Map<String, String> categorias;
  final List<Registro> comisiones;

  @override
  State<PantallaFormCatalogo> createState() => _PantallaFormCatalogoState();
}

class _PantallaFormCatalogoState extends State<PantallaFormCatalogo> with GuardarYCerrar {
  late final _campos = camposDe(widget.catalogo);
  late final Map<String, Object?> _v = {
    for (final c in _campos) c.clave: widget.registro?.datos[c.clave] ?? _vacio(c.tipo),
  };
  late final Map<String, TextEditingController> _textos = {
    for (final c in _campos)
      if (const {TipoCampo.texto, TipoCampo.largo, TipoCampo.numero, TipoCampo.dia}.contains(c.tipo))
        c.clave: TextEditingController(text: '${_v[c.clave] ?? ''}'),
  };

  static Object? _vacio(TipoCampo t) => switch (t) {
    TipoCampo.siNo => false,
    TipoCampo.localidades || TipoCampo.comisiones => const <String>[],
    _ => null,
  };

  @override
  void dispose() {
    for (final c in _textos.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Lo que no se cambia al editar (ver `camposFijos`).
  bool _fijo(String clave) => camposFijos(widget.catalogo, widget.registro).contains(clave);

  String _etiqueta(Textos t, String clave) => switch (clave) {
    'name' => t.sisCampoName,
    'serviceName' => t.sisCampoServiceName,
    'description' => t.sisCampoDescription,
    'amount' => t.sisCampoAmount,
    'price' => t.sisCampoPrice,
    'unit' => t.sisCampoUnit,
    'brand' => t.sisCampoBrand,
    'model' => t.sisCampoModel,
    'categoryId' => t.sisCampoCategory,
    'zoneIds' => t.sisCampoZoneIds,
    'localityId' => t.sisCampoLocality,
    'commissionIds' => t.sisCampoCommissionIds,
    'commission' => t.sisLlevaComision,
    'billable' => t.sisLlevaCobro,
    'isp' => t.sisCampoIsp,
    'payFrom' => t.sisCampoPayFrom,
    'payTo' => t.sisCampoPayTo,
    'invoiceDay' => t.sisCampoInvoiceDay,
    'installFrom' => t.sisCampoInstallFrom,
    'installTo' => t.sisCampoInstallTo,
    'permission' => t.sisCampoPermission,
    _ => clave,
  };

  /// Lo escrito, con números donde van números.
  Map<String, Object?> _leer() => {
    ..._v,
    for (final c in _campos)
      if (_textos[c.clave] case final ctl?)
        c.clave: switch (c.tipo) {
          TipoCampo.numero =>
            ctl.text.trim().isEmpty ? null : (num.tryParse(ctl.text.trim().replaceAll(',', '.')) ?? double.nan),
          TipoCampo.dia => int.tryParse(ctl.text.trim()),
          _ => ctl.text,
        },
  };

  Future<void> _guardar() async {
    final t = Textos.of(context);
    final v = _leer();
    // el importe que no se entiende no pasa (NaN no es un número válido)
    final fallo = v.values.any((x) => x is double && x.isNaN)
        ? FalloSistema.importe
        : revisarRegistro(
            widget.catalogo,
            v,
            widget.existentes,
            antes: widget.registro,
            nombreLocalidad: widget.nombresZonas['${v['localityId'] ?? ''}'] ?? '',
          );
    if (fallo != null) {
      setState(
        () => error = switch (fallo) {
          FalloSistema.faltaNombre => t.errSisNombre,
          FalloSistema.yaExiste => t.errSisYaExiste,
          FalloSistema.dia => t.errSisDia,
          FalloSistema.importe => t.errSisImporte,
          FalloSistema.localidad => t.errSisLocalidad,
          FalloSistema.categoria => t.errSisCategoria,
          FalloSistema.fechaChoca => t.errSisFechaChoca,
          FalloSistema.permiso => t.errSisPermiso,
        },
      );
      return;
    }
    await guardarYCerrar(
      () => widget.servicio.guardarRegistro(
        widget.catalogo,
        v,
        widget.tecnico,
        antes: widget.registro,
        existentes: widget.existentes,
        nombreLocalidad: widget.nombresZonas['${v['localityId'] ?? ''}'] ?? '',
      ),
      listo: () => t.sisGuardado,
    );
  }

  Future<void> _borrar() {
    final t = Textos.of(context);
    return borrarConPregunta(
      widget.registro!,
      [t.sisBorrarTexto, if (widget.catalogo == Catalogo.localidades) t.sisBorrarLocalidad].join('\n\n'),
      () => widget.servicio.borrarRegistro(widget.catalogo, widget.registro!, widget.tecnico),
    );
  }

  Widget _campo(Textos t, Campo c) {
    final etiqueta = _etiqueta(t, c.clave);
    final fijo = _fijo(c.clave);
    Widget chips(Map<String, String> opciones, {required bool varias}) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: id, value: nombre) in opciones.entries)
          if (varias)
            FilterChip(
              label: Text(nombre),
              selected: (_v[c.clave] as List? ?? const []).contains(id),
              onSelected: (si) => setState(() {
                final l = [...(_v[c.clave] as List? ?? const []).map((e) => '$e')];
                si ? l.add(id) : l.remove(id);
                _v[c.clave] = l;
              }),
            )
          else
            ChoiceChip(
              label: Text(nombre),
              selected: _v[c.clave] == id,
              onSelected: fijo ? null : (_) => setState(() => _v[c.clave] = id),
            ),
      ],
    );
    Widget conTitulo(Widget hijo) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        hijo,
      ],
    );
    return switch (c.tipo) {
      TipoCampo.texto || TipoCampo.largo || TipoCampo.numero || TipoCampo.dia => TextField(
        controller: _textos[c.clave],
        enabled: !fijo,
        minLines: c.tipo == TipoCampo.largo ? 2 : 1,
        maxLines: c.tipo == TipoCampo.largo ? 5 : 1,
        textCapitalization: c.tipo == TipoCampo.texto || c.tipo == TipoCampo.largo
            ? TextCapitalization.sentences
            : TextCapitalization.none,
        keyboardType: switch (c.tipo) {
          TipoCampo.numero => const TextInputType.numberWithOptions(decimal: true),
          TipoCampo.dia => TextInputType.number,
          _ => TextInputType.text,
        },
        decoration: InputDecoration(labelText: etiqueta, helperText: fijo ? t.sisNombreFijo : null, helperMaxLines: 3),
      ),
      TipoCampo.siNo => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(etiqueta),
        value: _v[c.clave] == true,
        onChanged: (x) => setState(() => _v[c.clave] = x),
      ),
      TipoCampo.localidades => conTitulo(chips(widget.nombresZonas, varias: true)),
      TipoCampo.localidad => conTitulo(chips(widget.nombresZonas, varias: false)),
      TipoCampo.comisiones => conTitulo(chips({for (final r in widget.comisiones) r.id: nombreDe(r)}, varias: true)),
      TipoCampo.categoria => DropdownButtonFormField<String>(
        initialValue: widget.categorias.containsKey(_v[c.clave]) ? '${_v[c.clave]}' : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: etiqueta),
        items: [
          for (final MapEntry(key: id, value: nombre) in widget.categorias.entries)
            DropdownMenuItem(value: id, child: Text(nombre)),
        ],
        onChanged: (x) => setState(() => _v[c.clave] = x ?? ''),
      ),
      TipoCampo.permiso => DropdownButtonFormField<String>(
        initialValue: permisos.containsKey(_v[c.clave]) ? '${_v[c.clave]}' : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: etiqueta),
        items: [for (final p in permisos.keys) DropdownMenuItem(value: p, child: Text(nombrePermiso(t, p)))],
        onChanged: (x) => setState(() => _v[c.clave] = x),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final r = widget.registro;
    return FormularioSistema(
      titulo: widget.titulo,
      registro: r,
      guardando: guardando,
      error: error,
      alBorrar: r != null && sePuedeBorrar(widget.catalogo, r) ? _borrar : null,
      // si al editar no queda nada que cambiar (solo el nombre, que se cambia en la web), no se guarda: solo se borra
      alGuardar: nadaQueCambiar(widget.catalogo, r) ? null : _guardar,
      children: [
        for (final c in _campos) ...[_campo(t, c), const SizedBox(height: 16)],
      ],
    );
  }
}

/// Pregunta si se borra el registro y, si sí, lo borra y cierra el formulario.
extension BorrarConPregunta on GuardarYCerrar {
  Future<void> borrarConPregunta(Registro r, String texto, Future<bool> Function() borrar) async {
    final t = Textos.of(context);
    final si = await confirmar(
      context,
      icono: Icons.delete_outline_rounded,
      titulo: t.sisBorrarPregunta(nombreDe(r).isEmpty ? r.id : nombreDe(r)),
      texto: texto,
      boton: t.sisBorrar,
    );
    if (!si || !mounted) return;
    await guardarYCerrar(borrar, listo: () => t.sisBorrado);
  }
}

/// Formulario de Sistema: «Lista › nombre» arriba con el botón de borrar (sin `alBorrar`, no sale), los campos, el
/// error y «Guardar» abajo (sin `alGuardar`, no sale).
class FormularioSistema extends StatelessWidget {
  const FormularioSistema({
    super.key,
    required this.titulo,
    required this.registro,
    required this.guardando,
    required this.error,
    required this.alBorrar,
    required this.alGuardar,
    required this.children,
  });

  final String titulo;
  final Registro? registro;
  final bool guardando;
  final String? error;
  final VoidCallback? alBorrar;
  final VoidCallback? alGuardar;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final r = registro;
    final guardar = alGuardar;
    return Scaffold(
      appBar: AppBar(
        title: Text('$titulo › ${r == null ? t.sisNuevo : (nombreDe(r).isEmpty ? r.id : nombreDe(r))}'),
        actions: [
          if (alBorrar != null)
            IconButton(
              tooltip: t.sisBorrar,
              onPressed: guardando ? null : alBorrar,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          ...children,
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
            ),
        ],
      ),
      bottomNavigationBar: guardar == null
          ? null
          : BarraInferior(
              child: BotonPrincipal(
                texto: t.sisGuardar,
                icono: Icons.save_rounded,
                ocupado: guardando,
                alTocar: guardar,
              ),
            ),
    );
  }
}
