import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/nueva_orden.dart';
import '../logica/orden.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'campos.dart';
import 'comun.dart';
import 'diseno.dart';

/// Crear una orden (técnicos y administradores) o editarla (administradores), con los mismos datos que la web:
/// todos los servicios, con lo que pide cada uno (plan y comisionista, motivo y módem, cancelación temporal…).
/// La orden llega sin técnico: el primero que la acepta se la queda. Devuelve el folio creado o true al guardar cambios.
class PantallaFormOrden extends StatefulWidget {
  const PantallaFormOrden({
    super.key,
    required this.tecnico,
    required this.servicio,
    required this.nombresZonas,
    this.orden,
    this.inicial,
  });

  final Tecnico tecnico;
  final ServicioOrdenes servicio;

  /// Localidades en el orden de la web.
  final Map<String, String> nombresZonas;

  /// La orden a editar; null = orden nueva.
  final Orden? orden;

  /// Para una orden nueva: los datos con que se abre (por ejemplo, los de un prospecto).
  final DatosOrden? inicial;

  @override
  State<PantallaFormOrden> createState() => _PantallaFormOrdenState();
}

class _PantallaFormOrdenState extends State<PantallaFormOrden> {
  late final DatosOrden _d = widget.orden == null
      ? (widget.inicial ?? DatosOrden(pais: paisDelCelular()))
      : DatosOrden.de(widget.orden!, pais: paisDelCelular());
  late final _cliente = TextEditingController(text: _d.cliente);
  late final _telefono = TextEditingController(text: _d.telefono);
  late final _direccion = TextEditingController(text: _d.direccion);
  late final _coordenadas = TextEditingController(text: _d.coordenadas);
  late final _descripcion = TextEditingController(text: _d.descripcion);
  late final _motivoOtro = TextEditingController(text: _d.motivoTexto);
  late final _motivoTemporal = TextEditingController(text: _d.temporalMotivo);
  CatalogosOrden _cat = const CatalogosOrden();
  Map<String, String> _paises = const {};
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  bool get _editando => widget.orden != null;
  Tecnico get _yo => widget.tecnico;
  TipoServicio get _tipo => tipoServicio(_cat.servicios[_d.servicioId]);

  @override
  void initState() {
    super.initState();
    final zonas = _zonas;
    if (_d.zonaId == null && zonas.length == 1) _d.zonaId = zonas.first;
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final cat = await widget.servicio.catalogosOrden();
      if (!mounted) return;
      setState(() {
        _cat = cat;
        _cargando = false;
        _ajustarAlCatalogo();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = textoErrorCarga(Textos.of(context), e);
        });
      }
    }
  }

  /// Al editar, como la web: una baja vieja sin id de motivo se busca por su nombre (o queda en «Otros» con su texto),
  /// y una comisión que el comisionista ya no tiene marcada se quita.
  void _ajustarAlCatalogo() {
    final o = widget.orden;
    if (o == null) return;
    final nombre = '${o.datos['bajaReason'] ?? ''}';
    if (_d.motivoId == null && !_d.motivoOtro && nombre.isNotEmpty) {
      final m = _cat.motivos.where((x) => !x.otro && plano(x.nombre) == plano(nombre)).firstOrNull;
      if (m != null) {
        _d.motivoId = m.id;
      } else {
        _d.motivoOtro = true;
        _motivoOtro.text = nombre;
      }
    }
    if (_d.comisionId != null && !_cat.comisionesDe(_d.comisionistaId).any((c) => c['id'] == _d.comisionId)) {
      _d.comisionId = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paises.isEmpty) {
      nombresDePaises(Localizations.localeOf(context).languageCode).then((p) {
        if (mounted) setState(() => _paises = p);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_cliente, _telefono, _direccion, _coordenadas, _descripcion, _motivoOtro, _motivoTemporal]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Localidades que puede elegir: el administrador, todas; el técnico, las suyas (en el orden de la web).
  List<String> get _zonas {
    final todas = widget.nombresZonas.keys.toList();
    final mias = _yo.esAdmin
        ? todas
        : [...todas.where(_yo.zonas.contains), ..._yo.zonas.where((z) => !todas.contains(z))];
    final actual = _d.zonaId;
    return [...mias, if (actual != null && !mias.contains(actual)) actual];
  }

  /// Todos los servicios de la web, en su orden.
  List<MapEntry<String, Map<String, dynamic>>> get _servicios =>
      _cat.servicios.entries.toList()..sort((a, b) => compararOrdenWeb(a.value, b.value));

  Future<DateTime?> _calendario(DateTime inicial) {
    final hoy = DateTime.now();
    final primero = DateTime(hoy.year, hoy.month, hoy.day);
    return showDatePicker(
      context: context,
      initialDate: inicial.isBefore(primero) ? primero : inicial,
      firstDate: primero,
      lastDate: DateTime(hoy.year + 2, 12, 31),
    );
  }

  Future<void> _elegirHora() async {
    final partes = _d.hora.split(':');
    final elegida = await showTimePicker(
      context: context,
      initialTime: partes.length == 2
          ? TimeOfDay(hour: int.tryParse(partes[0]) ?? 9, minute: int.tryParse(partes[1]) ?? 0)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (elegida != null) {
      setState(
        () => _d.hora = '${elegida.hour.toString().padLeft(2, '0')}:${elegida.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _guardar() async {
    final t = Textos.of(context);
    _d
      ..cliente = _cliente.text
      ..telefono = _telefono.text
      ..direccion = _direccion.text
      ..coordenadas = _coordenadas.text
      ..descripcion = _descripcion.text
      ..motivoTexto = _motivoOtro.text
      ..temporalMotivo = _motivoTemporal.text;
    final fallo = revisarOrden(_d, DateTime.now(), _cat, antes: widget.orden);
    if (fallo != null) {
      setState(() => _error = _textoFallo(t, fallo));
      return;
    }
    setState(() {
      _error = null;
      _guardando = true;
    });
    try {
      if (_editando) {
        await widget.servicio.editar(widget.orden!, _d, _yo);
        if (mounted) Navigator.pop(context, true);
      } else {
        final creada = await widget.servicio.crear(_d, _yo);
        if (mounted) Navigator.pop(context, creada);
      }
    } catch (e) {
      if (mounted) setState(() => _error = textoDeError(t, e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _textoFallo(Textos t, FalloNuevaOrden f) => switch (f) {
    FalloNuevaOrden.cliente => t.errFoCliente,
    FalloNuevaOrden.telefono => t.errFoTelefono(_paises[_d.pais] ?? _d.pais),
    FalloNuevaOrden.coordenadas => t.errFoCoordenadas,
    FalloNuevaOrden.localidad => t.errFoLocalidad,
    FalloNuevaOrden.servicio => t.errFoServicio,
    FalloNuevaOrden.plan => t.errFoPlan,
    FalloNuevaOrden.comision => t.errFoComision,
    FalloNuevaOrden.motivoBaja => t.errFoMotivo,
    FalloNuevaOrden.motivoOtro => t.errFoMotivoOtro,
    FalloNuevaOrden.modem => t.errFoModem,
    FalloNuevaOrden.recogeModem => t.errFoRecoge,
    FalloNuevaOrden.fechaRegreso => t.errFoRegreso,
    FalloNuevaOrden.fechaRegresoPasada => t.errFoRegresoPasada,
    FalloNuevaOrden.diaPasado => t.errFoDiaPasado,
    FalloNuevaOrden.horaPasada => t.errFoHoraPasada,
    FalloNuevaOrden.completadaFutura => t.errFoCompletadaFutura,
  };

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final folio = widget.orden?.folio ?? '';
    final extra = _datosExtra(t);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          encabezadoAzul(
            alto: 170,
            titulo: Text(_editando ? t.editarOrden : t.nuevaOrden),
            relleno: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 20),
            contenido: [
              Text(
                _editando ? t.folio(folio) : t.foSubtituloNueva,
                style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 15, height: 1.35),
              ),
            ],
          ),
          if (_cargando)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverList.list(
              children: [
                _seccion(0, Icons.person_rounded, t.foSeccionCliente, [
                  TextField(
                    controller: _cliente,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: t.foCliente, prefixIcon: const Icon(Icons.badge_outlined)),
                  ),
                  const SizedBox(height: 12),
                  CampoTelefono(
                    controller: _telefono,
                    pais: _d.pais,
                    alCambiarPais: (p) => setState(() => _d.pais = p),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _direccion,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: t.foDireccion, prefixIcon: const Icon(Icons.home_outlined)),
                  ),
                ]),
                _seccion(1, Icons.my_location_rounded, t.foSeccionUbicacion, [
                  CampoUbicacion(controller: _coordenadas),
                ]),
                _seccion(2, Icons.map_rounded, t.localidad, [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final z in _zonas)
                        ChoiceChip(
                          label: Text(widget.nombresZonas[z] ?? z),
                          selected: _d.zonaId == z,
                          onSelected: (_) => setState(() {
                            _d.zonaId = z;
                            // el comisionista tiene que trabajar en esa localidad
                            final c = _cat.comisionistas.where((x) => x.id == _d.comisionistaId).firstOrNull;
                            if (c != null && !c.atiende(z)) {
                              _d
                                ..comisionistaId = ''
                                ..comisionId = null;
                            }
                          }),
                        ),
                    ],
                  ),
                ]),
                _seccion(3, Icons.handyman_rounded, t.servicio, [
                  DropdownButtonFormField<String>(
                    initialValue: _cat.servicios.containsKey(_d.servicioId) ? _d.servicioId : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.build_circle_outlined),
                      hintText: t.foElegirServicio,
                    ),
                    items: [
                      for (final e in _servicios)
                        DropdownMenuItem(value: e.key, child: Text('${e.value['name'] ?? e.key}')),
                    ],
                    onChanged: (v) => setState(() => _d.servicioId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descripcion,
                    minLines: 3,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: t.descripcion, alignLabelWithHint: true),
                  ),
                ]),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: extra ?? const SizedBox(width: double.infinity),
                ),
                _seccion(5, Icons.event_rounded, t.foCuando, [_cuando(t)]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.foLlegaSinTecnico, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
        ],
      ),
      bottomNavigationBar: BarraInferior(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
            BotonPrincipal(
              icono: _editando ? Icons.save_rounded : Icons.add_task_rounded,
              texto: _editando ? t.foGuardar : t.foCrear,
              ocupado: _guardando || _cargando,
              alTocar: _guardar,
            ),
          ],
        ),
      ),
    );
  }

  /// Lo que pide el servicio elegido, como las cajas extra de la web.
  Widget? _datosExtra(Textos t) => switch (_tipo) {
    TipoServicio.nuevo => _seccion(4, Icons.rocket_launch_rounded, t.foDatosNuevo, _nuevo(t)),
    TipoServicio.baja => _seccion(4, Icons.person_remove_rounded, t.foDatosBaja, _baja(t)),
    TipoServicio.temporal => _seccion(4, Icons.pause_circle_rounded, t.foDatosTemporal, _temporal(t)),
    TipoServicio.tvFibra => _seccion(4, Icons.tv_off_rounded, t.foModemRecuperar, [
      _modems(_d.modemTv, (m) => setState(() => _d.modemTv = m)),
    ]),
    TipoServicio.sencillo || TipoServicio.tvCable => null,
  };

  List<Widget> _nuevo(Textos t) {
    final comisionistas = _cat.comisionistas.where((c) => c.atiende(_d.zonaId)).toList();
    final tasas = _d.comisionistaId.isEmpty ? const <Map<String, dynamic>>[] : _cat.comisionesDe(_d.comisionistaId);
    void elegirComisionista(String id) {
      _d
        ..comisionistaId = id
        ..comisionId = id.isEmpty ? null : _cat.comisionSugerida(id, _d.plan);
    }

    final plan = _d.plan;
    return [
      _subtitulo(t.foPlan),
      _modems(
        plan,
        (m) => setState(() {
          _d.plan = m;
          if (_d.comisionistaId.isNotEmpty) {
            _d.comisionId = _cat.comisionSugerida(_d.comisionistaId, m) ?? _d.comisionId;
          }
        }),
      ),
      if (plan != null && plan.doblePlay) ...[
        const SizedBox(height: 14),
        _subtitulo(t.foTelevisiones),
        Row(
          children: [
            Expanded(child: _contador(t.foTvConCosto, _d.tvPagadas, (v) => setState(() => _d.tvPagadas = v))),
            const SizedBox(width: 10),
            Expanded(child: _contador(t.foTvSinCosto, _d.tvGratis, (v) => setState(() => _d.tvGratis = v))),
          ],
        ),
        if (_cat.precioTv != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              t.foTvPrecio(dinero(context, _cat.precioTv!), dinero(context, _cat.precioTv! * _d.tvPagadas)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
      const SizedBox(height: 16),
      _subtitulo(t.foQuienLoConsiguio),
      DropdownButtonFormField<String>(
        key: ValueKey('comisionista-${_d.zonaId}'),
        initialValue: _d.comisionistaId,
        isExpanded: true,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.handshake_outlined)),
        items: [
          DropdownMenuItem(value: '', child: Text(t.foNingunoSinComision)),
          for (final c in comisionistas)
            DropdownMenuItem(
              value: c.id,
              child: Text(c.nombre, overflow: TextOverflow.ellipsis),
            ),
          if (_d.comisionistaId.isNotEmpty && !comisionistas.any((c) => c.id == _d.comisionistaId))
            DropdownMenuItem(
              value: _d.comisionistaId,
              child: Text('${widget.orden?.datos['referrerName'] ?? _d.comisionistaId}'),
            ),
        ],
        onChanged: (v) => setState(() => elegirComisionista(v ?? '')),
      ),
      if (tasas.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in tasas)
              ChoiceChip(
                avatar: const Icon(Icons.payments_outlined, size: 18),
                label: Text('${c['name'] ?? ''} · ${dinero(context, num.tryParse('${c['amount']}')?.toDouble() ?? 0)}'),
                selected: _d.comisionId == c['id'],
                onSelected: (_) => setState(() => _d.comisionId = '${c['id']}'),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _baja(Textos t) {
    final hayOtro = _cat.motivos.any((m) => m.otro);
    return [
      _subtitulo(t.foMotivo),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final m in _cat.motivos)
            ChoiceChip(
              label: Text(m.nombre),
              selected: m.otro ? _d.motivoOtro : (!_d.motivoOtro && _d.motivoId == m.id),
              onSelected: (_) => setState(() {
                _d
                  ..motivoOtro = m.otro
                  ..motivoId = m.otro ? null : m.id;
              }),
            ),
          if (!hayOtro)
            ChoiceChip(
              label: Text(t.foOtros),
              selected: _d.motivoOtro,
              onSelected: (_) => setState(() {
                _d
                  ..motivoOtro = true
                  ..motivoId = null;
              }),
            ),
        ],
      ),
      if (_d.motivoOtro) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _motivoOtro,
          maxLength: 400,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: t.foEscribeMotivo),
        ),
      ],
      const SizedBox(height: 14),
      _subtitulo(t.foModemRecuperar),
      _modems(_d.modemBaja, (m) => setState(() => _d.modemBaja = m)),
    ];
  }

  List<Widget> _temporal(Textos t) {
    final regreso = DateTime.tryParse(_d.fechaRegreso);
    return [
      TextField(
        controller: _motivoTemporal,
        maxLength: 400,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: t.foMotivoOpcional, alignLabelWithHint: true),
      ),
      _subtitulo(t.foRecogeModem),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(t.foSi),
            selected: _d.recogeModem == true,
            onSelected: (_) => setState(() => _d.recogeModem = true),
          ),
          ChoiceChip(
            label: Text(t.foNo),
            selected: _d.recogeModem == false,
            onSelected: (_) => setState(() => _d.recogeModem = false),
          ),
        ],
      ),
      if (_d.recogeModem == true) ...[
        const SizedBox(height: 14),
        _subtitulo(t.foModemSeRecoge),
        _modems(_d.modemTemporal, (m) => setState(() => _d.modemTemporal = m)),
      ],
      if (_d.recogeModem == false) ...[
        const SizedBox(height: 14),
        _subtitulo(t.foFechaRegreso),
        OutlinedButton.icon(
          icon: const Icon(Icons.event_available_rounded),
          label: Text(regreso == null ? t.foElegirFecha : fechaCorta(context, _d.fechaRegreso)),
          onPressed: () async {
            final f = await _calendario(regreso ?? DateTime.now());
            if (f != null) setState(() => _d.fechaRegreso = textoDia(f));
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(t.foFechaRegresoAyuda, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ];
  }

  /// Categorías de módem para elegir (Internet o Doble Play).
  Widget _modems(CategoriaModem? actual, ValueChanged<CategoriaModem> elegir) {
    final t = Textos.of(context);
    if (_cat.modems.isEmpty) {
      return Text(t.foSinCategoriasModem, style: TextStyle(color: Theme.of(context).colorScheme.error));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in _cat.modems)
          ChoiceChip(
            avatar: Icon(m.doblePlay ? Icons.tv_rounded : Icons.router_rounded, size: 18),
            label: Text(m.nombre),
            selected: actual?.id == m.id,
            onSelected: (_) => elegir(m),
          ),
      ],
    );
  }

  Widget _subtitulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(texto, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
  );

  /// Cantidad de 0 a 50 con botones − y +.
  Widget _contador(String texto, int valor, ValueChanged<int> cambiar) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colores.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: valor > 0 ? () => cambiar(valor - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text('$valor', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: valor < 50 ? () => cambiar(valor + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _cuando(Textos t) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final manana = hoy.add(const Duration(days: 1));
    final dia = DateTime(_d.dia.year, _d.dia.month, _d.dia.day);
    final otro = dia != hoy && dia != manana;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(label: Text(t.hoy), selected: dia == hoy, onSelected: (_) => setState(() => _d.dia = hoy)),
            ChoiceChip(
              label: Text(t.foManana),
              selected: dia == manana,
              onSelected: (_) => setState(() => _d.dia = manana),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(otro ? fechaCorta(context, textoDia(dia)) : t.foOtroDia),
              selected: otro,
              onSelected: (_) async {
                final f = await _calendario(_d.dia);
                if (f != null) setState(() => _d.dia = f);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(t.foSinHora),
              selected: _d.hora.isEmpty,
              onSelected: (_) => setState(() => _d.hora = ''),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(_d.hora.isEmpty ? t.foElegirHora : _d.hora),
              selected: _d.hora.isNotEmpty,
              onSelected: (_) => _elegirHora(),
            ),
          ],
        ),
      ],
    );
  }

  /// Tarjeta de una sección del formulario, con su ícono y título; aparecen una tras otra.
  Widget _seccion(int orden, IconData icono, String titulo, List<Widget> hijos) {
    final colores = Theme.of(context).colorScheme;
    return Aparecer(
      orden: orden,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Superficie(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colores.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icono, size: 19, color: colores.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...hijos,
            ],
          ),
        ),
      ),
    );
  }
}
