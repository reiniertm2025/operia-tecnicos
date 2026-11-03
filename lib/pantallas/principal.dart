import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../l10n/textos.dart';
import '../logica/fechas.dart';
import '../logica/menu.dart';
import '../logica/sistema.dart';
import '../logica/orden.dart';
import '../logica/tablero.dart';
import '../servicios/ajustes.dart';
import '../servicios/avisos.dart';
import '../servicios/ordenes.dart';
import '../servicios/sesion.dart';
import 'ayuda.dart';
import 'comun.dart';
import 'dashboard.dart';
import 'finanzas.dart';
import 'detalle_orden.dart';
import 'diseno.dart';
import 'form_orden.dart';
import 'historial.dart';
import 'inconclusas.dart';
import 'comisiones.dart';
import 'ips.dart';
import 'mapa_dia.dart';
import 'modems.dart';
import 'nuevos_cancelados.dart';
import 'por_autorizar.dart';
import 'sistema.dart';
import 'prospectos.dart';
import 'terminos.dart';

/// Pantalla después de entrar: encabezado con el saludo y los totales del día, filtro por localidad y
/// menú de abajo (Pendientes, En proceso, Culminadas de hoy, Historial).
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({
    super.key,
    required this.tecnico,
    required this.ajustes,
    required this.alSalir,
    this.ordenes,
  });

  final Tecnico tecnico;
  final Ajustes ajustes;
  final VoidCallback alSalir;
  final ServicioOrdenes? ordenes;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late final ServicioOrdenes _servicio = widget.ordenes ?? ServicioOrdenes();
  late final Stream<List<Orden>> _abiertas = _servicio.abiertas(widget.tecnico);
  late final Stream<List<Orden>> _culminadas = _servicio.culminadasHoy();
  Map<String, String> _nombresZonas = const {};
  String? _zona;
  RangoDias? _rango;
  final _buscador = TextEditingController();
  String _buscar = '';
  int _pestana = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _encenderAvisos());
    _servicio
        .zonas()
        .then((z) {
          if (mounted) setState(() => _nombresZonas = z);
        })
        .catchError((_) {
          // sin nombres de localidad la lista sigue sirviendo
        });
  }

  /// Aviso fijo de órdenes nuevas (si falla, la app sigue funcionando sin avisos).
  Future<void> _encenderAvisos() async {
    if (!mounted || widget.ordenes != null) return; // en las pruebas no hay servicio de Android
    final t = Textos.of(context);
    final idioma = Localizations.localeOf(context).languageCode;
    try {
      Avisos.preparar(t);
      await Avisos.encender(widget.tecnico, idioma, t);
    } catch (_) {
      // sin permiso o sin servicio: solo no habrá avisos
    }
  }

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  /// Las órdenes que coinciden con lo escrito en el buscador.
  List<Orden> _filtrar(List<Orden> ordenes) =>
      ordenes.where((o) => coincideBusqueda(o, _buscar, zona: _nombresZonas[o.zonaId] ?? '')).toList();

  /// Localidades del filtro: el administrador, todas; el técnico, las suyas.
  List<String> get _zonasDelFiltro {
    final ids = widget.tecnico.esAdmin ? _nombresZonas.keys.toList() : widget.tecnico.zonas;
    // en el orden de la web (`zonas()` ya viene ordenado); las desconocidas al final
    final orden = _nombresZonas.keys.toList();
    int lugar(String id) => orden.contains(id) ? orden.indexOf(id) : orden.length;
    return [...ids]..sort((a, b) => lugar(a).compareTo(lugar(b)));
  }

  Future<void> _abrir(Orden o, String hero) async {
    final resultado = await Navigator.push<ResultadoDetalle>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaDetalleOrden(
          orden: o,
          zonas: _nombresZonas,
          tecnico: widget.tecnico,
          servicio: _servicio,
          hero: hero,
        ),
      ),
    );
    // al aceptar una orden, se pasa directo a «En proceso», donde ya aparece
    if (resultado == ResultadoDetalle.aceptada && mounted) setState(() => _pestana = 1);
  }

  /// Técnicos y administradores crean órdenes; los de consulta no.
  Future<void> _nuevaOrden() async {
    final t = Textos.of(context);
    final avisos = ScaffoldMessenger.of(context);
    final folio = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaFormOrden(tecnico: widget.tecnico, servicio: _servicio, nombresZonas: _nombresZonas),
      ),
    );
    if (folio is OrdenCreada) avisos.showSnackBar(SnackBar(content: Text(t.ordenCreada(folio.folio))));
  }

  Future<void> _confirmarSalida() async {
    final t = Textos.of(context);
    final salir = await confirmar(
      context,
      icono: Icons.logout,
      titulo: t.cerrarSesionPregunta,
      texto: t.cerrarSesionTexto,
      boton: t.cerrarSesion,
    );
    if (salir) widget.alSalir();
  }

  /// Hoja de abajo para elegir una opción (idioma, apariencia); devuelve la elegida o null.
  Future<T?> _elegir<T>(String titulo, T actual, List<(T, IconData, String)> opciones) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colores = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final (valor, icono, nombre) in opciones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Presionable(
                      radio: 16,
                      alTocar: () => Navigator.pop(context, valor),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: valor == actual ? colores.primary.withValues(alpha: 0.1) : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: valor == actual ? colores.primary : colores.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(icono, color: valor == actual ? colores.primary : colores.onSurfaceVariant),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            if (valor == actual) Icon(Icons.check_circle_rounded, color: colores.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _elegirIdioma() async {
    final t = Textos.of(context);
    final elegido = await _elegir(t.menuIdioma, widget.ajustes.idioma.value?.languageCode ?? '', [
      ('', Icons.phone_android_rounded, t.idiomaAutomatico),
      ('es', Icons.translate_rounded, t.idiomaEspanol),
      ('en', Icons.translate_rounded, t.idiomaIngles),
    ]);
    if (elegido == null) return;
    await widget.ajustes.cambiarIdioma(elegido.isEmpty ? null : Locale(elegido));
  }

  Future<void> _elegirTema() async {
    final t = Textos.of(context);
    final elegido = await _elegir(t.menuApariencia, widget.ajustes.tema.value, [
      (ThemeMode.system, Icons.brightness_auto_rounded, t.temaAutomatico),
      (ThemeMode.light, Icons.light_mode_rounded, t.temaClaro),
      (ThemeMode.dark, Icons.dark_mode_rounded, t.temaOscuro),
    ]);
    if (elegido != null) await widget.ajustes.cambiarTema(elegido);
  }

  /// Cierra el menú y abre otra pantalla.
  void _ir(WidgetBuilder pantalla) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: pantalla));
  }

  void _verIps() {
    Navigator.pop(context); // cierra el menú
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaIps(tecnico: widget.tecnico, nombresZonas: _nombresZonas),
      ),
    );
  }

  void _verAyuda(int pestana) {
    Navigator.pop(context); // cierra el menú
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaAyuda(tecnico: widget.tecnico, pestanaInicial: pestana),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final zonas = _zonasDelFiltro;
    return EscuchaTablero(
      tecnico: widget.tecnico,
      abiertas: _abiertas,
      culminadas: _culminadas,
      zona: _zona,
      builder: (context, tablero, estado) {
        final error = estado.error;
        final cargando = estado.cargando;
        final cuerpo = switch (_pestana) {
          3 => PestanaHistorial(
            key: ValueKey('historial-$_zona-$_rango'),
            tecnico: widget.tecnico,
            servicio: _servicio,
            zona: _zona,
            nombresZonas: _nombresZonas,
            alAbrir: (o) => _abrir(o, heroDe('historial', o)),
            rango: _rango,
            buscar: _buscar,
            alCambiarRango: (r) => setState(() => _rango = r),
          ),
          _ when error != null => AvisoCentral(icono: Icons.cloud_off_rounded, texto: textoErrorCarga(t, error)),
          _ when cargando => const ListaEsqueleto(),
          0 => _porDia(_filtrar(tablero.pendientes), t.vacioPendientes, Icons.inbox_rounded, 'pendientes'),
          1 => _porDia(_filtrar(tablero.enProceso), t.vacioEnProceso, Icons.task_alt_rounded, 'proceso'),
          _ => _lista(_filtrar(tablero.culminadas), t.vacioCulminadas, Icons.celebration_rounded, 'culminadas'),
        };
        return Scaffold(
          drawer: _menu(t),
          floatingActionButton: widget.tecnico.soloMirar
              ? null
              : FloatingActionButton.extended(
                  onPressed: _nuevaOrden,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(t.nuevaOrden),
                ),
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [_encabezado(t, tablero, zonas)],
            body: Column(
              children: [
                _barraBuscar(t),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (hijo, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
                        child: hijo,
                      ),
                    ),
                    child: KeyedSubtree(key: ValueKey('$_pestana-$_zona-${cargando || error != null}'), child: cuerpo),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(boxShadow: sombra(context, 2)),
            child: NavigationBar(
              selectedIndex: _pestana,
              animationDuration: const Duration(milliseconds: 500),
              onDestinationSelected: (i) => setState(() => _pestana = i),
              destinations: [
                _destino(Icons.schedule_outlined, Icons.schedule_rounded, t.navPendientes, tablero.pendientes.length),
                _destino(Icons.build_outlined, Icons.build_rounded, t.navEnProceso, tablero.enProceso.length),
                _destino(
                  Icons.check_circle_outline,
                  Icons.check_circle_rounded,
                  t.navCulminadas,
                  tablero.culminadas.length,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.history),
                  selectedIcon: const Icon(Icons.history_rounded),
                  label: t.navHistorial,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  NavigationDestination _destino(IconData icono, IconData elegido, String texto, int cuantas) => NavigationDestination(
    icon: Badge(isLabelVisible: cuantas > 0, label: Text('$cuantas'), child: Icon(icono)),
    selectedIcon: Badge(isLabelVisible: cuantas > 0, label: Text('$cuantas'), child: Icon(elegido)),
    label: texto,
  );

  /// Encabezado azul: saludo, fecha y totales; al bajar se encoge y queda el título con el filtro.
  Widget _encabezado(Textos t, Tablero tablero, List<String> zonas) {
    final conFiltro = zonas.length > 1;
    final idioma = Localizations.localeOf(context).toLanguageTag();
    final hoy = DateFormat.MMMMEEEEd(idioma).format(DateTime.now());
    final titulos = [t.navPendientes, t.navEnProceso, t.navCulminadas, t.navHistorial];
    return encabezadoAzul(
      alto: 236 + (conFiltro ? 56 : 0),
      titulo: Text(titulos[_pestana]),
      acciones: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SvgPicture.asset('assets/logo.svg', width: 32, height: 32),
        ),
      ],
      abajo: filtroSiHayVarias(
        t,
        zonas: zonas,
        nombres: _nombresZonas,
        elegida: _zona,
        alElegir: (z) => setState(() => _zona = z),
      ),
      relleno: EdgeInsets.fromLTRB(20, kToolbarHeight + 4, 20, conFiltro ? 64 : 18),
      contenido: [
        Text(
          t.hola(widget.tecnico.nombre.isEmpty ? t.tecnico : widget.tecnico.nombre),
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
        const SizedBox(height: 2),
        Text(hoy, style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 14)),
        const SizedBox(height: 16),
        Row(
          children: [
            TotalCristal(
              texto: t.navPendientes,
              cuantas: tablero.pendientes.length,
              color: const Color(0xFFFBBF24),
              elegido: _pestana == 0,
              alTocar: () => setState(() => _pestana = 0),
            ),
            const SizedBox(width: 10),
            TotalCristal(
              texto: t.navEnProceso,
              cuantas: tablero.enProceso.length,
              color: const Color(0xFF818CF8),
              elegido: _pestana == 1,
              alTocar: () => setState(() => _pestana = 1),
            ),
            const SizedBox(width: 10),
            TotalCristal(
              texto: t.navCulminadas,
              cuantas: tablero.culminadas.length,
              color: const Color(0xFF34D399),
              elegido: _pestana == 2,
              alTocar: () => setState(() => _pestana = 2),
            ),
          ],
        ),
      ],
    );
  }

  /// Buscador de la pestaña que se ve (en Historial busca en lo que ya se cargó).
  Widget _barraBuscar(Textos t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: TextField(
      controller: _buscador,
      onChanged: (v) => setState(() => _buscar = v),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: t.buscarOrdenes,
        suffixIcon: _buscar.isEmpty
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _buscador.clear();
                  setState(() => _buscar = '');
                },
              ),
      ),
    ),
  );

  /// Lista vacía: si hay algo escrito en el buscador, lo dice.
  Widget _vacio(String vacio, IconData icono) => _buscar.trim().isEmpty
      ? AvisoCentral(icono: icono, texto: vacio)
      : AvisoCentral(icono: Icons.search_off_rounded, texto: Textos.of(context).buscarSinResultados(_buscar.trim()));

  Widget _porDia(List<Orden> ordenes, String vacio, IconData icono, String lugar) {
    final t = Textos.of(context);
    final grupos = OrdenesDelTecnico(ordenes, textoDia(DateTime.now()));
    if (grupos.vacio) return _vacio(vacio, icono);
    var posicion = 0;
    List<Widget> seccion(String titulo, List<Orden> lista, Color? color) {
      if (lista.isEmpty) return const [];
      return [
        TituloSeccion(texto: titulo, cuantas: lista.length, color: color),
        for (final o in lista) _tarjeta(o, lugar, posicion++),
      ];
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      children: [
        ...seccion(t.atrasadas, grupos.atrasadas, Theme.of(context).colorScheme.error),
        ...seccion(t.hoy, grupos.deHoy, null),
        ...seccion(t.proximosDias, grupos.proximas, null),
      ],
    );
  }

  Widget _lista(List<Orden> ordenes, String vacio, IconData icono, String lugar) {
    if (ordenes.isEmpty) return _vacio(vacio, icono);
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 96),
      children: [for (var i = 0; i < ordenes.length; i++) _tarjeta(ordenes[i], lugar, i)],
    );
  }

  Widget _tarjeta(Orden o, String lugar, int posicion) {
    final hero = heroDe(lugar, o);
    return TarjetaOrden(
      key: ValueKey(o.id),
      orden: o,
      zona: _nombresZonas[o.zonaId] ?? o.zonaId,
      verTecnico: widget.tecnico.esAdmin,
      hero: hero,
      posicion: posicion,
      alTocar: () => _abrir(o, hero),
    );
  }

  Widget _menu(Textos t) {
    final yo = widget.tecnico;
    final colores = Theme.of(context).colorScheme;
    final misZonas = yo.esAdmin ? t.todasLasLocalidades : yo.zonas.map((z) => _nombresZonas[z] ?? z).join(', ');
    final inicial = (yo.nombre.isEmpty ? t.tecnico : yo.nombre).characters.first.toUpperCase();
    return NavigationDrawer(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            gradient: Marca.degradado,
            borderRadius: BorderRadius.circular(24),
            boxShadow: sombra(context, 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Marca.cielo, Marca.azul]),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Text(
                      inicial,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  SvgPicture.asset('assets/logo.svg', width: 36, height: 36),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                yo.nombre.isEmpty ? t.tecnico : yo.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              if (yo.rol.isNotEmpty)
                Text(
                  yo.rol,
                  style: const TextStyle(color: Color(0xFF7DD3FC), fontWeight: FontWeight.w500),
                ),
              if (misZonas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, color: Colors.white60, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(misZonas, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        ..._menuDelRol(t),
        const Divider(indent: 24, endIndent: 24, height: 16),
        _opcion(Icons.menu_book_rounded, t.menuAyuda, () => _verAyuda(0)),
        _opcion(Icons.auto_awesome_rounded, t.menuNovedades, () => _verAyuda(1)),
        _opcion(Icons.gavel_rounded, t.terminosTitulo, () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaTerminos(tecnico: widget.tecnico)));
        }),
        _opcion(Icons.translate_rounded, t.menuIdioma, () {
          Navigator.pop(context);
          _elegirIdioma();
        }),
        _opcion(Icons.contrast_rounded, t.menuApariencia, () {
          Navigator.pop(context);
          _elegirTema();
        }),
        const Divider(indent: 24, endIndent: 24, height: 24),
        _opcion(Icons.logout_rounded, t.cerrarSesion, () {
          Navigator.pop(context);
          _confirmarSalida();
        }, color: colores.error),
      ],
    );
  }

  /// El menú según quién entró (`menuPara`): el administrador en grupos como la web; el técnico, solo lo suyo.
  List<Widget> _menuDelRol(Textos t) {
    final yo = widget.tecnico;
    void pestana(int i) {
      Navigator.pop(context);
      setState(() => _pestana = i);
    }

    Widget opcion(OpcionMenu o) => switch (o) {
      OpcionMenu.dashboard => _opcion(
        Icons.insights_rounded,
        t.menuDashboard,
        () => _ir((_) => PantallaDashboard(servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.delDia => _opcion(Icons.today_rounded, t.menuDelDia, () => pestana(0)),
      OpcionMenu.mapaDia => _opcion(
        Icons.map_rounded,
        t.menuMapaDia,
        () => _ir((_) => PantallaMapaDia(tecnico: yo, servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.historico => _opcion(Icons.history_rounded, t.menuHistorico, () => pestana(3)),
      OpcionMenu.inconclusas => _opcion(
        Icons.flag_rounded,
        t.menuInconclusas,
        () => _ir((_) => PantallaInconclusas(tecnico: yo, servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.prospectos => _opcion(
        Icons.person_search_rounded,
        t.menuProspectos,
        () => _ir((_) => PantallaProspectos(tecnico: yo, servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.futuro => _opcionAbiertas(Icons.calendar_month_rounded, t.menuFuturo, ListaAbiertas.futuro),
      OpcionMenu.nsPendientes => _opcionAbiertas(Icons.pending_rounded, t.menuNsPendientes, ListaAbiertas.nsPendientes),
      OpcionMenu.facturaIsp => _opcion(
        Icons.receipt_long_rounded,
        t.menuFacturaIsp,
        () => _ir((_) => PantallaFacturaIsp(tecnico: yo, servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.nsHistorico => _opcionPorDia(Icons.history_rounded, t.menuNsHistorico, ListaPorDia.nsHistorico),
      OpcionMenu.ncNuevos => _opcionPorDia(Icons.block_rounded, t.menuNcNuevos, ListaPorDia.ncNuevos),
      OpcionMenu.tvCable => _opcionPorDia(Icons.tv_rounded, t.menuTvCable, ListaPorDia.tvCable),
      OpcionMenu.tvDoblePlay => _opcionPorDia(Icons.satellite_alt_rounded, t.menuTvDoblePlay, ListaPorDia.tvDoblePlay),
      OpcionMenu.definitivos => _opcionPorDia(Icons.person_off_rounded, t.menuDefinitivos, ListaPorDia.definitivos),
      OpcionMenu.temporales => _opcion(
        Icons.pause_circle_outline_rounded,
        t.menuTemporales,
        () => _ir((_) => PantallaTemporales(servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.modems => _opcion(
        Icons.inventory_2_rounded,
        t.menuModems,
        () => _ir((_) => PantallaModems(tecnico: yo, servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.finanzas => _opcion(
        Icons.query_stats_rounded,
        t.menuResumenFinanzas,
        () => _ir((_) => PantallaFinanzas(servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.porAutorizar => _opcion(
        Icons.pending_actions_rounded,
        t.menuPorAutorizar,
        () => _ir((_) => PantallaPorAutorizar(tecnico: yo, servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.comisiones => _opcion(
        Icons.savings_rounded,
        t.menuComisiones,
        () => _ir((_) => PantallaComisiones(servicio: _servicio, nombresZonas: _nombresZonas)),
      ),
      OpcionMenu.ips => _opcion(Icons.lan_rounded, t.menuIps, _verIps),
      OpcionMenu.sisUsuarios => _opcionSistema(Icons.person_rounded, t.menuUsuariosApp, Catalogo.usuarios),
      OpcionMenu.sisRoles => _opcionSistema(Icons.admin_panel_settings_rounded, t.menuRoles, Catalogo.roles),
      OpcionMenu.sisOcupaciones => _opcionSistema(Icons.work_rounded, t.menuOcupacion, Catalogo.ocupaciones),
      OpcionMenu.sisLocalidades => _opcionSistema(Icons.location_city_rounded, t.menuLocalidades, Catalogo.localidades),
      OpcionMenu.sisFechasPago => _opcionSistema(Icons.event_available_rounded, t.menuFechasPago, Catalogo.fechasPago),
      OpcionMenu.sisZonas => _opcionSistema(Icons.pentagon_outlined, t.menuZonas, Catalogo.zonas),
      OpcionMenu.sisServicios => _opcionSistema(Icons.build_rounded, t.menuServicios, Catalogo.servicios),
      OpcionMenu.sisComisiones => _opcionSistema(
        Icons.volunteer_activism_rounded,
        t.menuComisionesCat,
        Catalogo.comisiones,
      ),
      OpcionMenu.sisComisionistas => _opcionSistema(Icons.badge_rounded, t.menuComisionistas, Catalogo.comisionistas),
      OpcionMenu.sisActivos => _opcionSistema(Icons.devices_other_rounded, t.menuActivos, Catalogo.activos),
      OpcionMenu.sisInsumos => _opcionSistema(Icons.category_rounded, t.menuInsumos, Catalogo.insumos),
      OpcionMenu.sisMotivosCancelacion => _opcionSistema(
        Icons.person_remove_rounded,
        t.menuMotivosCancelacion,
        Catalogo.motivosCancelacion,
      ),
      OpcionMenu.sisCobros => _opcionSistema(Icons.point_of_sale_rounded, t.menuCobroServicios, Catalogo.cobros),
      OpcionMenu.sisFormasPago => _opcionSistema(
        Icons.account_balance_wallet_outlined,
        t.menuFormasPago,
        Catalogo.formasPago,
      ),
      OpcionMenu.sisPartidasGasto => _opcionSistema(Icons.receipt_rounded, t.menuPartidaGastos, Catalogo.partidasGasto),
    };
    final (icono, nombre) = (
      {
        GrupoMenu.ordenesTrabajo: Icons.assignment_rounded,
        GrupoMenu.nuevosServicios: Icons.add_home_work_rounded,
        GrupoMenu.cancelados: Icons.block_rounded,
        GrupoMenu.recuperarModem: Icons.inventory_2_outlined,
        GrupoMenu.finanzas: Icons.account_balance_wallet_rounded,
        GrupoMenu.reportes: Icons.bar_chart_rounded,
        GrupoMenu.sistema: Icons.manage_accounts_rounded,
        GrupoMenu.herramientas: Icons.handyman_rounded,
      },
      {
        GrupoMenu.ordenesTrabajo: t.menuOrdenesTrabajo,
        GrupoMenu.nuevosServicios: t.menuNuevosServicios,
        GrupoMenu.cancelados: t.menuCancelados,
        GrupoMenu.recuperarModem: t.menuRecuperarModem,
        GrupoMenu.finanzas: t.menuFinanzas,
        GrupoMenu.reportes: t.menuReportes,
        GrupoMenu.sistema: t.menuSistema,
        GrupoMenu.herramientas: t.menuHerramientas,
      },
    );
    return [
      if (yo.esAdmin)
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 16, 4),
          child: Text(
            t.menuAdmin.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
          ),
        ),
      for (final sec in menuPara(yo))
        if (sec.grupo case final g?)
          _grupo(icono[g]!, nombre[g]!, [for (final o in sec.opciones) opcion(o)])
        else ...[
          for (final o in sec.opciones) opcion(o),
        ],
    ];
  }

  Widget _opcionAbiertas(IconData icono, String texto, ListaAbiertas lista) => _opcion(
    icono,
    texto,
    () => _ir(
      (_) => PantallaListaAbiertas(
        lista: lista,
        tecnico: widget.tecnico,
        servicio: _servicio,
        nombresZonas: _nombresZonas,
      ),
    ),
  );

  Widget _opcionPorDia(IconData icono, String texto, ListaPorDia lista) => _opcion(
    icono,
    texto,
    () => _ir(
      (_) =>
          PantallaListaPorDia(lista: lista, tecnico: widget.tecnico, servicio: _servicio, nombresZonas: _nombresZonas),
    ),
  );

  Widget _opcionSistema(IconData icono, String texto, Catalogo catalogo) => _opcion(
    icono,
    texto,
    () => _ir(
      (_) => PantallaCatalogo(
        catalogo: catalogo,
        titulo: texto,
        servicio: _servicio,
        tecnico: widget.tecnico,
        nombresZonas: _nombresZonas,
      ),
    ),
  );

  /// Grupo que se abre y cierra, con sus opciones un poco adentro.
  Widget _grupo(IconData icono, String texto, List<Widget> opciones) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icono),
        title: Text(texto, style: const TextStyle(fontWeight: FontWeight.w500)),
        childrenPadding: const EdgeInsets.only(left: 12),
        children: opciones,
      ),
    ),
  );

  Widget _opcion(IconData icono, String texto, VoidCallback alTocar, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    child: ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icono, color: color),
      title: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: alTocar,
    ),
  );
}
