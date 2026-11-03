import 'package:flutter/material.dart';

import '../l10n/textos.dart';
import '../logica/sistema.dart';
import '../logica/telefono.dart';
import '../logica/usuarios.dart';
import '../servicios/sesion.dart';
import '../servicios/usuarios.dart';
import 'campos.dart';
import 'comun.dart';
import 'form_catalogo.dart';

/// Sistema › Usuarios app › agregar o cambiar (solo el administrador), con los campos del formulario de usuarios de la
/// web: datos, rol, localidades, sueldo y su entrada a la app (usuario y contraseña). Devuelve true si se guardó o se
/// borró.
class PantallaFormUsuario extends StatefulWidget {
  const PantallaFormUsuario({
    super.key,
    required this.servicio,
    required this.tecnico,
    required this.nombresZonas,
    required this.existentes,
    required this.roles,
    required this.ocupaciones,
    this.registro,
  });

  final ServicioUsuarios servicio;
  final Tecnico tecnico;
  final Map<String, String> nombresZonas;
  final List<Registro> existentes;
  final List<Registro> roles;
  final List<Registro> ocupaciones;

  /// null = nuevo.
  final Registro? registro;

  @override
  State<PantallaFormUsuario> createState() => _PantallaFormUsuarioState();
}

class _PantallaFormUsuarioState extends State<PantallaFormUsuario> with GuardarYCerrar {
  late final Map<String, dynamic> _antes = widget.registro?.datos ?? const {};
  String _texto(String c) => '${_antes[c] ?? ''}';

  late final _nombre = TextEditingController(text: _texto('name'));
  late final _tel = separarTelefono(_texto('phone'));
  late final _telefono = TextEditingController(text: _tel?.local ?? _texto('phone'));
  late String _pais = _tel?.iso ?? 'MX';
  late final _correo = TextEditingController(text: _texto('email'));
  late String? _rol = widget.roles.any((r) => r.id == _antes['role']) ? _texto('role') : null;
  late String _ocupacion = widget.ocupaciones.any((r) => r.id == _antes['occupation']) ? _texto('occupation') : '';
  late final _zonas = <String>{...zonasDeUsuario(_antes)};
  late bool _asalariado = _antes['salaried'] == true;
  late final _sueldo = TextEditingController(text: _texto('salaryWeekly'));
  late bool _comisionista = _antes['commissioner'] == true;
  late bool _acceso = widget.registro == null || (_antes['appAccess'] != false && _texto('username').isNotEmpty);
  late final _usuario = TextEditingController(text: _texto('username'));
  final _contrasena = TextEditingController();
  bool _verContrasena = false;

  @override
  void dispose() {
    for (final c in [_nombre, _telefono, _correo, _sueldo, _usuario, _contrasena]) {
      c.dispose();
    }
    super.dispose();
  }

  DatosUsuario _leer() {
    final sueldo = _sueldo.text.trim().replaceAll(',', '.');
    return (
      nombre: _nombre.text,
      telefono: telefonoInternacional(_telefono.text, _pais),
      correo: _correo.text,
      rol: _rol ?? '',
      ocupacion: _ocupacion,
      zonas: [
        for (final z in widget.nombresZonas.keys)
          if (_zonas.contains(z)) z,
      ],
      asalariado: _asalariado,
      sueldo: sueldo.isEmpty ? null : (double.tryParse(sueldo) ?? double.nan),
      comisionista: _comisionista,
      acceso: _acceso,
      usuario: _usuario.text,
      contrasena: _contrasena.text,
    );
  }

  Future<void> _guardar() async {
    final t = Textos.of(context);
    final d = _leer();
    final fallo = revisarUsuario(d, widget.existentes, antes: widget.registro);
    if (fallo != null) {
      setState(
        () => error = switch (fallo) {
          FalloUsuario.faltaNombre => t.errSisNombre,
          FalloUsuario.telefono => t.errUsuTelefono,
          FalloUsuario.correo => t.errUsuCorreo,
          FalloUsuario.correoRepetido => t.errUsuCorreoRepetido,
          FalloUsuario.faltaRol => t.errUsuRol,
          FalloUsuario.sueldo => t.errUsuSueldo,
          FalloUsuario.faltaUsuario => t.errUsuUsuario,
          FalloUsuario.usuarioFormato => t.errUsuUsuarioFormato,
          FalloUsuario.usuarioOcupado => t.errUsuUsuarioOcupado,
          FalloUsuario.faltaContrasena => t.errUsuContrasena,
          FalloUsuario.contrasenaCorta => t.errUsuContrasenaCorta,
        },
      );
      return;
    }
    final permiso = '${widget.roles.where((r) => r.id == d.rol).firstOrNull?.datos['permission'] ?? ''}';
    // si la ficha se guardó pero su acceso no, se cierra igual con el aviso (guardar otra vez la duplicaría)
    ErrorDeCuenta? sinAcceso;
    await guardarYCerrar(() async {
      try {
        return await widget.servicio.guardar(
          d,
          antes: widget.registro,
          permiso: permiso,
          nombresZonas: widget.nombresZonas,
        );
      } on ErrorDeCuenta catch (e) {
        sinAcceso = e;
        return true;
      }
    }, listo: () => sinAcceso == null ? t.sisGuardado : t.errUsuCuenta(sinAcceso!.codigo));
  }

  Future<void> _borrar() => borrarConPregunta(
    widget.registro!,
    Textos.of(context).usuBorrarTexto,
    () => widget.servicio.borrar(widget.registro!, widget.tecnico),
  );

  Widget _desplegable(String etiqueta, String? valor, Map<String, String> opciones, ValueChanged<String?> alCambiar) =>
      DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        decoration: InputDecoration(labelText: etiqueta),
        items: [
          for (final MapEntry(key: id, value: nombre) in opciones.entries)
            DropdownMenuItem(value: id, child: Text(nombre)),
        ],
        onChanged: (x) => setState(() => alCambiar(x)),
      );

  @override
  Widget build(BuildContext context) {
    final t = Textos.of(context);
    final r = widget.registro;
    const hueco = SizedBox(height: 16);
    return FormularioSistema(
      titulo: t.menuUsuariosApp,
      registro: r,
      guardando: guardando,
      error: error,
      // uno mismo no se borra (se quedaría sin entrar)
      alBorrar: r != null && r.id != widget.tecnico.userId ? _borrar : null,
      alGuardar: _guardar,
      children: [
        TextField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: t.sisCampoName),
        ),
        hueco,
        CampoTelefono(controller: _telefono, pais: _pais, alCambiarPais: (p) => setState(() => _pais = p)),
        hueco,
        TextField(
          controller: _correo,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(labelText: t.usuCorreo, helperText: t.foOpcional),
        ),
        hueco,
        _desplegable(t.usuRol, _rol, {for (final x in widget.roles) x.id: nombreDe(x)}, (x) => _rol = x),
        hueco,
        _desplegable(t.usuOcupacion, _ocupacion, {
          '': t.usuSinOcupacion,
          for (final x in widget.ocupaciones) x.id: nombreDe(x),
        }, (x) => _ocupacion = x ?? ''),
        hueco,
        Text(t.sisCampoZoneIds, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(t.usuLocalidadesAyuda, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final MapEntry(key: id, value: nombre) in widget.nombresZonas.entries)
              FilterChip(
                label: Text(nombre),
                selected: _zonas.contains(id),
                onSelected: (si) => setState(() => si ? _zonas.add(id) : _zonas.remove(id)),
              ),
          ],
        ),
        hueco,
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.usuAsalariado),
          value: _asalariado,
          onChanged: (x) => setState(() => _asalariado = x),
        ),
        if (_asalariado)
          TextField(
            controller: _sueldo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: t.usuSueldo, prefixText: r'$ '),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.usuComisionista),
          value: _comisionista,
          onChanged: (x) => setState(() => _comisionista = x),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.usuAcceso),
          value: _acceso,
          onChanged: (x) => setState(() => _acceso = x),
        ),
        if (_acceso) ...[
          TextField(
            controller: _usuario,
            autocorrect: false,
            decoration: InputDecoration(labelText: t.usuUsuario, helperText: t.usuUsuarioAyuda, helperMaxLines: 2),
          ),
          hueco,
          TextField(
            controller: _contrasena,
            obscureText: !_verContrasena,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: t.usuContrasena,
              helperText: tieneAcceso(r) ? t.usuContrasenaCambiar : t.usuContrasenaNueva,
              suffixIcon: IconButton(
                tooltip: _verContrasena ? t.usuOcultar : t.usuMostrar,
                onPressed: () => setState(() => _verContrasena = !_verContrasena),
                icon: Icon(_verContrasena ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              ),
            ),
          ),
        ],
        hueco,
      ],
    );
  }
}
