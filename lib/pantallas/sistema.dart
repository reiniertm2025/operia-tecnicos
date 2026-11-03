import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/orden.dart';
import '../logica/sistema.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import '../servicios/usuarios.dart';
import 'comun.dart';
import 'diseno.dart';
import 'form_catalogo.dart';
import 'form_usuario.dart';

/// Sistema › (Usuarios app, Roles, Localidades, Servicios, Comisionistas, Activos…): las mismas listas que la web, con
/// buscador. Se agrega con «Agregar» y se cambia o borra tocando el registro (Usuarios app, con su acceso a la app).
/// Jalar hacia abajo vuelve a leer.
class PantallaCatalogo extends StatefulWidget {
  const PantallaCatalogo({
    super.key,
    required this.catalogo,
    required this.titulo,
    required this.servicio,
    required this.tecnico,
    required this.nombresZonas,
  });

  final Catalogo catalogo;
  final String titulo;
  final ServicioOrdenes servicio;
  final Tecnico tecnico;
  final Map<String, String> nombresZonas;

  @override
  State<PantallaCatalogo> createState() => _PantallaCatalogoState();
}

/// Lo leído: la lista y, para ponerles nombre, las otras colecciones que la acompañan.
/// `todos`: toda la colección (para no repetir nombres); `extra`: la otra que acompaña (usuarios de una localidad,
/// comisiones de un comisionista).
typedef _Datos = ({List<Registro> lista, List<Registro> todos, Map<String, String> nombres, List<Registro> extra});

class _PantallaCatalogoState extends State<PantallaCatalogo> {
  late Future<_Datos> _carga = _leer();
  String _buscar = '';

  Future<_Datos> _leer({bool recargar = false}) async {
    final s = widget.servicio;
    final c = widget.catalogo;
    final otras = switch (c) {
      Catalogo.usuarios => ['roles', 'occupations'],
      Catalogo.activos => ['assetCategories'],
      Catalogo.localidades => ['users'],
      Catalogo.cobros => ['services'],
      Catalogo.comisionistas => ['commissions'],
      _ => const <String>[],
    };
    final r = await Future.wait([
      s.registros(coleccionDe(c), recargar: recargar),
      for (final o in otras) s.registros(o, recargar: recargar),
    ]);
    return (
      lista: ordenarCatalogo(c, r[0].where((x) => entraEn(c, x))),
      todos: r[0],
      nombres: {
        for (final l in r.skip(1))
          for (final x in l) x.id: nombreDe(x),
      },
      extra: r.length > 1 ? r[1] : const <Registro>[],
    );
  }

  String _zonas(Object? ids) =>
      [for (final z in (ids is List ? ids : const [])) widget.nombresZonas['$z'] ?? '$z'].join(', ');

  /// Las líneas debajo del nombre, con lo que muestra la tabla de la web.
  List<String> _detalle(Textos t, Registro r, _Datos d) {
    final x = r.datos;
    String v(String c) => '${x[c] ?? ''}'.trim();
    String dinero2(String c) => num.tryParse(v(c)) == null ? '' : dinero(context, num.parse(v(c)).toDouble());
    return switch (widget.catalogo) {
      Catalogo.usuarios => [
        [d.nombres[v('role')] ?? v('role'), d.nombres[v('occupation')] ?? ''].where((e) => e.isNotEmpty).join(' · '),
        [v('phone'), v('email')].where((e) => e.isNotEmpty).join(' · '),
        _zonas(x['zoneIds']).isEmpty ? t.todasLasLocalidades : _zonas(x['zoneIds']),
        if (x['appAccess'] == false) t.sisSinAcceso,
      ],
      Catalogo.roles => [v('description'), nombrePermiso(t, v('permission'))],
      Catalogo.localidades => [
        v('description'),
        t.sisUsuarios(d.extra.where((u) => (u.datos['zoneIds'] as List?)?.contains(r.id) ?? false).length),
        if (x['active'] == false) t.sisInactiva,
      ],
      Catalogo.fechasPago => [
        [
          t.sisPago(v('payFrom'), v('payTo')),
          t.sisFacturaDia(v('invoiceDay')),
          t.sisInstalaciones(v('installFrom'), v('installTo')),
        ].join(', '),
        _zonas(x['zoneIds']).isEmpty ? t.todasLasLocalidades : _zonas(x['zoneIds']),
      ],
      Catalogo.zonas => [widget.nombresZonas[v('localityId')] ?? v('localityId'), v('description')],
      Catalogo.servicios => [
        v('description'),
        [
          if (x['commission'] == true) t.sisLlevaComision,
          if (x['billable'] == true) t.sisLlevaCobro,
          if (x['materialsOn'] == true) t.sisLlevaMateriales,
        ].join(' · '),
      ],
      Catalogo.comisiones => [dinero2('amount')],
      Catalogo.comisionistas => [
        v('description'),
        _zonas(x['zoneIds']).isEmpty ? t.todasLasLocalidades : _zonas(x['zoneIds']),
      ],
      Catalogo.activos || Catalogo.insumos => [
        [d.nombres[v('categoryId')] ?? '', v('brand'), v('model')].where((e) => e.isNotEmpty).join(' · '),
        [dinero2('price'), v('unit')].where((e) => e.isNotEmpty).join(' · '),
      ],
      Catalogo.motivosCancelacion => [if (x['other'] == true) t.sisPideMotivo],
      Catalogo.cobros => [d.nombres[v('serviceId')] ?? '', dinero2('amount')],
      Catalogo.ocupaciones || Catalogo.formasPago => [v('description')],
      Catalogo.partidasGasto => [v('description'), if (v('auto').isNotEmpty) t.sisAutomatica],
    }.where((e) => e.isNotEmpty).toList();
  }

  /// Abre el formulario (r null = nuevo) y, si se guardó o se borró, vuelve a leer la lista.
  Future<void> _abrir(Registro? r) async {
    final _Datos d;
    try {
      d = await _carga;
    } catch (_) {
      return; // la lista no se pudo leer: el aviso ya está en pantalla
    }
    if (widget.catalogo == Catalogo.usuarios) return _abrirUsuario(r, d);
    if (!mounted) return;
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFormCatalogo(
          catalogo: widget.catalogo,
          titulo: widget.titulo,
          servicio: widget.servicio,
          tecnico: widget.tecnico,
          nombresZonas: widget.nombresZonas,
          existentes: d.todos,
          registro: r,
          categorias: widget.catalogo == Catalogo.activos ? d.nombres : const {},
          comisiones: widget.catalogo == Catalogo.comisionistas ? d.extra : const [],
        ),
      ),
    );
    if (cambio == true && mounted) setState(() => _carga = _leer());
  }

  Future<void> _abrirUsuario(Registro? r, _Datos d) async {
    final List<Registro> ocupaciones;
    try {
      ocupaciones = await widget.servicio.registros('occupations');
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFormUsuario(
          servicio: ServicioUsuarios(widget.servicio),
          tecnico: widget.tecnico,
          nombresZonas: widget.nombresZonas,
          existentes: d.todos,
          roles: ordenarCatalogo(Catalogo.roles, d.extra),
          ocupaciones: ordenarCatalogo(Catalogo.ocupaciones, ocupaciones),
          registro: r,
        ),
      ),
    );
    if (cambio == true && mounted) setState(() => _carga = _leer());
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${t.menuSistema} › ${widget.titulo}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(null),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.sisAgregar),
      ),
      body: FutureBuilder<_Datos>(
        future: _carga,
        builder: (context, foto) {
          final cargando = cargaOError(t, foto);
          if (cargando != null) return cargando;
          final d = foto.data!;
          final q = plano(_buscar.trim());
          final filas = [
            for (final r in d.lista)
              if (q.isEmpty || plano([nombreDe(r), ..._detalle(t, r, d)].join(' ')).contains(q)) r,
          ];
          return listaRecargable(
            alRecargar: () async {
              setState(() => _carga = _leer(recargar: true));
              await _carga;
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _buscar = v),
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: t.sisBuscar),
                ),
              ),
              if (filas.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: AvisoCentral(icono: Icons.inventory_outlined, texto: t.sisVacio),
                ),
              TituloSeccion(texto: widget.titulo, cuantas: filas.length),
              for (var i = 0; i < filas.length; i++)
                Aparecer(
                  orden: i,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Presionable(
                      radio: 20,
                      alTocar: () => _abrir(filas[i]),
                      child: Superficie(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreDe(filas[i]).isEmpty ? filas[i].id : nombreDe(filas[i]),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            for (final l in _detalle(t, filas[i], d))
                              Text(l, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
