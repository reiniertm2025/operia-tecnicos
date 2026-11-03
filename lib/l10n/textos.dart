import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'textos_en.dart';
import 'textos_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of Textos
/// returned by `Textos.of(context)`.
///
/// Applications need to include `Textos.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/textos.dart';
///
/// return MaterialApp(
///   localizationsDelegates: Textos.localizationsDelegates,
///   supportedLocales: Textos.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the Textos.supportedLocales
/// property.
abstract class Textos {
  Textos(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static Textos of(BuildContext context) {
    return Localizations.of<Textos>(context, Textos)!;
  }

  static const LocalizationsDelegate<Textos> delegate = _TextosDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitulo.
  ///
  /// In es, this message translates to:
  /// **'Operia Técnicos'**
  String get appTitulo;

  /// No description provided for @conectando.
  ///
  /// In es, this message translates to:
  /// **'Conectando'**
  String get conectando;

  /// No description provided for @tuMundo.
  ///
  /// In es, this message translates to:
  /// **'tu mundo'**
  String get tuMundo;

  /// No description provided for @loginSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Atiende tus órdenes de trabajo desde donde estés.'**
  String get loginSubtitulo;

  /// No description provided for @loginInstruccion.
  ///
  /// In es, this message translates to:
  /// **'Entra con el usuario y la contraseña que te dio la oficina.'**
  String get loginInstruccion;

  /// No description provided for @usuario.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get usuario;

  /// No description provided for @contrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get contrasena;

  /// No description provided for @verContrasena.
  ///
  /// In es, this message translates to:
  /// **'Ver contraseña'**
  String get verContrasena;

  /// No description provided for @ocultarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get ocultarContrasena;

  /// No description provided for @entrar.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get entrar;

  /// No description provided for @recordarDatos.
  ///
  /// In es, this message translates to:
  /// **'Recordar usuario y contraseña'**
  String get recordarDatos;

  /// No description provided for @errFaltanDatos.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu usuario y tu contraseña.'**
  String get errFaltanDatos;

  /// No description provided for @errDatosIncorrectos.
  ///
  /// In es, this message translates to:
  /// **'Usuario o contraseña incorrectos.'**
  String get errDatosIncorrectos;

  /// No description provided for @errTipoDesconocido.
  ///
  /// In es, this message translates to:
  /// **'Tipo de contraseña desconocido ({detalle}). Habla con la oficina.'**
  String errTipoDesconocido(String detalle);

  /// No description provided for @errSinAccesoApp.
  ///
  /// In es, this message translates to:
  /// **'Tu usuario no tiene acceso a la app. Pídeselo a la oficina.'**
  String get errSinAccesoApp;

  /// No description provided for @errCuentaDesactivada.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está desactivada. Habla con la oficina.'**
  String get errCuentaDesactivada;

  /// No description provided for @errDemasiadosIntentos.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos seguidos. Espera unos minutos y vuelve a intentar.'**
  String get errDemasiadosIntentos;

  /// No description provided for @errSinInternet.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión a internet. Revisa tus datos o el wifi.'**
  String get errSinInternet;

  /// No description provided for @errOtro.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar ({detalle}).'**
  String errOtro(String detalle);

  /// No description provided for @errYaTomada.
  ///
  /// In es, this message translates to:
  /// **'Otro técnico ya aceptó esta orden.'**
  String get errYaTomada;

  /// No description provided for @errSinPermiso.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para cambiar esta orden. Habla con la oficina.'**
  String get errSinPermiso;

  /// No description provided for @navPendientes.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get navPendientes;

  /// No description provided for @navEnProceso.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get navEnProceso;

  /// No description provided for @navCulminadas.
  ///
  /// In es, this message translates to:
  /// **'Culminadas'**
  String get navCulminadas;

  /// No description provided for @navHistorial.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get navHistorial;

  /// No description provided for @todas.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get todas;

  /// No description provided for @atrasadas.
  ///
  /// In es, this message translates to:
  /// **'Atrasadas'**
  String get atrasadas;

  /// No description provided for @hoy.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get hoy;

  /// No description provided for @proximosDias.
  ///
  /// In es, this message translates to:
  /// **'Próximos días'**
  String get proximosDias;

  /// No description provided for @seccion.
  ///
  /// In es, this message translates to:
  /// **'{titulo} ({n})'**
  String seccion(String titulo, int n);

  /// No description provided for @vacioPendientes.
  ///
  /// In es, this message translates to:
  /// **'No hay órdenes pendientes.'**
  String get vacioPendientes;

  /// No description provided for @vacioEnProceso.
  ///
  /// In es, this message translates to:
  /// **'No tienes órdenes en proceso.'**
  String get vacioEnProceso;

  /// No description provided for @vacioCulminadas.
  ///
  /// In es, this message translates to:
  /// **'Hoy todavía no se culmina ninguna orden.'**
  String get vacioCulminadas;

  /// No description provided for @vacioHistorial.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay órdenes en el historial.'**
  String get vacioHistorial;

  /// No description provided for @errorCargar.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las órdenes.\nRevisa tu internet.\n\n({detalle})'**
  String errorCargar(String detalle);

  /// No description provided for @cargarMas.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get cargarMas;

  /// No description provided for @hola.
  ///
  /// In es, this message translates to:
  /// **'Hola, {nombre}'**
  String hola(String nombre);

  /// No description provided for @todasLasLocalidades.
  ///
  /// In es, this message translates to:
  /// **'Todas las localidades'**
  String get todasLasLocalidades;

  /// No description provided for @menuAyuda.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y manual'**
  String get menuAyuda;

  /// No description provided for @menuNovedades.
  ///
  /// In es, this message translates to:
  /// **'Novedades'**
  String get menuNovedades;

  /// No description provided for @menuIdioma.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get menuIdioma;

  /// No description provided for @idiomaAutomatico.
  ///
  /// In es, this message translates to:
  /// **'Automático (el del teléfono)'**
  String get idiomaAutomatico;

  /// No description provided for @menuApariencia.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get menuApariencia;

  /// No description provided for @temaAutomatico.
  ///
  /// In es, this message translates to:
  /// **'Automático (como el teléfono)'**
  String get temaAutomatico;

  /// No description provided for @temaClaro.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get temaClaro;

  /// No description provided for @temaOscuro.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get temaOscuro;

  /// No description provided for @idiomaEspanol.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get idiomaEspanol;

  /// No description provided for @idiomaIngles.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get idiomaIngles;

  /// No description provided for @cerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get cerrarSesion;

  /// No description provided for @cerrarSesionPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get cerrarSesionPregunta;

  /// No description provided for @cerrarSesionTexto.
  ///
  /// In es, this message translates to:
  /// **'Tendrás que volver a escribir tu usuario y contraseña.'**
  String get cerrarSesionTexto;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión {v}'**
  String version(String v);

  /// No description provided for @estPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get estPendiente;

  /// No description provided for @estEnProceso.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get estEnProceso;

  /// No description provided for @estCompletada.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get estCompletada;

  /// No description provided for @estCancelada.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get estCancelada;

  /// No description provided for @estFaltaCobro.
  ///
  /// In es, this message translates to:
  /// **'Falta cobro'**
  String get estFaltaCobro;

  /// No description provided for @sinNombre.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get sinNombre;

  /// No description provided for @folio.
  ///
  /// In es, this message translates to:
  /// **'Folio {f}'**
  String folio(String f);

  /// No description provided for @orden.
  ///
  /// In es, this message translates to:
  /// **'Orden'**
  String get orden;

  /// No description provided for @sinTecnico.
  ///
  /// In es, this message translates to:
  /// **'Sin técnico'**
  String get sinTecnico;

  /// No description provided for @llamar.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get llamar;

  /// No description provided for @verEnMapa.
  ///
  /// In es, this message translates to:
  /// **'Ver en mapa'**
  String get verEnMapa;

  /// No description provided for @telefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get telefono;

  /// No description provided for @direccion.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get direccion;

  /// No description provided for @localidad.
  ///
  /// In es, this message translates to:
  /// **'Localidad'**
  String get localidad;

  /// No description provided for @servicio.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get servicio;

  /// No description provided for @diaServicio.
  ///
  /// In es, this message translates to:
  /// **'Día de servicio'**
  String get diaServicio;

  /// No description provided for @descripcion.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get descripcion;

  /// No description provided for @notaOficina.
  ///
  /// In es, this message translates to:
  /// **'Nota de la oficina'**
  String get notaOficina;

  /// No description provided for @tecnico.
  ///
  /// In es, this message translates to:
  /// **'Técnico'**
  String get tecnico;

  /// No description provided for @misComentarios.
  ///
  /// In es, this message translates to:
  /// **'Mis comentarios'**
  String get misComentarios;

  /// No description provided for @comentariosTecnico.
  ///
  /// In es, this message translates to:
  /// **'Comentarios del técnico'**
  String get comentariosTecnico;

  /// No description provided for @culminadaEl.
  ///
  /// In es, this message translates to:
  /// **'Culminada: {fecha}'**
  String culminadaEl(String fecha);

  /// No description provided for @guardarComentarios.
  ///
  /// In es, this message translates to:
  /// **'Guardar comentarios'**
  String get guardarComentarios;

  /// No description provided for @comentariosGuardados.
  ///
  /// In es, this message translates to:
  /// **'Comentarios guardados.'**
  String get comentariosGuardados;

  /// No description provided for @empezar.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get empezar;

  /// No description provided for @marcasteInicio.
  ///
  /// In es, this message translates to:
  /// **'Marcaste el inicio.'**
  String get marcasteInicio;

  /// No description provided for @aceptarOrden.
  ///
  /// In es, this message translates to:
  /// **'Aceptar orden'**
  String get aceptarOrden;

  /// No description provided for @aceptarPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Aceptar esta orden?'**
  String get aceptarPregunta;

  /// No description provided for @aceptarTexto.
  ///
  /// In es, this message translates to:
  /// **'Quedará a tu nombre y pasará a «En proceso». La oficina lo verá en la web.'**
  String get aceptarTexto;

  /// No description provided for @aceptar.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get aceptar;

  /// No description provided for @ordenAceptada.
  ///
  /// In es, this message translates to:
  /// **'La orden ya es tuya.'**
  String get ordenAceptada;

  /// No description provided for @termine.
  ///
  /// In es, this message translates to:
  /// **'Terminé'**
  String get termine;

  /// No description provided for @terminePregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Terminaste el trabajo?'**
  String get terminePregunta;

  /// No description provided for @terminarDirecto.
  ///
  /// In es, this message translates to:
  /// **'La orden quedará como completada.'**
  String get terminarDirecto;

  /// No description provided for @siTermine.
  ///
  /// In es, this message translates to:
  /// **'Sí, terminé'**
  String get siTermine;

  /// No description provided for @ordenCompletada.
  ///
  /// In es, this message translates to:
  /// **'Orden completada.'**
  String get ordenCompletada;

  /// No description provided for @msgCancelada.
  ///
  /// In es, this message translates to:
  /// **'Esta orden fue cancelada.'**
  String get msgCancelada;

  /// No description provided for @msgCompletada.
  ///
  /// In es, this message translates to:
  /// **'Orden completada.'**
  String get msgCompletada;

  /// No description provided for @msgOtroTecnico.
  ///
  /// In es, this message translates to:
  /// **'Esta orden la tiene {nombre}.'**
  String msgOtroTecnico(String nombre);

  /// No description provided for @otroTecnicoSinNombre.
  ///
  /// In es, this message translates to:
  /// **'otro técnico'**
  String get otroTecnicoSinNombre;

  /// No description provided for @sinSenal.
  ///
  /// In es, this message translates to:
  /// **'Sin señal: se enviará en cuanto haya internet.'**
  String get sinSenal;

  /// No description provided for @noSePudoAbrir.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir en este celular.'**
  String get noSePudoAbrir;

  /// No description provided for @cobroTitulo.
  ///
  /// In es, this message translates to:
  /// **'Cobro'**
  String get cobroTitulo;

  /// No description provided for @cobroPaso.
  ///
  /// In es, this message translates to:
  /// **'Paso {n} de 2'**
  String cobroPaso(int n);

  /// No description provided for @cobroQueSeCobro.
  ///
  /// In es, this message translates to:
  /// **'¿Qué se cobró?'**
  String get cobroQueSeCobro;

  /// No description provided for @cobroMarcaPlan.
  ///
  /// In es, this message translates to:
  /// **'Marca el plan que contrató {cliente}.'**
  String cobroMarcaPlan(String cliente);

  /// No description provided for @cobroMarcaServicio.
  ///
  /// In es, this message translates to:
  /// **'Marca lo que se le cobró a {cliente}.'**
  String cobroMarcaServicio(String cliente);

  /// No description provided for @elCliente.
  ///
  /// In es, this message translates to:
  /// **'el cliente'**
  String get elCliente;

  /// No description provided for @cobroSinConceptos.
  ///
  /// In es, this message translates to:
  /// **'No hay cobros registrados. Se agregan en la web, en Sistema › Cobro de servicios.'**
  String get cobroSinConceptos;

  /// No description provided for @importe.
  ///
  /// In es, this message translates to:
  /// **'Importe'**
  String get importe;

  /// No description provided for @comentarioCobro.
  ///
  /// In es, this message translates to:
  /// **'Comentario del cobro'**
  String get comentarioCobro;

  /// No description provided for @total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @continuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continuar;

  /// No description provided for @atras.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get atras;

  /// No description provided for @completarSinCobro.
  ///
  /// In es, this message translates to:
  /// **'Completar sin cobro'**
  String get completarSinCobro;

  /// No description provided for @cobroComoPago.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo pagó el cliente?'**
  String get cobroComoPago;

  /// No description provided for @pagoEfectivo.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get pagoEfectivo;

  /// No description provided for @pagoTransferencia.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get pagoTransferencia;

  /// No description provided for @pagoPendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de pago'**
  String get pagoPendiente;

  /// No description provided for @pagoSinCosto.
  ///
  /// In es, this message translates to:
  /// **'Sin costo'**
  String get pagoSinCosto;

  /// No description provided for @notaEfectivo.
  ///
  /// In es, this message translates to:
  /// **'La orden quedará completada.'**
  String get notaEfectivo;

  /// No description provided for @notaTransferencia.
  ///
  /// In es, this message translates to:
  /// **'Toma foto del comprobante: la oficina lo revisa en la web y completa la orden.'**
  String get notaTransferencia;

  /// No description provided for @notaPendiente.
  ///
  /// In es, this message translates to:
  /// **'La orden sigue en proceso hasta que la oficina lo autorice; el cliente quedará pendiente de pago.'**
  String get notaPendiente;

  /// No description provided for @notaSinCosto.
  ///
  /// In es, this message translates to:
  /// **'No se cobra. La orden sigue en proceso hasta que la oficina lo autorice.'**
  String get notaSinCosto;

  /// No description provided for @guardarCompletar.
  ///
  /// In es, this message translates to:
  /// **'Guardar y completar'**
  String get guardarCompletar;

  /// No description provided for @enviarOficina.
  ///
  /// In es, this message translates to:
  /// **'Enviar a la oficina'**
  String get enviarOficina;

  /// No description provided for @elegirFormaPago.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo pagó el cliente.'**
  String get elegirFormaPago;

  /// No description provided for @errImporteCobro.
  ///
  /// In es, this message translates to:
  /// **'Escribe un importe válido para «{nombre}».'**
  String errImporteCobro(String nombre);

  /// No description provided for @errNotaCobro.
  ///
  /// In es, this message translates to:
  /// **'Escribe un comentario que explique el cobro de «{nombre}».'**
  String errNotaCobro(String nombre);

  /// No description provided for @cobroEnviado.
  ///
  /// In es, this message translates to:
  /// **'Listo, se envió a la oficina.'**
  String get cobroEnviado;

  /// No description provided for @msgPorAutorizar.
  ///
  /// In es, this message translates to:
  /// **'Esperando que la oficina autorice el cobro.'**
  String get msgPorAutorizar;

  /// No description provided for @msgTransferencia.
  ///
  /// In es, this message translates to:
  /// **'La oficina revisará el comprobante de la transferencia y completará la orden.'**
  String get msgTransferencia;

  /// No description provided for @estPorAutorizar.
  ///
  /// In es, this message translates to:
  /// **'Por autorizar'**
  String get estPorAutorizar;

  /// No description provided for @ayudaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get ayudaTitulo;

  /// No description provided for @pestManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get pestManual;

  /// No description provided for @pestNovedades.
  ///
  /// In es, this message translates to:
  /// **'Novedades'**
  String get pestNovedades;

  /// No description provided for @pestAcerca.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get pestAcerca;

  /// No description provided for @acercaTexto.
  ///
  /// In es, this message translates to:
  /// **'App de los técnicos de Operia. Usa la misma información que la web: lo que haces aquí lo ve la oficina al momento.'**
  String get acercaTexto;

  /// No description provided for @versionInstalada.
  ///
  /// In es, this message translates to:
  /// **'Versión instalada'**
  String get versionInstalada;

  /// No description provided for @usuarioActual.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get usuarioActual;

  /// No description provided for @rol.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get rol;

  /// No description provided for @menuIps.
  ///
  /// In es, this message translates to:
  /// **'IPs libres'**
  String get menuIps;

  /// No description provided for @ipsDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Aparta la IP que vas a usar para que nadie más la tome.'**
  String get ipsDescripcion;

  /// No description provided for @ipsRouter.
  ///
  /// In es, this message translates to:
  /// **'Lista del router: {fecha}'**
  String ipsRouter(String fecha);

  /// No description provided for @ipsLibres.
  ///
  /// In es, this message translates to:
  /// **'Libres'**
  String get ipsLibres;

  /// No description provided for @ipsOcupadas.
  ///
  /// In es, this message translates to:
  /// **'Ocupadas'**
  String get ipsOcupadas;

  /// No description provided for @ipsMias.
  ///
  /// In es, this message translates to:
  /// **'Mías'**
  String get ipsMias;

  /// No description provided for @ipsTodas.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get ipsTodas;

  /// No description provided for @ipsBuscar.
  ///
  /// In es, this message translates to:
  /// **'Buscar IP o segmento'**
  String get ipsBuscar;

  /// No description provided for @ipsVacio.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay IPs publicadas para tus localidades. La oficina las publica desde la web, en Herramientas › IPs libres.'**
  String get ipsVacio;

  /// No description provided for @ipsSinFiltro.
  ///
  /// In es, this message translates to:
  /// **'No hay IPs con estos filtros.'**
  String get ipsSinFiltro;

  /// No description provided for @ipsVlan.
  ///
  /// In es, this message translates to:
  /// **'VLAN {vlan}'**
  String ipsVlan(String vlan);

  /// No description provided for @ipsCuantasLibres.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =1{1 libre} other{{n} libres}}'**
  String ipsCuantasLibres(int n);

  /// No description provided for @ipsLibre.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get ipsLibre;

  /// No description provided for @ipsOcupada.
  ///
  /// In es, this message translates to:
  /// **'Ocupada'**
  String get ipsOcupada;

  /// No description provided for @ipsDesdeApp.
  ///
  /// In es, this message translates to:
  /// **'desde la app'**
  String get ipsDesdeApp;

  /// No description provided for @ipsDesdeWeb.
  ///
  /// In es, this message translates to:
  /// **'desde la web'**
  String get ipsDesdeWeb;

  /// No description provided for @ipsApartar.
  ///
  /// In es, this message translates to:
  /// **'Apartar'**
  String get ipsApartar;

  /// No description provided for @ipsLiberar.
  ///
  /// In es, this message translates to:
  /// **'Liberar'**
  String get ipsLiberar;

  /// No description provided for @ipsApartarPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Apartar la IP {ip}?'**
  String ipsApartarPregunta(String ip);

  /// No description provided for @ipsApartarTexto.
  ///
  /// In es, this message translates to:
  /// **'Queda ocupada a tu nombre para que nadie más la use. La oficina y los demás técnicos lo ven al momento.'**
  String get ipsApartarTexto;

  /// No description provided for @ipsLiberarPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Liberar la IP {ip}?'**
  String ipsLiberarPregunta(String ip);

  /// No description provided for @ipsLiberarTexto.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a quedar libre para que otra persona la pueda usar.'**
  String get ipsLiberarTexto;

  /// No description provided for @ipsApartadaOk.
  ///
  /// In es, this message translates to:
  /// **'Apartaste la IP {ip}: ya sale ocupada.'**
  String ipsApartadaOk(String ip);

  /// No description provided for @ipsLiberadaOk.
  ///
  /// In es, this message translates to:
  /// **'Liberaste la IP {ip}.'**
  String ipsLiberadaOk(String ip);

  /// No description provided for @ipsCopiar.
  ///
  /// In es, this message translates to:
  /// **'Copiar IP'**
  String get ipsCopiar;

  /// No description provided for @ipsCopiada.
  ///
  /// In es, this message translates to:
  /// **'IP {ip} copiada.'**
  String ipsCopiada(String ip);

  /// No description provided for @errIpOcupada.
  ///
  /// In es, this message translates to:
  /// **'Esa IP ya no está libre: otra persona la ocupó o la oficina cambió la lista.'**
  String get errIpOcupada;

  /// No description provided for @ipsTodasVlan.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get ipsTodasVlan;

  /// No description provided for @ipsFiltroVlan.
  ///
  /// In es, this message translates to:
  /// **'VLAN'**
  String get ipsFiltroVlan;

  /// No description provided for @ipsFiltroSegmentos.
  ///
  /// In es, this message translates to:
  /// **'Segmentos (marca uno o varios)'**
  String get ipsFiltroSegmentos;

  /// No description provided for @terminosAntes.
  ///
  /// In es, this message translates to:
  /// **'Antes de empezar, {nombre}'**
  String terminosAntes(String nombre);

  /// No description provided for @terminosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get terminosTitulo;

  /// No description provided for @terminosActualizados.
  ///
  /// In es, this message translates to:
  /// **'Actualizados: {fecha}'**
  String terminosActualizados(String fecha);

  /// No description provided for @terminosDesliza.
  ///
  /// In es, this message translates to:
  /// **'Desliza hasta el final para poder aceptar'**
  String get terminosDesliza;

  /// No description provided for @terminosLeiAcepto.
  ///
  /// In es, this message translates to:
  /// **'Leí y acepto los términos y condiciones'**
  String get terminosLeiAcepto;

  /// No description provided for @terminosAceptar.
  ///
  /// In es, this message translates to:
  /// **'Aceptar y entrar'**
  String get terminosAceptar;

  /// No description provided for @terminosNoAcepto.
  ///
  /// In es, this message translates to:
  /// **'No acepto'**
  String get terminosNoAcepto;

  /// No description provided for @terminosSalirPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Salir sin aceptar?'**
  String get terminosSalirPregunta;

  /// No description provided for @terminosSalirTexto.
  ///
  /// In es, this message translates to:
  /// **'Para usar la app necesitas aceptar los términos y condiciones. Puedes volver a entrar cuando quieras.'**
  String get terminosSalirTexto;

  /// No description provided for @terminosSalir.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get terminosSalir;

  /// No description provided for @histTodasFechas.
  ///
  /// In es, this message translates to:
  /// **'Todas las fechas'**
  String get histTodasFechas;

  /// No description provided for @histSemana.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get histSemana;

  /// No description provided for @histMes.
  ///
  /// In es, this message translates to:
  /// **'Este mes'**
  String get histMes;

  /// No description provided for @histMesAnterior.
  ///
  /// In es, this message translates to:
  /// **'Mes anterior'**
  String get histMesAnterior;

  /// No description provided for @histElegirFechas.
  ///
  /// In es, this message translates to:
  /// **'Elegir fechas'**
  String get histElegirFechas;

  /// No description provided for @histVacioRango.
  ///
  /// In es, this message translates to:
  /// **'No hay órdenes creadas en esas fechas.'**
  String get histVacioRango;

  /// No description provided for @buscarOrdenes.
  ///
  /// In es, this message translates to:
  /// **'Buscar: cliente, folio, teléfono, dirección…'**
  String get buscarOrdenes;

  /// No description provided for @buscarSinResultados.
  ///
  /// In es, this message translates to:
  /// **'No hay órdenes que coincidan con «{texto}».'**
  String buscarSinResultados(String texto);

  /// No description provided for @avisoCanalFijo.
  ///
  /// In es, this message translates to:
  /// **'Aviso fijo'**
  String get avisoCanalFijo;

  /// No description provided for @avisoCanalOrdenes.
  ///
  /// In es, this message translates to:
  /// **'Órdenes nuevas'**
  String get avisoCanalOrdenes;

  /// No description provided for @avisoFijoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Atento a órdenes nuevas'**
  String get avisoFijoTitulo;

  /// No description provided for @avisoFijoTexto.
  ///
  /// In es, this message translates to:
  /// **'Te aviso en cuanto llegue una orden.'**
  String get avisoFijoTexto;

  /// No description provided for @avisoFijoPendientes.
  ///
  /// In es, this message translates to:
  /// **'{n, plural, =0{Sin órdenes pendientes} =1{1 orden pendiente} other{{n} órdenes pendientes}}'**
  String avisoFijoPendientes(int n);

  /// No description provided for @avisoNueva.
  ///
  /// In es, this message translates to:
  /// **'Nueva orden {folio}'**
  String avisoNueva(String folio);

  /// No description provided for @avisoAsignada.
  ///
  /// In es, this message translates to:
  /// **'Te asignaron la orden {folio}'**
  String avisoAsignada(String folio);

  /// No description provided for @nuevaOrden.
  ///
  /// In es, this message translates to:
  /// **'Nueva orden'**
  String get nuevaOrden;

  /// No description provided for @editarOrden.
  ///
  /// In es, this message translates to:
  /// **'Editar orden'**
  String get editarOrden;

  /// No description provided for @foSubtituloNueva.
  ///
  /// In es, this message translates to:
  /// **'Llena los datos: la oficina y los técnicos la ven al momento.'**
  String get foSubtituloNueva;

  /// No description provided for @foSeccionCliente.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get foSeccionCliente;

  /// No description provided for @foCliente.
  ///
  /// In es, this message translates to:
  /// **'Nombre del cliente'**
  String get foCliente;

  /// No description provided for @foDireccion.
  ///
  /// In es, this message translates to:
  /// **'Dirección (calle, número, colonia, referencias)'**
  String get foDireccion;

  /// No description provided for @foSeccionUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get foSeccionUbicacion;

  /// No description provided for @foCoordenadas.
  ///
  /// In es, this message translates to:
  /// **'Coordenadas o enlace de Google Maps'**
  String get foCoordenadas;

  /// No description provided for @foMiUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Usar mi ubicación'**
  String get foMiUbicacion;

  /// No description provided for @foElegirServicio.
  ///
  /// In es, this message translates to:
  /// **'Elige el servicio'**
  String get foElegirServicio;

  /// No description provided for @foCuando.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo?'**
  String get foCuando;

  /// No description provided for @foManana.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get foManana;

  /// No description provided for @foOtroDia.
  ///
  /// In es, this message translates to:
  /// **'Otro día'**
  String get foOtroDia;

  /// No description provided for @foSinHora.
  ///
  /// In es, this message translates to:
  /// **'Sin hora'**
  String get foSinHora;

  /// No description provided for @foElegirHora.
  ///
  /// In es, this message translates to:
  /// **'Elegir hora'**
  String get foElegirHora;

  /// No description provided for @foCrear.
  ///
  /// In es, this message translates to:
  /// **'Crear orden'**
  String get foCrear;

  /// No description provided for @foGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get foGuardar;

  /// No description provided for @errFoCliente.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre del cliente.'**
  String get errFoCliente;

  /// No description provided for @errFoTelefono.
  ///
  /// In es, this message translates to:
  /// **'Ese teléfono no es válido para {pais}. Revisa el número o cambia el país.'**
  String errFoTelefono(String pais);

  /// No description provided for @errFoCoordenadas.
  ///
  /// In es, this message translates to:
  /// **'No entiendo esas coordenadas: escribe «latitud, longitud» o pega un enlace de Google Maps.'**
  String get errFoCoordenadas;

  /// No description provided for @errFoLocalidad.
  ///
  /// In es, this message translates to:
  /// **'Elige la localidad.'**
  String get errFoLocalidad;

  /// No description provided for @errFoServicio.
  ///
  /// In es, this message translates to:
  /// **'Elige el servicio.'**
  String get errFoServicio;

  /// No description provided for @errFoDiaPasado.
  ///
  /// In es, this message translates to:
  /// **'El día no puede ser anterior a hoy.'**
  String get errFoDiaPasado;

  /// No description provided for @errFoHoraPasada.
  ///
  /// In es, this message translates to:
  /// **'Esa hora ya pasó.'**
  String get errFoHoraPasada;

  /// No description provided for @errFoCompletadaFutura.
  ///
  /// In es, this message translates to:
  /// **'Una orden completada no puede pasar a un día futuro.'**
  String get errFoCompletadaFutura;

  /// No description provided for @errUbicacionApagada.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación del teléfono.'**
  String get errUbicacionApagada;

  /// No description provided for @errUbicacionPermiso.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso de ubicación: actívalo en los ajustes del teléfono.'**
  String get errUbicacionPermiso;

  /// No description provided for @errUbicacionOtro.
  ///
  /// In es, this message translates to:
  /// **'No se pudo obtener la ubicación. Intenta de nuevo.'**
  String get errUbicacionOtro;

  /// No description provided for @ordenCreada.
  ///
  /// In es, this message translates to:
  /// **'Listo: se creó la orden {folio}.'**
  String ordenCreada(String folio);

  /// No description provided for @ordenGuardada.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados.'**
  String get ordenGuardada;

  /// No description provided for @menuEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get menuEditar;

  /// No description provided for @menuEliminar.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get menuEliminar;

  /// No description provided for @eliminarPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar la orden {folio}?'**
  String eliminarPregunta(String folio);

  /// No description provided for @eliminarTexto.
  ///
  /// In es, this message translates to:
  /// **'Se va a la Papelera de la web: ahí se puede restaurar durante 30 días.'**
  String get eliminarTexto;

  /// No description provided for @ordenEliminada.
  ///
  /// In es, this message translates to:
  /// **'La orden se movió a la Papelera.'**
  String get ordenEliminada;

  /// No description provided for @msgSoloConsulta.
  ///
  /// In es, this message translates to:
  /// **'Tu rol es de consulta: puedes ver la orden, pero no cambiarla.'**
  String get msgSoloConsulta;

  /// No description provided for @menuModems.
  ///
  /// In es, this message translates to:
  /// **'Módems por recuperar'**
  String get menuModems;

  /// No description provided for @menuComisiones.
  ///
  /// In es, this message translates to:
  /// **'Pago de comisiones'**
  String get menuComisiones;

  /// No description provided for @modemDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Clientes que cancelaron: un comisionista va por el módem y se marca cuando lo traiga.'**
  String get modemDescripcion;

  /// No description provided for @modemSinAsignar.
  ///
  /// In es, this message translates to:
  /// **'Sin asignar'**
  String get modemSinAsignar;

  /// No description provided for @modemAsignados.
  ///
  /// In es, this message translates to:
  /// **'Asignados'**
  String get modemAsignados;

  /// No description provided for @modemInternet.
  ///
  /// In es, this message translates to:
  /// **'Módem Internet'**
  String get modemInternet;

  /// No description provided for @modemDoblePlay.
  ///
  /// In es, this message translates to:
  /// **'Módem Doble Play'**
  String get modemDoblePlay;

  /// No description provided for @modemLoRecuperasTu.
  ///
  /// In es, this message translates to:
  /// **'Lo recuperas tú'**
  String get modemLoRecuperasTu;

  /// No description provided for @modemLoRecupera.
  ///
  /// In es, this message translates to:
  /// **'Lo recupera {nombre}'**
  String modemLoRecupera(String nombre);

  /// No description provided for @modemComision.
  ///
  /// In es, this message translates to:
  /// **'Comisión {importe}'**
  String modemComision(String importe);

  /// No description provided for @modemSoltar.
  ///
  /// In es, this message translates to:
  /// **'Soltar'**
  String get modemSoltar;

  /// No description provided for @modemAsignar.
  ///
  /// In es, this message translates to:
  /// **'Asignar'**
  String get modemAsignar;

  /// No description provided for @modemYaLoRecupere.
  ///
  /// In es, this message translates to:
  /// **'Ya lo recuperé'**
  String get modemYaLoRecupere;

  /// No description provided for @modemQuienRecupera.
  ///
  /// In es, this message translates to:
  /// **'¿Qué comisionista recupera el módem?'**
  String get modemQuienRecupera;

  /// No description provided for @modemSoltado.
  ///
  /// In es, this message translates to:
  /// **'El módem quedó sin asignar.'**
  String get modemSoltado;

  /// No description provided for @modemAsignadoA.
  ///
  /// In es, this message translates to:
  /// **'Módem asignado a {nombre}.'**
  String modemAsignadoA(String nombre);

  /// No description provided for @modemRecuperadoPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes el módem?'**
  String get modemRecuperadoPregunta;

  /// No description provided for @modemRecuperadoTexto.
  ///
  /// In es, this message translates to:
  /// **'Confirma que ya se recuperó el módem de {cliente}. La oficina lo ve al momento.'**
  String modemRecuperadoTexto(String cliente);

  /// No description provided for @modemGanas.
  ///
  /// In es, this message translates to:
  /// **'Comisión: {importe}.'**
  String modemGanas(String importe);

  /// No description provided for @modemRecuperadoOk.
  ///
  /// In es, this message translates to:
  /// **'¡Listo! Módem recuperado: la comisión ya cuenta.'**
  String get modemRecuperadoOk;

  /// No description provided for @modemVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay módems por recuperar. ¡Todo al día!'**
  String get modemVacio;

  /// No description provided for @modemVacioFiltro.
  ///
  /// In es, this message translates to:
  /// **'No hay módems con este filtro.'**
  String get modemVacioFiltro;

  /// No description provided for @comTotalPeriodo.
  ///
  /// In es, this message translates to:
  /// **'Total del periodo'**
  String get comTotalPeriodo;

  /// No description provided for @comPorEntregar.
  ///
  /// In es, this message translates to:
  /// **'Por entregar'**
  String get comPorEntregar;

  /// No description provided for @comEntregadas.
  ///
  /// In es, this message translates to:
  /// **'Entregadas'**
  String get comEntregadas;

  /// No description provided for @comEntregada.
  ///
  /// In es, this message translates to:
  /// **'Entregada'**
  String get comEntregada;

  /// No description provided for @comSinImporte.
  ///
  /// In es, this message translates to:
  /// **'Sin importe'**
  String get comSinImporte;

  /// No description provided for @comVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay comisiones en este periodo.'**
  String get comVacio;

  /// No description provided for @foOpcional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get foOpcional;

  /// No description provided for @foBuscarPais.
  ///
  /// In es, this message translates to:
  /// **'Buscar país o lada'**
  String get foBuscarPais;

  /// No description provided for @foLlegaSinTecnico.
  ///
  /// In es, this message translates to:
  /// **'La orden llega sin técnico: el primero que la acepte se la queda.'**
  String get foLlegaSinTecnico;

  /// No description provided for @foDatosNuevo.
  ///
  /// In es, this message translates to:
  /// **'Datos del servicio nuevo'**
  String get foDatosNuevo;

  /// No description provided for @foPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan (módem que se instala)'**
  String get foPlan;

  /// No description provided for @foTelevisiones.
  ///
  /// In es, this message translates to:
  /// **'Televisiones'**
  String get foTelevisiones;

  /// No description provided for @foTvConCosto.
  ///
  /// In es, this message translates to:
  /// **'TV con costo'**
  String get foTvConCosto;

  /// No description provided for @foTvSinCosto.
  ///
  /// In es, this message translates to:
  /// **'TV sin costo'**
  String get foTvSinCosto;

  /// No description provided for @foTvPrecio.
  ///
  /// In es, this message translates to:
  /// **'Cada TV con costo se cobra {precio} al completar. Total: {total}.'**
  String foTvPrecio(String precio, String total);

  /// No description provided for @foQuienLoConsiguio.
  ///
  /// In es, this message translates to:
  /// **'¿Quién consiguió este servicio?'**
  String get foQuienLoConsiguio;

  /// No description provided for @foNingunoSinComision.
  ///
  /// In es, this message translates to:
  /// **'Ninguno (sin comisión)'**
  String get foNingunoSinComision;

  /// No description provided for @foDatosBaja.
  ///
  /// In es, this message translates to:
  /// **'Cancelación definitiva'**
  String get foDatosBaja;

  /// No description provided for @foMotivo.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get foMotivo;

  /// No description provided for @foOtros.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get foOtros;

  /// No description provided for @foEscribeMotivo.
  ///
  /// In es, this message translates to:
  /// **'Escribe el motivo'**
  String get foEscribeMotivo;

  /// No description provided for @foModemRecuperar.
  ///
  /// In es, this message translates to:
  /// **'Módem a recuperar'**
  String get foModemRecuperar;

  /// No description provided for @foDatosTemporal.
  ///
  /// In es, this message translates to:
  /// **'Cancelación temporal'**
  String get foDatosTemporal;

  /// No description provided for @foMotivoOpcional.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get foMotivoOpcional;

  /// No description provided for @foRecogeModem.
  ///
  /// In es, this message translates to:
  /// **'¿Se recoge el módem?'**
  String get foRecogeModem;

  /// No description provided for @foSi.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get foSi;

  /// No description provided for @foNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get foNo;

  /// No description provided for @foModemSeRecoge.
  ///
  /// In es, this message translates to:
  /// **'Módem que se recoge'**
  String get foModemSeRecoge;

  /// No description provided for @foFechaRegreso.
  ///
  /// In es, this message translates to:
  /// **'Fecha supuesta de regreso'**
  String get foFechaRegreso;

  /// No description provided for @foElegirFecha.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get foElegirFecha;

  /// No description provided for @foFechaRegresoAyuda.
  ///
  /// In es, this message translates to:
  /// **'La web avisa 3 días antes.'**
  String get foFechaRegresoAyuda;

  /// No description provided for @foSinCategoriasModem.
  ///
  /// In es, this message translates to:
  /// **'No hay categorías de módem: agrégalas en la web (Sistema › Activos).'**
  String get foSinCategoriasModem;

  /// No description provided for @errFoPlan.
  ///
  /// In es, this message translates to:
  /// **'Elige el plan (el módem que se instala).'**
  String get errFoPlan;

  /// No description provided for @errFoComision.
  ///
  /// In es, this message translates to:
  /// **'Elige la comisión de quien consiguió el servicio.'**
  String get errFoComision;

  /// No description provided for @errFoMotivo.
  ///
  /// In es, this message translates to:
  /// **'Elige el motivo de la cancelación.'**
  String get errFoMotivo;

  /// No description provided for @errFoMotivoOtro.
  ///
  /// In es, this message translates to:
  /// **'Escribe el motivo de la cancelación.'**
  String get errFoMotivoOtro;

  /// No description provided for @errFoModem.
  ///
  /// In es, this message translates to:
  /// **'Elige la categoría del módem.'**
  String get errFoModem;

  /// No description provided for @errFoRecoge.
  ///
  /// In es, this message translates to:
  /// **'Elige si se recoge el módem.'**
  String get errFoRecoge;

  /// No description provided for @errFoRegreso.
  ///
  /// In es, this message translates to:
  /// **'Elige la fecha supuesta de regreso.'**
  String get errFoRegreso;

  /// No description provided for @errFoRegresoPasada.
  ///
  /// In es, this message translates to:
  /// **'La fecha de regreso no puede ser anterior a hoy.'**
  String get errFoRegresoPasada;

  /// No description provided for @menuAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get menuAdmin;

  /// No description provided for @menuDashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get menuDashboard;

  /// No description provided for @menuOrdenesTrabajo.
  ///
  /// In es, this message translates to:
  /// **'Órdenes de trabajo'**
  String get menuOrdenesTrabajo;

  /// No description provided for @menuDelDia.
  ///
  /// In es, this message translates to:
  /// **'Del día'**
  String get menuDelDia;

  /// No description provided for @menuHistorico.
  ///
  /// In es, this message translates to:
  /// **'Histórico'**
  String get menuHistorico;

  /// No description provided for @menuPorAutorizar.
  ///
  /// In es, this message translates to:
  /// **'Por autorizar'**
  String get menuPorAutorizar;

  /// No description provided for @menuRecuperarModem.
  ///
  /// In es, this message translates to:
  /// **'Recuperar módem'**
  String get menuRecuperarModem;

  /// No description provided for @menuReportes.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get menuReportes;

  /// No description provided for @menuHerramientas.
  ///
  /// In es, this message translates to:
  /// **'Herramientas'**
  String get menuHerramientas;

  /// No description provided for @dashRecibidas.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get dashRecibidas;

  /// No description provided for @dashRecibidasSub.
  ///
  /// In es, this message translates to:
  /// **'recibidas'**
  String get dashRecibidasSub;

  /// No description provided for @dashCompletadas.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get dashCompletadas;

  /// No description provided for @dashCumplimiento.
  ///
  /// In es, this message translates to:
  /// **'{p} % de cumplimiento'**
  String dashCumplimiento(int p);

  /// No description provided for @dashAbiertas.
  ///
  /// In es, this message translates to:
  /// **'Abiertas'**
  String get dashAbiertas;

  /// No description provided for @dashAbiertasSub.
  ///
  /// In es, this message translates to:
  /// **'{p} pendientes · {e} en proceso'**
  String dashAbiertasSub(int p, int e);

  /// No description provided for @dashTiempo.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de atención'**
  String get dashTiempo;

  /// No description provided for @dashTiempoSub.
  ///
  /// In es, this message translates to:
  /// **'promedio de {n} servicios'**
  String dashTiempoSub(int n);

  /// No description provided for @dashNuevos.
  ///
  /// In es, this message translates to:
  /// **'Nuevos servicios'**
  String get dashNuevos;

  /// No description provided for @dashNuevosSub.
  ///
  /// In es, this message translates to:
  /// **'instalaciones'**
  String get dashNuevosSub;

  /// No description provided for @dashIngresos.
  ///
  /// In es, this message translates to:
  /// **'Ingresos cobrados'**
  String get dashIngresos;

  /// No description provided for @dashIngresosSub.
  ///
  /// In es, this message translates to:
  /// **'{n} cobros'**
  String dashIngresosSub(int n);

  /// No description provided for @dashPorCobrar.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de cobro'**
  String get dashPorCobrar;

  /// No description provided for @dashPorCobrarSub.
  ///
  /// In es, this message translates to:
  /// **'por cobrar'**
  String get dashPorCobrarSub;

  /// No description provided for @dashPospuestas.
  ///
  /// In es, this message translates to:
  /// **'Pospuestas'**
  String get dashPospuestas;

  /// No description provided for @dashCanceladas.
  ///
  /// In es, this message translates to:
  /// **'Canceladas'**
  String get dashCanceladas;

  /// No description provided for @dashDeLasSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'{p} % de las solicitudes'**
  String dashDeLasSolicitudes(int p);

  /// No description provided for @dashVsAnterior.
  ///
  /// In es, this message translates to:
  /// **'Las flechas comparan con los {dias} días anteriores.'**
  String dashVsAnterior(int dias);

  /// No description provided for @dashSinDato.
  ///
  /// In es, this message translates to:
  /// **'—'**
  String get dashSinDato;

  /// No description provided for @dashMinutos.
  ///
  /// In es, this message translates to:
  /// **'{m} min'**
  String dashMinutos(int m);

  /// No description provided for @dashHoras.
  ///
  /// In es, this message translates to:
  /// **'{h} h'**
  String dashHoras(String h);

  /// No description provided for @dashDias.
  ///
  /// In es, this message translates to:
  /// **'{d} días'**
  String dashDias(String d);

  /// No description provided for @dashTendencia.
  ///
  /// In es, this message translates to:
  /// **'Recibidas y completadas'**
  String get dashTendencia;

  /// No description provided for @dashEstados.
  ///
  /// In es, this message translates to:
  /// **'Cómo van las solicitudes'**
  String get dashEstados;

  /// No description provided for @dashPorLocalidad.
  ///
  /// In es, this message translates to:
  /// **'Por localidad'**
  String get dashPorLocalidad;

  /// No description provided for @dashPorTecnico.
  ///
  /// In es, this message translates to:
  /// **'Por técnico'**
  String get dashPorTecnico;

  /// No description provided for @dashLocalidadDetalle.
  ///
  /// In es, this message translates to:
  /// **'{n} recibidas · {d} completadas'**
  String dashLocalidadDetalle(int n, int d);

  /// No description provided for @dashTecnicoDetalle.
  ///
  /// In es, this message translates to:
  /// **'{n} completadas · {tiempo} en promedio'**
  String dashTecnicoDetalle(int n, String tiempo);

  /// No description provided for @dashSinLocalidad.
  ///
  /// In es, this message translates to:
  /// **'Sin localidad'**
  String get dashSinLocalidad;

  /// No description provided for @dashSinDatos.
  ///
  /// In es, this message translates to:
  /// **'No hay órdenes registradas en estas fechas.'**
  String get dashSinDatos;

  /// No description provided for @dashNota.
  ///
  /// In es, this message translates to:
  /// **'Cuenta las órdenes registradas en el periodo (como el Dashboard de la web). Por técnico: las que completó en el periodo.'**
  String get dashNota;

  /// No description provided for @dashToca.
  ///
  /// In es, this message translates to:
  /// **'Toca una barra para ver sus números.'**
  String get dashToca;

  /// No description provided for @dashTramo.
  ///
  /// In es, this message translates to:
  /// **'{fecha}: {r} recibidas · {c} completadas'**
  String dashTramo(String fecha, int r, int c);

  /// No description provided for @autVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay cobros esperando autorización.'**
  String get autVacio;

  /// No description provided for @autNota.
  ///
  /// In es, this message translates to:
  /// **'Se autorizan desde la web, en Finanzas › Pendientes de pago.'**
  String get autNota;

  /// No description provided for @dashNuevo.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get dashNuevo;

  /// No description provided for @dashPuntos.
  ///
  /// In es, this message translates to:
  /// **'{n} pts'**
  String dashPuntos(String n);

  /// No description provided for @avisoRegreso.
  ///
  /// In es, this message translates to:
  /// **'La orden {folio} regresó a Pendientes'**
  String avisoRegreso(String folio);

  /// No description provided for @comNota.
  ///
  /// In es, this message translates to:
  /// **'Las comisiones las cobran los comisionistas (Sistema › Comisionistas de la web). Se entregan desde la web.'**
  String get comNota;

  /// No description provided for @comTipoInstalacion.
  ///
  /// In es, this message translates to:
  /// **'Instalación'**
  String get comTipoInstalacion;

  /// No description provided for @comTipoModem.
  ///
  /// In es, this message translates to:
  /// **'Módem recuperado'**
  String get comTipoModem;

  /// No description provided for @comTipoIsp.
  ///
  /// In es, this message translates to:
  /// **'Módem de Importados ISP'**
  String get comTipoIsp;

  /// No description provided for @comSinNombre.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get comSinNombre;

  /// No description provided for @comDeQuien.
  ///
  /// In es, this message translates to:
  /// **'{nombre} · {importe}'**
  String comDeQuien(String nombre, String importe);

  /// No description provided for @menuFinanzas.
  ///
  /// In es, this message translates to:
  /// **'Finanzas'**
  String get menuFinanzas;

  /// No description provided for @menuResumenFinanzas.
  ///
  /// In es, this message translates to:
  /// **'Resumen'**
  String get menuResumenFinanzas;

  /// No description provided for @finResultado.
  ///
  /// In es, this message translates to:
  /// **'Resultado del periodo'**
  String get finResultado;

  /// No description provided for @finEntradas.
  ///
  /// In es, this message translates to:
  /// **'Entradas'**
  String get finEntradas;

  /// No description provided for @finSalidas.
  ///
  /// In es, this message translates to:
  /// **'Salidas'**
  String get finSalidas;

  /// No description provided for @finIngresosServicios.
  ///
  /// In es, this message translates to:
  /// **'Ingresos de servicios'**
  String get finIngresosServicios;

  /// No description provided for @finCobrosOrdenes.
  ///
  /// In es, this message translates to:
  /// **'Cobros de órdenes'**
  String get finCobrosOrdenes;

  /// No description provided for @finCobrosDetalle.
  ///
  /// In es, this message translates to:
  /// **'{n} órdenes cobradas en efectivo o transferencia'**
  String finCobrosDetalle(int n);

  /// No description provided for @finGastos.
  ///
  /// In es, this message translates to:
  /// **'Gastos'**
  String get finGastos;

  /// No description provided for @finComisiones.
  ///
  /// In es, this message translates to:
  /// **'Comisiones'**
  String get finComisiones;

  /// No description provided for @finComisionesNoCuentan.
  ///
  /// In es, this message translates to:
  /// **'No cuentan como gasto: en la web no está la partida de comisiones.'**
  String get finComisionesNoCuentan;

  /// No description provided for @finSinFormaPago.
  ///
  /// In es, this message translates to:
  /// **'Sin forma de pago'**
  String get finSinFormaPago;

  /// No description provided for @finOtrosGastos.
  ///
  /// In es, this message translates to:
  /// **'Otros gastos'**
  String get finOtrosGastos;

  /// No description provided for @finNada.
  ///
  /// In es, this message translates to:
  /// **'Nada en este periodo.'**
  String get finNada;

  /// No description provided for @finNota.
  ///
  /// In es, this message translates to:
  /// **'Es un resumen del Estado financiero de la web. Salarios y materiales (AFT, insumos) se ven en la web.'**
  String get finNota;

  /// No description provided for @comTodos.
  ///
  /// In es, this message translates to:
  /// **'Todos los comisionistas'**
  String get comTodos;

  /// No description provided for @matTitulo.
  ///
  /// In es, this message translates to:
  /// **'Materiales'**
  String get matTitulo;

  /// No description provided for @matExplica.
  ///
  /// In es, this message translates to:
  /// **'Marca el módem que se instaló y los insumos que se usaron. Salen del inventario de la oficina.'**
  String get matExplica;

  /// No description provided for @matModem.
  ///
  /// In es, this message translates to:
  /// **'Módem instalado'**
  String get matModem;

  /// No description provided for @matModemNinguno.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get matModemNinguno;

  /// No description provided for @matModemNingunoSub.
  ///
  /// In es, this message translates to:
  /// **'No se instaló módem (sin gasto)'**
  String get matModemNingunoSub;

  /// No description provided for @matInsumos.
  ///
  /// In es, this message translates to:
  /// **'Lleva insumos'**
  String get matInsumos;

  /// No description provided for @matInsumoElige.
  ///
  /// In es, this message translates to:
  /// **'Elige el insumo'**
  String get matInsumoElige;

  /// No description provided for @matCantidad.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get matCantidad;

  /// No description provided for @matAgregar.
  ///
  /// In es, this message translates to:
  /// **'Agregar insumo'**
  String get matAgregar;

  /// No description provided for @matQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get matQuitar;

  /// No description provided for @matSinPred.
  ///
  /// In es, this message translates to:
  /// **'Este servicio no trae insumos: agrégalos si se usaron.'**
  String get matSinPred;

  /// No description provided for @matGastoModem.
  ///
  /// In es, this message translates to:
  /// **'Gasto del módem'**
  String get matGastoModem;

  /// No description provided for @matGastoInsumos.
  ///
  /// In es, this message translates to:
  /// **'Gasto de insumos'**
  String get matGastoInsumos;

  /// No description provided for @matTotal.
  ///
  /// In es, this message translates to:
  /// **'Total de materiales'**
  String get matTotal;

  /// No description provided for @matContinuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get matContinuar;

  /// No description provided for @matSinLista.
  ///
  /// In es, this message translates to:
  /// **'Sin señal no se pudo leer la lista de materiales: la orden se termina igual y la oficina los anota en la web.'**
  String get matSinLista;

  /// No description provided for @menuInconclusas.
  ///
  /// In es, this message translates to:
  /// **'Inconclusas'**
  String get menuInconclusas;

  /// No description provided for @incMarcar.
  ///
  /// In es, this message translates to:
  /// **'Marcar inconclusa'**
  String get incMarcar;

  /// No description provided for @incTitulo.
  ///
  /// In es, this message translates to:
  /// **'Orden inconclusa'**
  String get incTitulo;

  /// No description provided for @incExplica.
  ///
  /// In es, this message translates to:
  /// **'Se completó pero quedó algo pendiente. Elige cuándo se regresa y qué falta.'**
  String get incExplica;

  /// No description provided for @incFecha.
  ///
  /// In es, this message translates to:
  /// **'Fecha de regreso'**
  String get incFecha;

  /// No description provided for @incMotivo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué quedó pendiente?'**
  String get incMotivo;

  /// No description provided for @incChipModem.
  ///
  /// In es, this message translates to:
  /// **'Falta poner el módem correcto'**
  String get incChipModem;

  /// No description provided for @incChipMaterial.
  ///
  /// In es, this message translates to:
  /// **'Falta material'**
  String get incChipMaterial;

  /// No description provided for @incChipTerminar.
  ///
  /// In es, this message translates to:
  /// **'Falta terminar la instalación'**
  String get incChipTerminar;

  /// No description provided for @incChipSenal.
  ///
  /// In es, this message translates to:
  /// **'Regresar a revisar la señal'**
  String get incChipSenal;

  /// No description provided for @incGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get incGuardar;

  /// No description provided for @incFaltaFecha.
  ///
  /// In es, this message translates to:
  /// **'Elige la fecha de regreso.'**
  String get incFaltaFecha;

  /// No description provided for @incFaltaMotivo.
  ///
  /// In es, this message translates to:
  /// **'Escribe qué quedó pendiente.'**
  String get incFaltaMotivo;

  /// No description provided for @incGuardada.
  ///
  /// In es, this message translates to:
  /// **'Orden marcada como inconclusa.'**
  String get incGuardada;

  /// No description provided for @incResolver.
  ///
  /// In es, this message translates to:
  /// **'Resolver'**
  String get incResolver;

  /// No description provided for @incResolverPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Ya se resolvió?'**
  String get incResolverPregunta;

  /// No description provided for @incResolverTexto.
  ///
  /// In es, this message translates to:
  /// **'La orden {folio} deja de estar inconclusa.'**
  String incResolverTexto(String folio);

  /// No description provided for @incResuelta.
  ///
  /// In es, this message translates to:
  /// **'Inconclusa resuelta.'**
  String get incResuelta;

  /// No description provided for @incVuelve.
  ///
  /// In es, this message translates to:
  /// **'Vuelve el {fecha}'**
  String incVuelve(String fecha);

  /// No description provided for @incSinFecha.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha de regreso'**
  String get incSinFecha;

  /// No description provided for @incAtrasadas.
  ///
  /// In es, this message translates to:
  /// **'Atrasadas'**
  String get incAtrasadas;

  /// No description provided for @incProximas.
  ///
  /// In es, this message translates to:
  /// **'Próximas'**
  String get incProximas;

  /// No description provided for @incVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay órdenes inconclusas. ¡Todo terminado!'**
  String get incVacio;

  /// No description provided for @incCambiar.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get incCambiar;

  /// No description provided for @menuProspectos.
  ///
  /// In es, this message translates to:
  /// **'Prospectos'**
  String get menuProspectos;

  /// No description provided for @prosNuevo.
  ///
  /// In es, this message translates to:
  /// **'Nuevo prospecto'**
  String get prosNuevo;

  /// No description provided for @prosEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar prospecto'**
  String get prosEditar;

  /// No description provided for @prosExplica.
  ///
  /// In es, this message translates to:
  /// **'Posible cliente de un servicio nuevo. Ningún dato es obligatorio.'**
  String get prosExplica;

  /// No description provided for @prosNombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get prosNombre;

  /// No description provided for @prosSinLocalidad.
  ///
  /// In es, this message translates to:
  /// **'Sin localidad'**
  String get prosSinLocalidad;

  /// No description provided for @prosQuien.
  ///
  /// In es, this message translates to:
  /// **'¿Quién lo prospectó?'**
  String get prosQuien;

  /// No description provided for @prosNadie.
  ///
  /// In es, this message translates to:
  /// **'Nadie'**
  String get prosNadie;

  /// No description provided for @prosDia.
  ///
  /// In es, this message translates to:
  /// **'Fecha de instalación'**
  String get prosDia;

  /// No description provided for @prosSinDia.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get prosSinDia;

  /// No description provided for @prosComentario.
  ///
  /// In es, this message translates to:
  /// **'Comentario'**
  String get prosComentario;

  /// No description provided for @prosFoto.
  ///
  /// In es, this message translates to:
  /// **'Foto'**
  String get prosFoto;

  /// No description provided for @prosTomarFoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get prosTomarFoto;

  /// No description provided for @prosGaleria.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get prosGaleria;

  /// No description provided for @prosQuitarFoto.
  ///
  /// In es, this message translates to:
  /// **'Quitar foto'**
  String get prosQuitarFoto;

  /// No description provided for @prosFotoError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo usar esa foto.'**
  String get prosFotoError;

  /// No description provided for @prosGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get prosGuardar;

  /// No description provided for @prosGuardado.
  ///
  /// In es, this message translates to:
  /// **'Prospecto guardado.'**
  String get prosGuardado;

  /// No description provided for @prosCrearOrden.
  ///
  /// In es, this message translates to:
  /// **'Crear orden'**
  String get prosCrearOrden;

  /// No description provided for @prosAsignado.
  ///
  /// In es, this message translates to:
  /// **'Listo: el prospecto quedó asignado a la orden {folio}.'**
  String prosAsignado(String folio);

  /// No description provided for @prosDescripcionOrden.
  ///
  /// In es, this message translates to:
  /// **'Prospecto: {texto}'**
  String prosDescripcionOrden(String texto);

  /// No description provided for @prosVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay prospectos en estas fechas.'**
  String get prosVacio;

  /// No description provided for @prosPendientes.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get prosPendientes;

  /// No description provided for @prosAsignados.
  ///
  /// In es, this message translates to:
  /// **'Asignados'**
  String get prosAsignados;

  /// No description provided for @prosLuzHoy.
  ///
  /// In es, this message translates to:
  /// **'Instalar hoy (o ya pasó)'**
  String get prosLuzHoy;

  /// No description provided for @prosLuzManana.
  ///
  /// In es, this message translates to:
  /// **'Instalar mañana'**
  String get prosLuzManana;

  /// No description provided for @prosOrden.
  ///
  /// In es, this message translates to:
  /// **'Orden {folio}'**
  String prosOrden(String folio);

  /// No description provided for @errProsDiaPasado.
  ///
  /// In es, this message translates to:
  /// **'La fecha de instalación no puede ser anterior a hoy.'**
  String get errProsDiaPasado;

  /// No description provided for @menuMapaDia.
  ///
  /// In es, this message translates to:
  /// **'Mapa del día'**
  String get menuMapaDia;

  /// No description provided for @mapaCalles.
  ///
  /// In es, this message translates to:
  /// **'Calles'**
  String get mapaCalles;

  /// No description provided for @mapaSatelite.
  ///
  /// In es, this message translates to:
  /// **'Satélite'**
  String get mapaSatelite;

  /// No description provided for @mapaSinUbicacion.
  ///
  /// In es, this message translates to:
  /// **'{n} sin ubicación'**
  String mapaSinUbicacion(int n);

  /// No description provided for @mapaVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay órdenes para hoy con ubicación.'**
  String get mapaVacio;

  /// No description provided for @mapaCreditos.
  ///
  /// In es, this message translates to:
  /// **'© OpenStreetMap · Esri'**
  String get mapaCreditos;

  /// No description provided for @mapaCentrar.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get mapaCentrar;

  /// No description provided for @fotTitulo.
  ///
  /// In es, this message translates to:
  /// **'Fotos del trabajo'**
  String get fotTitulo;

  /// No description provided for @fotNinguna.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay fotos. Toma fotos del trabajo: la oficina las ve en la web.'**
  String get fotNinguna;

  /// No description provided for @fotMax.
  ///
  /// In es, this message translates to:
  /// **'Máximo {n} fotos por orden.'**
  String fotMax(int n);

  /// No description provided for @fotGuardadas.
  ///
  /// In es, this message translates to:
  /// **'Fotos guardadas.'**
  String get fotGuardadas;

  /// No description provided for @fotQuitarPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar esta foto?'**
  String get fotQuitarPregunta;

  /// No description provided for @fotQuitarTexto.
  ///
  /// In es, this message translates to:
  /// **'Se borra de la orden también en la web.'**
  String get fotQuitarTexto;

  /// No description provided for @fotQuitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get fotQuitar;

  /// No description provided for @compTitulo.
  ///
  /// In es, this message translates to:
  /// **'Comprobante de la transferencia'**
  String get compTitulo;

  /// No description provided for @compExplica.
  ///
  /// In es, this message translates to:
  /// **'Opcional, pero ayuda: con la foto la oficina completa la orden sin pedírtelo otra vez.'**
  String get compExplica;

  /// No description provided for @menuNuevosServicios.
  ///
  /// In es, this message translates to:
  /// **'Nuevos Servicios'**
  String get menuNuevosServicios;

  /// No description provided for @menuCancelados.
  ///
  /// In es, this message translates to:
  /// **'Cancelados'**
  String get menuCancelados;

  /// No description provided for @menuFuturo.
  ///
  /// In es, this message translates to:
  /// **'Futuro'**
  String get menuFuturo;

  /// No description provided for @menuNsPendientes.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get menuNsPendientes;

  /// No description provided for @menuFacturaIsp.
  ///
  /// In es, this message translates to:
  /// **'Eliminar factura del ISP'**
  String get menuFacturaIsp;

  /// No description provided for @menuNsHistorico.
  ///
  /// In es, this message translates to:
  /// **'Histórico'**
  String get menuNsHistorico;

  /// No description provided for @menuNcNuevos.
  ///
  /// In es, this message translates to:
  /// **'Nuevos Servicios'**
  String get menuNcNuevos;

  /// No description provided for @menuTvCable.
  ///
  /// In es, this message translates to:
  /// **'TV Cable'**
  String get menuTvCable;

  /// No description provided for @menuTvDoblePlay.
  ///
  /// In es, this message translates to:
  /// **'TV Doble Play'**
  String get menuTvDoblePlay;

  /// No description provided for @menuDefinitivos.
  ///
  /// In es, this message translates to:
  /// **'Definitivos'**
  String get menuDefinitivos;

  /// No description provided for @menuTemporales.
  ///
  /// In es, this message translates to:
  /// **'Temporales'**
  String get menuTemporales;

  /// No description provided for @nsAtrasado1.
  ///
  /// In es, this message translates to:
  /// **'Atrasado 1 día'**
  String get nsAtrasado1;

  /// No description provided for @nsAtrasadoN.
  ///
  /// In es, this message translates to:
  /// **'Atrasado {n} días'**
  String nsAtrasadoN(int n);

  /// No description provided for @nsTocaHoy.
  ///
  /// In es, this message translates to:
  /// **'Toca hoy'**
  String get nsTocaHoy;

  /// No description provided for @nsManana.
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get nsManana;

  /// No description provided for @nsEnDias.
  ///
  /// In es, this message translates to:
  /// **'En {n} días'**
  String nsEnDias(int n);

  /// No description provided for @listaVacia.
  ///
  /// In es, this message translates to:
  /// **'No hay órdenes en estas fechas.'**
  String get listaVacia;

  /// No description provided for @futVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay órdenes para los días que vienen.'**
  String get futVacio;

  /// No description provided for @npVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay servicios nuevos pendientes.'**
  String get npVacio;

  /// No description provided for @defModemRecuperado.
  ///
  /// In es, this message translates to:
  /// **'Módem recuperado'**
  String get defModemRecuperado;

  /// No description provided for @tcActiva.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get tcActiva;

  /// No description provided for @tcReactivada.
  ///
  /// In es, this message translates to:
  /// **'Reactivada'**
  String get tcReactivada;

  /// No description provided for @tcRegresa.
  ///
  /// In es, this message translates to:
  /// **'Regresa el {fecha}'**
  String tcRegresa(String fecha);

  /// No description provided for @tcRecogerModem.
  ///
  /// In es, this message translates to:
  /// **'Recoger módem: {modem}'**
  String tcRecogerModem(String modem);

  /// No description provided for @tcVencida.
  ///
  /// In es, this message translates to:
  /// **'Ya toca regresar'**
  String get tcVencida;

  /// No description provided for @tcPronto.
  ///
  /// In es, this message translates to:
  /// **'Regresa pronto'**
  String get tcPronto;

  /// No description provided for @tcVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay cancelaciones temporales en estas fechas.'**
  String get tcVacio;

  /// No description provided for @ifaExplica.
  ///
  /// In es, this message translates to:
  /// **'Servicios nuevos ya instalados que pagaron al instalarse: hay que eliminar en el ISP la factura de su primer pago para que no les suspendan el servicio.'**
  String get ifaExplica;

  /// No description provided for @ifaFactura.
  ///
  /// In es, this message translates to:
  /// **'Factura del ISP: {fecha}'**
  String ifaFactura(String fecha);

  /// No description provided for @ifaPago.
  ///
  /// In es, this message translates to:
  /// **'Pago del {de} al {a}'**
  String ifaPago(String de, String a);

  /// No description provided for @ifaMarcar.
  ///
  /// In es, this message translates to:
  /// **'Ya la eliminé'**
  String get ifaMarcar;

  /// No description provided for @ifaDeshacer.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get ifaDeshacer;

  /// No description provided for @ifaHecha.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get ifaHecha;

  /// No description provided for @ifaPendientes.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get ifaPendientes;

  /// No description provided for @ifaHechas.
  ///
  /// In es, this message translates to:
  /// **'Completadas'**
  String get ifaHechas;

  /// No description provided for @ifaVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay facturas por eliminar en estas fechas.'**
  String get ifaVacio;

  /// No description provided for @ifaSinFechas.
  ///
  /// In es, this message translates to:
  /// **'No hay Fechas de pago: se configuran en la web, en Sistema › Fechas de pago.'**
  String get ifaSinFechas;

  /// No description provided for @ifaGuardada.
  ///
  /// In es, this message translates to:
  /// **'Marcada como eliminada en el ISP.'**
  String get ifaGuardada;

  /// No description provided for @menuSistema.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get menuSistema;

  /// No description provided for @menuUsuariosApp.
  ///
  /// In es, this message translates to:
  /// **'Usuarios app'**
  String get menuUsuariosApp;

  /// No description provided for @menuRoles.
  ///
  /// In es, this message translates to:
  /// **'Roles'**
  String get menuRoles;

  /// No description provided for @menuOcupacion.
  ///
  /// In es, this message translates to:
  /// **'Ocupación'**
  String get menuOcupacion;

  /// No description provided for @menuLocalidades.
  ///
  /// In es, this message translates to:
  /// **'Localidades'**
  String get menuLocalidades;

  /// No description provided for @menuFechasPago.
  ///
  /// In es, this message translates to:
  /// **'Fechas de pago'**
  String get menuFechasPago;

  /// No description provided for @menuZonas.
  ///
  /// In es, this message translates to:
  /// **'Zonas'**
  String get menuZonas;

  /// No description provided for @menuServicios.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get menuServicios;

  /// No description provided for @menuComisionesCat.
  ///
  /// In es, this message translates to:
  /// **'Comisiones'**
  String get menuComisionesCat;

  /// No description provided for @menuComisionistas.
  ///
  /// In es, this message translates to:
  /// **'Comisionistas'**
  String get menuComisionistas;

  /// No description provided for @menuActivos.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get menuActivos;

  /// No description provided for @menuInsumos.
  ///
  /// In es, this message translates to:
  /// **'Insumos'**
  String get menuInsumos;

  /// No description provided for @menuMotivosCancelacion.
  ///
  /// In es, this message translates to:
  /// **'Motivos de Cancelación'**
  String get menuMotivosCancelacion;

  /// No description provided for @menuCobroServicios.
  ///
  /// In es, this message translates to:
  /// **'Cobro de servicios'**
  String get menuCobroServicios;

  /// No description provided for @menuFormasPago.
  ///
  /// In es, this message translates to:
  /// **'Formas de pago'**
  String get menuFormasPago;

  /// No description provided for @menuPartidaGastos.
  ///
  /// In es, this message translates to:
  /// **'Partida de Gastos'**
  String get menuPartidaGastos;

  /// No description provided for @sisSoloVer.
  ///
  /// In es, this message translates to:
  /// **'Aquí solo se ve. Para agregar o cambiar, usa la web (Sistema).'**
  String get sisSoloVer;

  /// No description provided for @sisVacio.
  ///
  /// In es, this message translates to:
  /// **'No hay nada registrado.'**
  String get sisVacio;

  /// No description provided for @sisBuscar.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get sisBuscar;

  /// No description provided for @sisUsuarios.
  ///
  /// In es, this message translates to:
  /// **'{n} usuarios'**
  String sisUsuarios(int n);

  /// No description provided for @sisPago.
  ///
  /// In es, this message translates to:
  /// **'Pago del {de} al {a}'**
  String sisPago(String de, String a);

  /// No description provided for @sisFacturaDia.
  ///
  /// In es, this message translates to:
  /// **'factura el día {d}'**
  String sisFacturaDia(String d);

  /// No description provided for @sisInstalaciones.
  ///
  /// In es, this message translates to:
  /// **'instalaciones del {de} al {a}'**
  String sisInstalaciones(String de, String a);

  /// No description provided for @sisLlevaComision.
  ///
  /// In es, this message translates to:
  /// **'Lleva comisión'**
  String get sisLlevaComision;

  /// No description provided for @sisLlevaCobro.
  ///
  /// In es, this message translates to:
  /// **'Lleva cobro'**
  String get sisLlevaCobro;

  /// No description provided for @sisLlevaMateriales.
  ///
  /// In es, this message translates to:
  /// **'Lleva materiales'**
  String get sisLlevaMateriales;

  /// No description provided for @sisPideMotivo.
  ///
  /// In es, this message translates to:
  /// **'Pide escribir el motivo'**
  String get sisPideMotivo;

  /// No description provided for @sisAutomatica.
  ///
  /// In es, this message translates to:
  /// **'Se calcula sola'**
  String get sisAutomatica;

  /// No description provided for @sisInactiva.
  ///
  /// In es, this message translates to:
  /// **'Inactiva'**
  String get sisInactiva;

  /// No description provided for @sisSinAcceso.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso a la app'**
  String get sisSinAcceso;

  /// No description provided for @sisAgregar.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get sisAgregar;

  /// No description provided for @sisNuevo.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get sisNuevo;

  /// No description provided for @sisGuardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get sisGuardar;

  /// No description provided for @sisBorrar.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get sisBorrar;

  /// No description provided for @sisGuardado.
  ///
  /// In es, this message translates to:
  /// **'Guardado.'**
  String get sisGuardado;

  /// No description provided for @sisBorrado.
  ///
  /// In es, this message translates to:
  /// **'Borrado: queda en la Papelera de la web.'**
  String get sisBorrado;

  /// No description provided for @sisBorrarPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar «{nombre}»?'**
  String sisBorrarPregunta(String nombre);

  /// No description provided for @sisBorrarTexto.
  ///
  /// In es, this message translates to:
  /// **'Se va a la Papelera de la web; ahí se puede restaurar.'**
  String get sisBorrarTexto;

  /// No description provided for @sisBorrarLocalidad.
  ///
  /// In es, this message translates to:
  /// **'También se borran sus zonas. Las órdenes ya hechas no cambian.'**
  String get sisBorrarLocalidad;

  /// No description provided for @sisNombreFijo.
  ///
  /// In es, this message translates to:
  /// **'El nombre se cambia en la web: allá también se cambia en todas las órdenes que lo usan.'**
  String get sisNombreFijo;

  /// No description provided for @sisElegir.
  ///
  /// In es, this message translates to:
  /// **'Elegir'**
  String get sisElegir;

  /// No description provided for @sisCampoName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get sisCampoName;

  /// No description provided for @sisCampoServiceName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del cobro'**
  String get sisCampoServiceName;

  /// No description provided for @sisCampoDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get sisCampoDescription;

  /// No description provided for @sisCampoAmount.
  ///
  /// In es, this message translates to:
  /// **'Importe'**
  String get sisCampoAmount;

  /// No description provided for @sisCampoPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio'**
  String get sisCampoPrice;

  /// No description provided for @sisCampoUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad (pza, m…)'**
  String get sisCampoUnit;

  /// No description provided for @sisCampoBrand.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get sisCampoBrand;

  /// No description provided for @sisCampoModel.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get sisCampoModel;

  /// No description provided for @sisCampoCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get sisCampoCategory;

  /// No description provided for @sisCampoZoneIds.
  ///
  /// In es, this message translates to:
  /// **'Localidades (sin ninguna = todas)'**
  String get sisCampoZoneIds;

  /// No description provided for @sisCampoLocality.
  ///
  /// In es, this message translates to:
  /// **'Localidad'**
  String get sisCampoLocality;

  /// No description provided for @sisCampoCommissionIds.
  ///
  /// In es, this message translates to:
  /// **'Comisiones que cobra'**
  String get sisCampoCommissionIds;

  /// No description provided for @sisCampoIsp.
  ///
  /// In es, this message translates to:
  /// **'Va con el ISP'**
  String get sisCampoIsp;

  /// No description provided for @sisCampoPayFrom.
  ///
  /// In es, this message translates to:
  /// **'Pago desde el día'**
  String get sisCampoPayFrom;

  /// No description provided for @sisCampoPayTo.
  ///
  /// In es, this message translates to:
  /// **'Pago hasta el día'**
  String get sisCampoPayTo;

  /// No description provided for @sisCampoInvoiceDay.
  ///
  /// In es, this message translates to:
  /// **'Día de la factura del ISP'**
  String get sisCampoInvoiceDay;

  /// No description provided for @sisCampoInstallFrom.
  ///
  /// In es, this message translates to:
  /// **'Instalaciones desde el día'**
  String get sisCampoInstallFrom;

  /// No description provided for @sisCampoInstallTo.
  ///
  /// In es, this message translates to:
  /// **'Instalaciones hasta el día'**
  String get sisCampoInstallTo;

  /// No description provided for @errSisNombre.
  ///
  /// In es, this message translates to:
  /// **'Escribe el nombre.'**
  String get errSisNombre;

  /// No description provided for @errSisYaExiste.
  ///
  /// In es, this message translates to:
  /// **'Ya hay uno con ese nombre.'**
  String get errSisYaExiste;

  /// No description provided for @errSisDia.
  ///
  /// In es, this message translates to:
  /// **'Los días van del 1 al 31.'**
  String get errSisDia;

  /// No description provided for @errSisImporte.
  ///
  /// In es, this message translates to:
  /// **'Escribe un importe válido.'**
  String get errSisImporte;

  /// No description provided for @errSisLocalidad.
  ///
  /// In es, this message translates to:
  /// **'Elige la localidad.'**
  String get errSisLocalidad;

  /// No description provided for @errSisCategoria.
  ///
  /// In es, this message translates to:
  /// **'Elige la categoría.'**
  String get errSisCategoria;

  /// No description provided for @errSisFechaChoca.
  ///
  /// In es, this message translates to:
  /// **'Esos días de instalación ya entran en otra fecha de pago de la misma localidad.'**
  String get errSisFechaChoca;

  /// No description provided for @sisCampoPermission.
  ///
  /// In es, this message translates to:
  /// **'Permiso'**
  String get sisCampoPermission;

  /// No description provided for @errSisPermiso.
  ///
  /// In es, this message translates to:
  /// **'Elige el permiso.'**
  String get errSisPermiso;

  /// No description provided for @permisoAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administrador del sistema (control total)'**
  String get permisoAdmin;

  /// No description provided for @permisoConsultor.
  ///
  /// In es, this message translates to:
  /// **'Consultor (solo ve, no cambia nada)'**
  String get permisoConsultor;

  /// No description provided for @permisoTecnico.
  ///
  /// In es, this message translates to:
  /// **'Técnico (crea y procesa, no borra)'**
  String get permisoTecnico;

  /// No description provided for @usuCorreo.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get usuCorreo;

  /// No description provided for @usuRol.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get usuRol;

  /// No description provided for @usuOcupacion.
  ///
  /// In es, this message translates to:
  /// **'Ocupación'**
  String get usuOcupacion;

  /// No description provided for @usuSinOcupacion.
  ///
  /// In es, this message translates to:
  /// **'Sin ocupación'**
  String get usuSinOcupacion;

  /// No description provided for @usuLocalidadesAyuda.
  ///
  /// In es, this message translates to:
  /// **'Si no marcas ninguna, ve todas.'**
  String get usuLocalidadesAyuda;

  /// No description provided for @usuAsalariado.
  ///
  /// In es, this message translates to:
  /// **'Tiene sueldo'**
  String get usuAsalariado;

  /// No description provided for @usuSueldo.
  ///
  /// In es, this message translates to:
  /// **'Sueldo semanal'**
  String get usuSueldo;

  /// No description provided for @usuComisionista.
  ///
  /// In es, this message translates to:
  /// **'Cobra comisiones'**
  String get usuComisionista;

  /// No description provided for @usuAcceso.
  ///
  /// In es, this message translates to:
  /// **'Entra a la app'**
  String get usuAcceso;

  /// No description provided for @usuUsuario.
  ///
  /// In es, this message translates to:
  /// **'Usuario de la app'**
  String get usuUsuario;

  /// No description provided for @usuUsuarioAyuda.
  ///
  /// In es, this message translates to:
  /// **'De 3 a 30 letras sin acentos, números, punto o guion. Sin espacios.'**
  String get usuUsuarioAyuda;

  /// No description provided for @usuContrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get usuContrasena;

  /// No description provided for @usuContrasenaCambiar.
  ///
  /// In es, this message translates to:
  /// **'Déjala vacía para no cambiarla.'**
  String get usuContrasenaCambiar;

  /// No description provided for @usuContrasenaNueva.
  ///
  /// In es, this message translates to:
  /// **'Al menos 8 caracteres.'**
  String get usuContrasenaNueva;

  /// No description provided for @usuMostrar.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get usuMostrar;

  /// No description provided for @usuOcultar.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get usuOcultar;

  /// No description provided for @usuBorrarTexto.
  ///
  /// In es, this message translates to:
  /// **'Se le quita la entrada a la app y su ficha va a la Papelera de la web. Desde ahí se recupera la ficha; para volver a entrar a la app hay que ponerle una contraseña nueva.'**
  String get usuBorrarTexto;

  /// No description provided for @errUsuTelefono.
  ///
  /// In es, this message translates to:
  /// **'Ese teléfono no es válido para el país elegido. Revisa el número o cambia el país.'**
  String get errUsuTelefono;

  /// No description provided for @errUsuCorreo.
  ///
  /// In es, this message translates to:
  /// **'El correo no es válido (ejemplo: nombre@correo.com).'**
  String get errUsuCorreo;

  /// No description provided for @errUsuCorreoRepetido.
  ///
  /// In es, this message translates to:
  /// **'Ya hay otro usuario con ese correo.'**
  String get errUsuCorreoRepetido;

  /// No description provided for @errUsuRol.
  ///
  /// In es, this message translates to:
  /// **'Elige el rol.'**
  String get errUsuRol;

  /// No description provided for @errUsuSueldo.
  ///
  /// In es, this message translates to:
  /// **'Escribe el sueldo semanal.'**
  String get errUsuSueldo;

  /// No description provided for @errUsuUsuario.
  ///
  /// In es, this message translates to:
  /// **'Escribe el usuario con el que entrará a la app.'**
  String get errUsuUsuario;

  /// No description provided for @errUsuUsuarioFormato.
  ///
  /// In es, this message translates to:
  /// **'El usuario debe tener de 3 a 30 letras sin acentos, números, punto o guion, sin espacios.'**
  String get errUsuUsuarioFormato;

  /// No description provided for @errUsuUsuarioOcupado.
  ///
  /// In es, this message translates to:
  /// **'Ese usuario ya lo tiene otra persona.'**
  String get errUsuUsuarioOcupado;

  /// No description provided for @errUsuContrasena.
  ///
  /// In es, this message translates to:
  /// **'Escribe la contraseña para la app.'**
  String get errUsuContrasena;

  /// No description provided for @errUsuContrasenaCorta.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 8 caracteres.'**
  String get errUsuContrasenaCorta;

  /// No description provided for @errUsuCuenta.
  ///
  /// In es, this message translates to:
  /// **'La ficha se guardó, pero no se pudo dar o cambiar su acceso a la app ({detalle}). Ábrela y vuelve a guardar, o hazlo en la web.'**
  String errUsuCuenta(String detalle);

  /// No description provided for @sisPropioFijo.
  ///
  /// In es, this message translates to:
  /// **'Es el tuyo: se cambia en la web, para que no te quedes sin entrar a la app.'**
  String get sisPropioFijo;
}

class _TextosDelegate extends LocalizationsDelegate<Textos> {
  const _TextosDelegate();

  @override
  Future<Textos> load(Locale locale) {
    return SynchronousFuture<Textos>(lookupTextos(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_TextosDelegate old) => false;
}

Textos lookupTextos(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return TextosEn();
    case 'es':
      return TextosEs();
  }

  throw FlutterError(
    'Textos.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
