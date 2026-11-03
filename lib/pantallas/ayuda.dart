import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../ayuda/contenido.dart';
import '../l10n/textos.dart';
import '../servicios/sesion.dart';
import 'diseno.dart';

/// Ayuda: manual de uso, novedades de cada versión y datos de la app (textos en assets/ayuda).
class PantallaAyuda extends StatefulWidget {
  const PantallaAyuda({super.key, required this.tecnico, this.pestanaInicial = 0});

  final Tecnico tecnico;
  final int pestanaInicial;

  @override
  State<PantallaAyuda> createState() => _PantallaAyudaState();
}

class _PantallaAyudaState extends State<PantallaAyuda> {
  Future<ContenidoAyuda>? _contenido;
  String? _idioma;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final idioma = Localizations.localeOf(context).languageCode;
    if (idioma != _idioma) {
      _idioma = idioma;
      _contenido = cargarAyuda(idioma);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: widget.pestanaInicial,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.ayudaTitulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF0B1834),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          // sin SizedBox.expand el degradado mide 0 y no se ve (quedaba texto blanco sobre fondo claro)
          flexibleSpace: const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: Marca.degradado),
              child: DecoratedBox(decoration: BoxDecoration(gradient: Marca.brillo)),
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Marca.cielo,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: t.pestManual),
              Tab(text: t.pestNovedades),
              Tab(text: t.pestAcerca),
            ],
          ),
        ),
        body: FutureBuilder<ContenidoAyuda>(
          future: _contenido,
          builder: (context, s) {
            final c = s.data;
            if (c == null) return const ListaEsqueleto();
            return TabBarView(children: [_manual(c), _novedades(t, c), _acerca(t)]);
          },
        ),
      ),
    );
  }

  Widget _manual(ContenidoAyuda c) {
    final temas = [
      for (final m in c.manual)
        if (!m.soloAdmin || widget.tecnico.esAdmin) m,
    ];
    final textos = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < temas.length; i++)
          Aparecer(
            orden: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Superficie(
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(temas[i].titulo, style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    children: [for (final p in temas[i].pasos) _Punto(p)],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _novedades(Textos t, ContenidoAyuda c) {
    final colores = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < c.novedades.length; i++)
          Aparecer(
            orden: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Superficie(
                nivel: i == 0 ? 2 : 1,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: i == 0 ? const LinearGradient(colors: [Marca.cielo, Marca.azul]) : null,
                            color: i == 0 ? null : colores.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            t.version(c.novedades[i].numero),
                            style: TextStyle(
                              color: i == 0 ? Colors.white : colores.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          c.novedades[i].fecha,
                          style: textos.labelMedium?.copyWith(color: colores.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final cambio in c.novedades[i].cambios) _Punto(cambio),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _acerca(Textos t) {
    final textos = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Aparecer(
          child: Superficie(
            nivel: 2,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SvgPicture.asset('assets/logo.svg', width: 80, height: 80),
                const SizedBox(height: 14),
                Text(t.appTitulo, style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(t.acercaTexto, textAlign: TextAlign.center, style: textos.bodyMedium?.copyWith(height: 1.45)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Aparecer(
          orden: 1,
          child: Superficie(
            child: Column(
              children: [
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, s) => ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(t.versionInstalada),
                    subtitle: Text(s.data == null ? '' : '${s.data!.version} (${s.data!.buildNumber})'),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(t.usuarioActual),
                  subtitle: Text(widget.tecnico.nombre),
                ),
                if (widget.tecnico.rol.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(t.rol),
                    subtitle: Text(widget.tecnico.rol),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 10),
            child: Icon(Icons.check_circle_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
          ),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45))),
        ],
      ),
    );
  }
}
