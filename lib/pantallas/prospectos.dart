import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/textos.dart';
import '../logica/fechas.dart';
import '../logica/nueva_orden.dart';
import '../logica/orden.dart';
import '../logica/prospectos.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'campos.dart';
import 'comun.dart';
import 'diseno.dart';
import 'form_orden.dart';

/// Órdenes de trabajo › Prospectos, como la web: posibles clientes con su día de instalación (luz roja si es hoy o ya
/// pasó, amarilla si es mañana). «Crear orden» abre la orden nueva con sus datos y el prospecto queda asignado.
class PantallaProspectos extends StatefulWidget {
  const PantallaProspectos({super.key, required this.tecnico, required this.servicio, required this.nombresZonas});

  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaProspectos> createState() => _PantallaProspectosState();
}

class _PantallaProspectosState extends State<PantallaProspectos> {
  late final Stream<List<Prospecto>> _lista = widget.servicio.prospectos(widget.tecnico);
  RangoDias? _rango;
  String? _zona;
  bool _asignados = false;

  bool get _puedeEditar => !widget.tecnico.soloMirar;

  Future<void> _abrirFormulario([Prospecto? p]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFormProspecto(
          tecnico: widget.tecnico,
          servicio: widget.servicio,
          nombresZonas: widget.nombresZonas,
          prospecto: p,
        ),
      ),
    );
    if (guardado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Textos.of(context).prosGuardado)));
    }
  }

  /// Abre la orden nueva con los datos del prospecto; al crearla, el prospecto queda asignado a ella.
  Future<void> _crearOrden(Prospecto p) async {
    final t = Textos.of(context);
    final avisos = ScaffoldMessenger.of(context);
    final CatalogosOrden cat;
    try {
      cat = await widget.servicio.catalogosOrden();
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(textoDeError(t, e))));
      return;
    }
    if (!mounted) return;
    final folio = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFormOrden(
          tecnico: widget.tecnico,
          servicio: widget.servicio,
          nombresZonas: widget.nombresZonas,
          inicial: ordenDeProspecto(p, cat, t.prosDescripcionOrden),
        ),
      ),
    );
    if (folio is! OrdenCreada) return;
    try {
      await widget.servicio.asignarProspecto(p, folio, widget.tecnico);
      avisos.showSnackBar(SnackBar(content: Text(t.prosAsignado(folioVisible(folio.folio)))));
    } catch (e) {
      avisos.showSnackBar(SnackBar(content: Text(textoDeError(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final hoy = textoDia(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(t.menuProspectos)),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _abrirFormulario,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(t.prosNuevo),
            )
          : null,
      body: StreamBuilder<List<Prospecto>>(
        stream: _lista,
        builder: (context, foto) {
          final cargando = cargaOError(t, foto);
          final r = _rango;
          final todos = foto.data ?? const <Prospecto>[];
          final zonas = [
            for (final z in widget.nombresZonas.keys)
              if (todos.any((p) => p.zonaId == z)) z,
          ];
          final lista = ordenarProspectos([
            for (final p in todos)
              if (p.asignado == _asignados &&
                  (_zona == null || p.zonaId == _zona) &&
                  (r == null ||
                      (p.diaInstalacion.isNotEmpty &&
                          p.diaInstalacion.compareTo(textoDia(r.desde)) >= 0 &&
                          p.diaInstalacion.compareTo(textoDia(r.hasta)) <= 0)))
                p,
          ]);
          return Column(
            children: [
              BotonesFechas(rango: _rango, alElegir: (x) => setState(() => _rango = x), conTodas: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: false, label: Text(t.prosPendientes)),
                    ButtonSegment(value: true, label: Text(t.prosAsignados)),
                  ],
                  selected: {_asignados},
                  onSelectionChanged: (s) => setState(() => _asignados = s.first),
                ),
              ),
              if (zonas.length > 1)
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                    children: [
                      for (final z in <String?>[null, ...zonas])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(z == null ? t.todas : (widget.nombresZonas[z] ?? z)),
                            selected: _zona == z,
                            onSelected: (_) => setState(() => _zona = z),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child:
                    cargando ??
                    (lista.isEmpty
                        ? AvisoCentral(icono: Icons.person_search_rounded, texto: t.prosVacio)
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 96),
                            itemCount: lista.length,
                            itemBuilder: (context, i) => _tarjeta(t, lista[i], hoy, i),
                          )),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tarjeta(Textos t, Prospecto p, String hoy, int posicion) {
    final colores = Theme.of(context).colorScheme;
    final o = p.comoOrden;
    final telefono = llamarA(o), mapa = mapaDe(o);
    final luz = luzProspecto(p, hoy);
    final detalle = [
      p.diaInstalacion.isEmpty ? t.prosSinDia : fechaCorta(context, p.diaInstalacion),
      widget.nombresZonas[p.zonaId] ?? p.zonaId,
      p.prospectorNombre,
    ].where((x) => x.isNotEmpty).join(' · ');
    return Aparecer(
      orden: posicion,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Superficie(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.foto.isNotEmpty) ...[Miniatura(foto: p.foto), const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre.isEmpty ? t.sinNombre : p.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(detalle, style: Theme.of(context).textTheme.bodySmall),
                        if (p.direccion.isNotEmpty) Text(p.direccion, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (p.comentario.isNotEmpty)
                          Text(
                            p.comentario,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colores.onSurfaceVariant),
                          ),
                        if (luz != LuzProspecto.ninguna) ...[const SizedBox(height: 6), _Luz(luz: luz)],
                        if (p.asignado && p.folio.isNotEmpty)
                          Text(
                            t.prosOrden(p.folio),
                            style: TextStyle(color: colores.primary, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: t.llamar,
                    onPressed: telefono == null ? null : () => abrirFuera(context, telefono),
                    icon: const Icon(Icons.phone_rounded),
                  ),
                  IconButton(
                    tooltip: t.verEnMapa,
                    onPressed: mapa == null ? null : () => abrirFuera(context, mapa),
                    icon: const Icon(Icons.near_me_rounded),
                  ),
                  const Spacer(),
                  if (_puedeEditar)
                    IconButton(
                      tooltip: t.prosEditar,
                      onPressed: () => _abrirFormulario(p),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  if (_puedeEditar && !p.asignado)
                    FilledButton.icon(
                      onPressed: () => _crearOrden(p),
                      icon: const Icon(Icons.assignment_add, size: 18),
                      label: Text(t.prosCrearOrden),
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

/// Luz con su texto (no solo el color): roja si es hoy o ya pasó, amarilla si es mañana.
class _Luz extends StatelessWidget {
  const _Luz({required this.luz});

  final LuzProspecto luz;

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final hoy = luz == LuzProspecto.hoy;
    final color = hoy ? Theme.of(context).colorScheme.error : const Color(0xFFD97706);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(
          hoy ? t.prosLuzHoy : t.prosLuzManana,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
      ],
    );
  }
}

/// Nuevo prospecto o editar uno, con los mismos datos que la web.
class PantallaFormProspecto extends StatefulWidget {
  const PantallaFormProspecto({
    super.key,
    required this.tecnico,
    required this.servicio,
    required this.nombresZonas,
    this.prospecto,
  });

  final Tecnico tecnico;
  final ServicioOrdenes servicio;
  final Map<String, String> nombresZonas;
  final Prospecto? prospecto;

  @override
  State<PantallaFormProspecto> createState() => _PantallaFormProspectoState();
}

class _PantallaFormProspectoState extends State<PantallaFormProspecto> with GuardarYCerrar {
  late final DatosProspecto _d = widget.prospecto == null
      ? (DatosProspecto()
          ..pais = paisDelCelular()
          ..zonaId = widget.tecnico.zonas.length == 1 ? widget.tecnico.zonas.first : '')
      : DatosProspecto.de(widget.prospecto!);
  late final _nombre = TextEditingController(text: _d.nombre);
  late final _telefono = TextEditingController(text: _d.telefono);
  late final _direccion = TextEditingController(text: _d.direccion);
  late final _coordenadas = TextEditingController(text: _d.coordenadas);
  late final _comentario = TextEditingController(text: _d.comentario);
  List<Comisionista> _comisionistas = const [];

  @override
  void initState() {
    super.initState();
    widget.servicio
        .catalogosOrden()
        .then((c) {
          if (mounted) setState(() => _comisionistas = c.comisionistas);
        })
        .catchError((_) {
          // sin la lista, el prospecto se guarda sin quién lo prospectó
        });
  }

  @override
  void dispose() {
    for (final c in [_nombre, _telefono, _direccion, _coordenadas, _comentario]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _foto(ImageSource fuente) async {
    final t = Textos.of(context);
    final foto = await tomarFoto(fuente);
    if (!mounted) return;
    if (foto == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.prosFotoError)));
    } else if (foto.isNotEmpty) {
      setState(() => _d.foto = foto);
    }
  }

  Future<void> _elegirDia() async {
    final hoy = DateTime.now();
    final primero = DateTime(hoy.year, hoy.month, hoy.day);
    final actual = DateTime.tryParse(_d.dia);
    final d = await showDatePicker(
      context: context,
      firstDate: primero,
      lastDate: DateTime(hoy.year + 2, 12, 31),
      initialDate: actual != null && !actual.isBefore(primero) ? actual : primero,
    );
    if (d != null && mounted) setState(() => _d.dia = textoDia(d));
  }

  Future<void> _guardar() async {
    final t = Textos.of(context);
    _d
      ..nombre = _nombre.text
      ..telefono = _telefono.text
      ..direccion = _direccion.text
      ..coordenadas = _coordenadas.text
      ..comentario = _comentario.text;
    final fallo = revisarProspecto(_d, textoDia(DateTime.now()), antes: widget.prospecto);
    if (fallo != null) {
      final nombres = await nombresDePaises(Localizations.localeOf(context).languageCode);
      if (!mounted) return;
      setState(
        () => error = switch (fallo) {
          FalloProspecto.telefono => t.errFoTelefono(nombres[_d.pais] ?? _d.pais),
          FalloProspecto.coordenadas => t.errFoCoordenadas,
          FalloProspecto.diaPasado => t.errProsDiaPasado,
        },
      );
      return;
    }
    await guardarYCerrar(() => widget.servicio.guardarProspecto(_d, widget.tecnico, antes: widget.prospecto));
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final zonas = widget.tecnico.esAdmin || widget.tecnico.zonas.isEmpty
        ? widget.nombresZonas.keys.toList()
        : [
            for (final z in widget.nombresZonas.keys)
              if (widget.tecnico.zonas.contains(z)) z,
          ];
    final comisionistas = [
      for (final c in _comisionistas)
        // el que ya tenía se sigue viendo aunque no sea de esta localidad
        if (c.nombre.isNotEmpty && (c.id == _d.prospectorId || c.atiende(_d.zonaId.isEmpty ? null : _d.zonaId))) c,
    ]..sort((a, b) => plano(a.nombre).compareTo(plano(b.nombre)));
    final quien = comisionistas.any((c) => c.id == _d.prospectorId) ? _d.prospectorId : '';
    final img = _d.foto.isEmpty ? null : imagenDeFoto(_d.foto);
    return Scaffold(
      appBar: AppBar(title: Text(widget.prospecto == null ? t.prosNuevo : t.prosEditar)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Text(t.prosExplica, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            controller: _nombre,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: t.prosNombre),
          ),
          const SizedBox(height: 12),
          CampoTelefono(controller: _telefono, pais: _d.pais, alCambiarPais: (p) => setState(() => _d.pais = p)),
          const SizedBox(height: 12),
          TextField(
            controller: _direccion,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(labelText: t.foDireccion),
          ),
          const SizedBox(height: 12),
          CampoUbicacion(controller: _coordenadas),
          const SizedBox(height: 16),
          Text(t.localidad, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(t.prosSinLocalidad),
                selected: _d.zonaId.isEmpty,
                onSelected: (_) => setState(() => _d.zonaId = ''),
              ),
              for (final z in zonas)
                ChoiceChip(
                  label: Text(widget.nombresZonas[z] ?? z),
                  selected: _d.zonaId == z,
                  onSelected: (_) => setState(() => _d.zonaId = z),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('quien-$quien-${comisionistas.length}'),
            initialValue: quien,
            isExpanded: true,
            decoration: InputDecoration(labelText: t.prosQuien),
            items: [
              DropdownMenuItem(value: '', child: Text(t.prosNadie)),
              for (final c in comisionistas) DropdownMenuItem(value: c.id, child: Text(c.nombre)),
            ],
            onChanged: (v) => setState(() {
              _d.prospectorId = v ?? '';
              _d.prospectorNombre = comisionistas.where((c) => c.id == v).firstOrNull?.nombre ?? '';
            }),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _elegirDia,
            icon: const Icon(Icons.event_rounded),
            label: Text(_d.dia.isEmpty ? t.prosDia : '${t.prosDia}: ${fechaCorta(context, _d.dia)}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comentario,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: t.prosComentario),
          ),
          const SizedBox(height: 16),
          Text(t.prosFoto, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (img != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image(image: img, height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _foto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_rounded),
                label: Text(t.prosTomarFoto),
              ),
              OutlinedButton.icon(
                onPressed: () => _foto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(t.prosGaleria),
              ),
              if (img != null)
                TextButton.icon(
                  onPressed: () => setState(() => _d.foto = ''),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(t.prosQuitarFoto),
                ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
      bottomNavigationBar: BarraInferior(
        child: BotonPrincipal(texto: t.prosGuardar, icono: Icons.save_rounded, ocupado: guardando, alTocar: _guardar),
      ),
    );
  }
}
