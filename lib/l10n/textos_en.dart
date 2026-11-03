// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TextosEn extends Textos {
  TextosEn([String locale = 'en']) : super(locale);

  @override
  String get appTitulo => 'Operia Technicians';

  @override
  String get conectando => 'Connecting';

  @override
  String get tuMundo => 'your world';

  @override
  String get loginSubtitulo => 'Handle your work orders from wherever you are.';

  @override
  String get loginInstruccion =>
      'Sign in with the username and password the office gave you.';

  @override
  String get usuario => 'Username';

  @override
  String get contrasena => 'Password';

  @override
  String get verContrasena => 'Show password';

  @override
  String get ocultarContrasena => 'Hide password';

  @override
  String get entrar => 'Sign in';

  @override
  String get recordarDatos => 'Remember username and password';

  @override
  String get errFaltanDatos => 'Enter your username and password.';

  @override
  String get errDatosIncorrectos => 'Wrong username or password.';

  @override
  String errTipoDesconocido(String detalle) {
    return 'Unknown password type ($detalle). Contact the office.';
  }

  @override
  String get errSinAccesoApp =>
      'Your user has no access to the app. Ask the office for it.';

  @override
  String get errCuentaDesactivada =>
      'Your account is disabled. Contact the office.';

  @override
  String get errDemasiadosIntentos =>
      'Too many attempts in a row. Wait a few minutes and try again.';

  @override
  String get errSinInternet =>
      'No internet connection. Check your mobile data or wifi.';

  @override
  String errOtro(String detalle) {
    return 'Could not complete ($detalle).';
  }

  @override
  String get errYaTomada => 'Another technician already accepted this order.';

  @override
  String get errSinPermiso =>
      'You are not allowed to change this order. Contact the office.';

  @override
  String get navPendientes => 'Pending';

  @override
  String get navEnProceso => 'In progress';

  @override
  String get navCulminadas => 'Done';

  @override
  String get navHistorial => 'History';

  @override
  String get todas => 'All';

  @override
  String get atrasadas => 'Overdue';

  @override
  String get hoy => 'Today';

  @override
  String get proximosDias => 'Upcoming days';

  @override
  String seccion(String titulo, int n) {
    return '$titulo ($n)';
  }

  @override
  String get vacioPendientes => 'There are no pending orders.';

  @override
  String get vacioEnProceso => 'You have no orders in progress.';

  @override
  String get vacioCulminadas => 'No orders have been completed today yet.';

  @override
  String get vacioHistorial => 'There are no orders in the history yet.';

  @override
  String errorCargar(String detalle) {
    return 'Could not load the orders.\nCheck your internet.\n\n($detalle)';
  }

  @override
  String get cargarMas => 'Show more';

  @override
  String hola(String nombre) {
    return 'Hi, $nombre';
  }

  @override
  String get todasLasLocalidades => 'All locations';

  @override
  String get menuAyuda => 'Help and manual';

  @override
  String get menuNovedades => 'What\'s new';

  @override
  String get menuIdioma => 'Language';

  @override
  String get idiomaAutomatico => 'Automatic (phone language)';

  @override
  String get menuApariencia => 'Appearance';

  @override
  String get temaAutomatico => 'Automatic (like the phone)';

  @override
  String get temaClaro => 'Light';

  @override
  String get temaOscuro => 'Dark';

  @override
  String get idiomaEspanol => 'Español';

  @override
  String get idiomaIngles => 'English';

  @override
  String get cerrarSesion => 'Sign out';

  @override
  String get cerrarSesionPregunta => 'Sign out?';

  @override
  String get cerrarSesionTexto =>
      'You will need to enter your username and password again.';

  @override
  String get cancelar => 'Cancel';

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get estPendiente => 'Pending';

  @override
  String get estEnProceso => 'In progress';

  @override
  String get estCompletada => 'Completed';

  @override
  String get estCancelada => 'Cancelled';

  @override
  String get estFaltaCobro => 'Payment due';

  @override
  String get sinNombre => 'No name';

  @override
  String folio(String f) {
    return 'Order $f';
  }

  @override
  String get orden => 'Order';

  @override
  String get sinTecnico => 'No technician';

  @override
  String get llamar => 'Call';

  @override
  String get verEnMapa => 'Open map';

  @override
  String get telefono => 'Phone';

  @override
  String get direccion => 'Address';

  @override
  String get localidad => 'Location';

  @override
  String get servicio => 'Service';

  @override
  String get diaServicio => 'Service day';

  @override
  String get descripcion => 'Description';

  @override
  String get notaOficina => 'Office note';

  @override
  String get tecnico => 'Technician';

  @override
  String get misComentarios => 'My comments';

  @override
  String get comentariosTecnico => 'Technician comments';

  @override
  String culminadaEl(String fecha) {
    return 'Completed: $fecha';
  }

  @override
  String get guardarComentarios => 'Save comments';

  @override
  String get comentariosGuardados => 'Comments saved.';

  @override
  String get empezar => 'Start';

  @override
  String get marcasteInicio => 'Start time saved.';

  @override
  String get aceptarOrden => 'Accept order';

  @override
  String get aceptarPregunta => 'Accept this order?';

  @override
  String get aceptarTexto =>
      'It will be assigned to you and move to «In progress». The office will see it on the web.';

  @override
  String get aceptar => 'Accept';

  @override
  String get ordenAceptada => 'The order is yours now.';

  @override
  String get termine => 'I\'m done';

  @override
  String get terminePregunta => 'Did you finish the job?';

  @override
  String get terminarDirecto => 'The order will be marked as completed.';

  @override
  String get siTermine => 'Yes, I\'m done';

  @override
  String get ordenCompletada => 'Order completed.';

  @override
  String get msgCancelada => 'This order was cancelled.';

  @override
  String get msgCompletada => 'Order completed.';

  @override
  String msgOtroTecnico(String nombre) {
    return 'This order belongs to $nombre.';
  }

  @override
  String get otroTecnicoSinNombre => 'another technician';

  @override
  String get sinSenal =>
      'No signal: it will be sent as soon as there is internet.';

  @override
  String get noSePudoAbrir => 'Could not open it on this phone.';

  @override
  String get cobroTitulo => 'Payment';

  @override
  String cobroPaso(int n) {
    return 'Step $n of 2';
  }

  @override
  String get cobroQueSeCobro => 'What was charged?';

  @override
  String cobroMarcaPlan(String cliente) {
    return 'Select the plan $cliente signed up for.';
  }

  @override
  String cobroMarcaServicio(String cliente) {
    return 'Select what $cliente was charged.';
  }

  @override
  String get elCliente => 'the customer';

  @override
  String get cobroSinConceptos =>
      'There are no charges registered. They are added on the web, in System › Service charges.';

  @override
  String get importe => 'Amount';

  @override
  String get comentarioCobro => 'Charge comment';

  @override
  String get total => 'Total';

  @override
  String get continuar => 'Continue';

  @override
  String get atras => 'Back';

  @override
  String get completarSinCobro => 'Complete without charge';

  @override
  String get cobroComoPago => 'How did the customer pay?';

  @override
  String get pagoEfectivo => 'Cash';

  @override
  String get pagoTransferencia => 'Transfer';

  @override
  String get pagoPendiente => 'Payment pending';

  @override
  String get pagoSinCosto => 'No charge';

  @override
  String get notaEfectivo => 'The order will be completed.';

  @override
  String get notaTransferencia =>
      'Take a photo of the receipt: the office checks it on the web and completes the order.';

  @override
  String get notaPendiente =>
      'The order stays in progress until the office approves it; the customer will owe the payment.';

  @override
  String get notaSinCosto =>
      'Nothing is charged. The order stays in progress until the office approves it.';

  @override
  String get guardarCompletar => 'Save and complete';

  @override
  String get enviarOficina => 'Send to the office';

  @override
  String get elegirFormaPago => 'Choose how the customer paid.';

  @override
  String errImporteCobro(String nombre) {
    return 'Enter a valid amount for «$nombre».';
  }

  @override
  String errNotaCobro(String nombre) {
    return 'Write a comment explaining the charge for «$nombre».';
  }

  @override
  String get cobroEnviado => 'Done, it was sent to the office.';

  @override
  String get msgPorAutorizar =>
      'Waiting for the office to approve the payment.';

  @override
  String get msgTransferencia =>
      'The office will check the transfer receipt and complete the order.';

  @override
  String get estPorAutorizar => 'To approve';

  @override
  String get ayudaTitulo => 'Help';

  @override
  String get pestManual => 'Manual';

  @override
  String get pestNovedades => 'What\'s new';

  @override
  String get pestAcerca => 'About';

  @override
  String get acercaTexto =>
      'Operia\'s technician app. It uses the same data as the web: what you do here the office sees right away.';

  @override
  String get versionInstalada => 'Installed version';

  @override
  String get usuarioActual => 'User';

  @override
  String get rol => 'Role';

  @override
  String get menuIps => 'Free IPs';

  @override
  String get ipsDescripcion =>
      'Reserve the IP you are going to use so nobody else takes it.';

  @override
  String ipsRouter(String fecha) {
    return 'Router list: $fecha';
  }

  @override
  String get ipsLibres => 'Free';

  @override
  String get ipsOcupadas => 'Taken';

  @override
  String get ipsMias => 'Mine';

  @override
  String get ipsTodas => 'All';

  @override
  String get ipsBuscar => 'Search IP or segment';

  @override
  String get ipsVacio =>
      'No IPs have been published for your locations yet. The office publishes them on the web, in Tools › Free IPs.';

  @override
  String get ipsSinFiltro => 'No IPs match these filters.';

  @override
  String ipsVlan(String vlan) {
    return 'VLAN $vlan';
  }

  @override
  String ipsCuantasLibres(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n free',
      one: '1 free',
    );
    return '$_temp0';
  }

  @override
  String get ipsLibre => 'Free';

  @override
  String get ipsOcupada => 'Taken';

  @override
  String get ipsDesdeApp => 'from the app';

  @override
  String get ipsDesdeWeb => 'from the web';

  @override
  String get ipsApartar => 'Reserve';

  @override
  String get ipsLiberar => 'Release';

  @override
  String ipsApartarPregunta(String ip) {
    return 'Reserve IP $ip?';
  }

  @override
  String get ipsApartarTexto =>
      'It is marked as taken under your name so nobody else uses it. The office and other technicians see it right away.';

  @override
  String ipsLiberarPregunta(String ip) {
    return 'Release IP $ip?';
  }

  @override
  String get ipsLiberarTexto =>
      'It becomes free again so someone else can use it.';

  @override
  String ipsApartadaOk(String ip) {
    return 'You reserved IP $ip: it now shows as taken.';
  }

  @override
  String ipsLiberadaOk(String ip) {
    return 'You released IP $ip.';
  }

  @override
  String get ipsCopiar => 'Copy IP';

  @override
  String ipsCopiada(String ip) {
    return 'IP $ip copied.';
  }

  @override
  String get errIpOcupada =>
      'That IP is no longer free: someone else took it or the office changed the list.';

  @override
  String get ipsTodasVlan => 'All';

  @override
  String get ipsFiltroVlan => 'VLAN';

  @override
  String get ipsFiltroSegmentos => 'Segments (pick one or more)';

  @override
  String terminosAntes(String nombre) {
    return 'Before you start, $nombre';
  }

  @override
  String get terminosTitulo => 'Terms and conditions';

  @override
  String terminosActualizados(String fecha) {
    return 'Updated: $fecha';
  }

  @override
  String get terminosDesliza => 'Scroll to the end to be able to accept';

  @override
  String get terminosLeiAcepto =>
      'I have read and accept the terms and conditions';

  @override
  String get terminosAceptar => 'Accept and enter';

  @override
  String get terminosNoAcepto => 'I do not accept';

  @override
  String get terminosSalirPregunta => 'Leave without accepting?';

  @override
  String get terminosSalirTexto =>
      'You need to accept the terms and conditions to use the app. You can sign in again whenever you want.';

  @override
  String get terminosSalir => 'Leave';

  @override
  String get histTodasFechas => 'All dates';

  @override
  String get histSemana => 'This week';

  @override
  String get histMes => 'This month';

  @override
  String get histMesAnterior => 'Last month';

  @override
  String get histElegirFechas => 'Choose dates';

  @override
  String get histVacioRango => 'No orders were created on those dates.';

  @override
  String get buscarOrdenes => 'Search: customer, folio, phone, address…';

  @override
  String buscarSinResultados(String texto) {
    return 'No orders match «$texto».';
  }

  @override
  String get avisoCanalFijo => 'Ongoing notice';

  @override
  String get avisoCanalOrdenes => 'New orders';

  @override
  String get avisoFijoTitulo => 'Watching for new orders';

  @override
  String get avisoFijoTexto =>
      'I will let you know as soon as an order arrives.';

  @override
  String avisoFijoPendientes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pending orders',
      one: '1 pending order',
      zero: 'No pending orders',
    );
    return '$_temp0';
  }

  @override
  String avisoNueva(String folio) {
    return 'New order $folio';
  }

  @override
  String avisoAsignada(String folio) {
    return 'Order $folio was assigned to you';
  }

  @override
  String get nuevaOrden => 'New order';

  @override
  String get editarOrden => 'Edit order';

  @override
  String get foSubtituloNueva =>
      'Fill in the details: the office and technicians see it right away.';

  @override
  String get foSeccionCliente => 'Customer';

  @override
  String get foCliente => 'Customer name';

  @override
  String get foDireccion =>
      'Address (street, number, neighborhood, references)';

  @override
  String get foSeccionUbicacion => 'Location';

  @override
  String get foCoordenadas => 'Coordinates or Google Maps link';

  @override
  String get foMiUbicacion => 'Use my location';

  @override
  String get foElegirServicio => 'Choose the service';

  @override
  String get foCuando => 'When?';

  @override
  String get foManana => 'Tomorrow';

  @override
  String get foOtroDia => 'Another day';

  @override
  String get foSinHora => 'No time';

  @override
  String get foElegirHora => 'Choose time';

  @override
  String get foCrear => 'Create order';

  @override
  String get foGuardar => 'Save changes';

  @override
  String get errFoCliente => 'Enter the customer name.';

  @override
  String errFoTelefono(String pais) {
    return 'That phone number is not valid for $pais. Check the number or change the country.';
  }

  @override
  String get errFoCoordenadas =>
      'Those coordinates are not valid: type «latitude, longitude» or paste a Google Maps link.';

  @override
  String get errFoLocalidad => 'Choose the location.';

  @override
  String get errFoServicio => 'Choose the service.';

  @override
  String get errFoDiaPasado => 'The day cannot be before today.';

  @override
  String get errFoHoraPasada => 'That time has already passed.';

  @override
  String get errFoCompletadaFutura =>
      'A completed order cannot be moved to a future day.';

  @override
  String get errUbicacionApagada => 'Turn on the phone location.';

  @override
  String get errUbicacionPermiso =>
      'No location permission: turn it on in the phone settings.';

  @override
  String get errUbicacionOtro => 'Could not get the location. Try again.';

  @override
  String ordenCreada(String folio) {
    return 'Done: order $folio was created.';
  }

  @override
  String get ordenGuardada => 'Changes saved.';

  @override
  String get menuEditar => 'Edit';

  @override
  String get menuEliminar => 'Delete';

  @override
  String eliminarPregunta(String folio) {
    return 'Delete order $folio?';
  }

  @override
  String get eliminarTexto =>
      'It goes to the web Trash: it can be restored there for 30 days.';

  @override
  String get ordenEliminada => 'The order was moved to the Trash.';

  @override
  String get msgSoloConsulta =>
      'Your role is view-only: you can see the order but not change it.';

  @override
  String get menuModems => 'Modems to recover';

  @override
  String get menuComisiones => 'Commission payments';

  @override
  String get modemDescripcion =>
      'Customers who cancelled: a commissioner picks up the modem and it is marked when brought back.';

  @override
  String get modemSinAsignar => 'Unassigned';

  @override
  String get modemAsignados => 'Assigned';

  @override
  String get modemInternet => 'Internet modem';

  @override
  String get modemDoblePlay => 'Double Play modem';

  @override
  String get modemLoRecuperasTu => 'You recover it';

  @override
  String modemLoRecupera(String nombre) {
    return '$nombre recovers it';
  }

  @override
  String modemComision(String importe) {
    return 'Commission $importe';
  }

  @override
  String get modemSoltar => 'Release';

  @override
  String get modemAsignar => 'Assign';

  @override
  String get modemYaLoRecupere => 'I recovered it';

  @override
  String get modemQuienRecupera => 'Which commissioner picks up the modem?';

  @override
  String get modemSoltado => 'The modem is unassigned now.';

  @override
  String modemAsignadoA(String nombre) {
    return 'Modem assigned to $nombre.';
  }

  @override
  String get modemRecuperadoPregunta => 'Do you have the modem?';

  @override
  String modemRecuperadoTexto(String cliente) {
    return 'Confirm that the modem from $cliente was recovered. The office sees it right away.';
  }

  @override
  String modemGanas(String importe) {
    return 'Commission: $importe.';
  }

  @override
  String get modemRecuperadoOk =>
      'Done! Modem recovered: the commission now counts.';

  @override
  String get modemVacio => 'No modems to recover. All caught up!';

  @override
  String get modemVacioFiltro => 'No modems with this filter.';

  @override
  String get comTotalPeriodo => 'Total for the period';

  @override
  String get comPorEntregar => 'To be paid';

  @override
  String get comEntregadas => 'Paid';

  @override
  String get comEntregada => 'Paid';

  @override
  String get comSinImporte => 'No amount';

  @override
  String get comVacio => 'No commissions in this period.';

  @override
  String get foOpcional => 'Optional';

  @override
  String get foBuscarPais => 'Search country or code';

  @override
  String get foLlegaSinTecnico =>
      'The order arrives without a technician: the first one who accepts it takes it.';

  @override
  String get foDatosNuevo => 'New service details';

  @override
  String get foPlan => 'Plan (modem to install)';

  @override
  String get foTelevisiones => 'TVs';

  @override
  String get foTvConCosto => 'Paid TVs';

  @override
  String get foTvSinCosto => 'Free TVs';

  @override
  String foTvPrecio(String precio, String total) {
    return 'Each paid TV is charged $precio when completing. Total: $total.';
  }

  @override
  String get foQuienLoConsiguio => 'Who brought this service?';

  @override
  String get foNingunoSinComision => 'Nobody (no commission)';

  @override
  String get foDatosBaja => 'Permanent cancellation';

  @override
  String get foMotivo => 'Reason';

  @override
  String get foOtros => 'Other';

  @override
  String get foEscribeMotivo => 'Type the reason';

  @override
  String get foModemRecuperar => 'Modem to recover';

  @override
  String get foDatosTemporal => 'Temporary cancellation';

  @override
  String get foMotivoOpcional => 'Reason (optional)';

  @override
  String get foRecogeModem => 'Is the modem picked up?';

  @override
  String get foSi => 'Yes';

  @override
  String get foNo => 'No';

  @override
  String get foModemSeRecoge => 'Modem picked up';

  @override
  String get foFechaRegreso => 'Expected return date';

  @override
  String get foElegirFecha => 'Choose date';

  @override
  String get foFechaRegresoAyuda => 'The web warns 3 days before.';

  @override
  String get foSinCategoriasModem =>
      'There are no modem categories: add them on the web (System › Assets).';

  @override
  String get errFoPlan => 'Choose the plan (the modem to install).';

  @override
  String get errFoComision =>
      'Choose the commission of who brought the service.';

  @override
  String get errFoMotivo => 'Choose the cancellation reason.';

  @override
  String get errFoMotivoOtro => 'Type the cancellation reason.';

  @override
  String get errFoModem => 'Choose the modem category.';

  @override
  String get errFoRecoge => 'Choose whether the modem is picked up.';

  @override
  String get errFoRegreso => 'Choose the expected return date.';

  @override
  String get errFoRegresoPasada => 'The return date cannot be before today.';

  @override
  String get menuAdmin => 'Administration';

  @override
  String get menuDashboard => 'Dashboard';

  @override
  String get menuOrdenesTrabajo => 'Work orders';

  @override
  String get menuDelDia => 'Today';

  @override
  String get menuHistorico => 'History';

  @override
  String get menuPorAutorizar => 'To authorize';

  @override
  String get menuRecuperarModem => 'Modem recovery';

  @override
  String get menuReportes => 'Reports';

  @override
  String get menuHerramientas => 'Tools';

  @override
  String get dashRecibidas => 'Requests';

  @override
  String get dashRecibidasSub => 'received';

  @override
  String get dashCompletadas => 'Completed';

  @override
  String dashCumplimiento(int p) {
    return '$p% completion';
  }

  @override
  String get dashAbiertas => 'Open';

  @override
  String dashAbiertasSub(int p, int e) {
    return '$p pending · $e in progress';
  }

  @override
  String get dashTiempo => 'Service time';

  @override
  String dashTiempoSub(int n) {
    return 'average of $n jobs';
  }

  @override
  String get dashNuevos => 'New services';

  @override
  String get dashNuevosSub => 'installations';

  @override
  String get dashIngresos => 'Collected income';

  @override
  String dashIngresosSub(int n) {
    return '$n payments';
  }

  @override
  String get dashPorCobrar => 'Pending payment';

  @override
  String get dashPorCobrarSub => 'to collect';

  @override
  String get dashPospuestas => 'Postponed';

  @override
  String get dashCanceladas => 'Cancelled';

  @override
  String dashDeLasSolicitudes(int p) {
    return '$p% of requests';
  }

  @override
  String dashVsAnterior(int dias) {
    return 'Arrows compare with the previous $dias days.';
  }

  @override
  String get dashSinDato => '—';

  @override
  String dashMinutos(int m) {
    return '$m min';
  }

  @override
  String dashHoras(String h) {
    return '$h h';
  }

  @override
  String dashDias(String d) {
    return '$d days';
  }

  @override
  String get dashTendencia => 'Received and completed';

  @override
  String get dashEstados => 'Where requests stand';

  @override
  String get dashPorLocalidad => 'By locality';

  @override
  String get dashPorTecnico => 'By technician';

  @override
  String dashLocalidadDetalle(int n, int d) {
    return '$n received · $d completed';
  }

  @override
  String dashTecnicoDetalle(int n, String tiempo) {
    return '$n completed · $tiempo on average';
  }

  @override
  String get dashSinLocalidad => 'No locality';

  @override
  String get dashSinDatos => 'No orders were registered in these dates.';

  @override
  String get dashNota =>
      'Counts orders registered in the period (like the web Dashboard). By technician: the ones completed in the period.';

  @override
  String get dashToca => 'Tap a bar to see its numbers.';

  @override
  String dashTramo(String fecha, int r, int c) {
    return '$fecha: $r received · $c completed';
  }

  @override
  String get autVacio => 'No payments waiting for authorization.';

  @override
  String get autNota =>
      'They are authorized on the web, in Finance › Pending payments.';

  @override
  String get dashNuevo => 'New';

  @override
  String dashPuntos(String n) {
    return '$n pts';
  }

  @override
  String avisoRegreso(String folio) {
    return 'Order $folio is back in Pending';
  }

  @override
  String get comNota =>
      'Commissions are paid to commissioners (System › Commissioners on the web). They are handed over from the web.';

  @override
  String get comTipoInstalacion => 'Installation';

  @override
  String get comTipoModem => 'Recovered modem';

  @override
  String get comTipoIsp => 'Modem from ISP imports';

  @override
  String get comSinNombre => 'No name';

  @override
  String comDeQuien(String nombre, String importe) {
    return '$nombre · $importe';
  }

  @override
  String get menuFinanzas => 'Finance';

  @override
  String get menuResumenFinanzas => 'Summary';

  @override
  String get finResultado => 'Period result';

  @override
  String get finEntradas => 'Income';

  @override
  String get finSalidas => 'Expenses';

  @override
  String get finIngresosServicios => 'Service income';

  @override
  String get finCobrosOrdenes => 'Order payments';

  @override
  String finCobrosDetalle(int n) {
    return '$n orders paid in cash or transfer';
  }

  @override
  String get finGastos => 'Expenses';

  @override
  String get finComisiones => 'Commissions';

  @override
  String get finComisionesNoCuentan =>
      'Not counted as an expense: the web has no commissions category.';

  @override
  String get finSinFormaPago => 'No payment method';

  @override
  String get finOtrosGastos => 'Other expenses';

  @override
  String get finNada => 'Nothing in this period.';

  @override
  String get finNota =>
      'A summary of the web Financial statement. Salaries and materials are on the web.';

  @override
  String get comTodos => 'All commissioners';

  @override
  String get matTitulo => 'Materials';

  @override
  String get matExplica =>
      'Mark the modem installed and the supplies used. They come out of the office inventory.';

  @override
  String get matModem => 'Modem installed';

  @override
  String get matModemNinguno => 'None';

  @override
  String get matModemNingunoSub => 'No modem was installed (no cost)';

  @override
  String get matInsumos => 'Uses supplies';

  @override
  String get matInsumoElige => 'Choose the supply';

  @override
  String get matCantidad => 'Quantity';

  @override
  String get matAgregar => 'Add supply';

  @override
  String get matQuitar => 'Remove';

  @override
  String get matSinPred =>
      'This service has no default supplies: add them if any were used.';

  @override
  String get matGastoModem => 'Modem cost';

  @override
  String get matGastoInsumos => 'Supplies cost';

  @override
  String get matTotal => 'Materials total';

  @override
  String get matContinuar => 'Continue';

  @override
  String get matSinLista =>
      'No signal to read the materials list: the order is finished anyway and the office records them on the web.';

  @override
  String get menuInconclusas => 'Incomplete';

  @override
  String get incMarcar => 'Mark incomplete';

  @override
  String get incTitulo => 'Incomplete order';

  @override
  String get incExplica =>
      'It was completed but something is pending. Choose when to come back and what is missing.';

  @override
  String get incFecha => 'Return date';

  @override
  String get incMotivo => 'What is pending?';

  @override
  String get incChipModem => 'Correct modem missing';

  @override
  String get incChipMaterial => 'Material missing';

  @override
  String get incChipTerminar => 'Installation not finished';

  @override
  String get incChipSenal => 'Come back to check the signal';

  @override
  String get incGuardar => 'Save';

  @override
  String get incFaltaFecha => 'Choose the return date.';

  @override
  String get incFaltaMotivo => 'Write what is pending.';

  @override
  String get incGuardada => 'Order marked as incomplete.';

  @override
  String get incResolver => 'Resolve';

  @override
  String get incResolverPregunta => 'Is it resolved?';

  @override
  String incResolverTexto(String folio) {
    return 'Order $folio will no longer be incomplete.';
  }

  @override
  String get incResuelta => 'Incomplete order resolved.';

  @override
  String incVuelve(String fecha) {
    return 'Back on $fecha';
  }

  @override
  String get incSinFecha => 'No return date';

  @override
  String get incAtrasadas => 'Overdue';

  @override
  String get incProximas => 'Upcoming';

  @override
  String get incVacio => 'No incomplete orders. All done!';

  @override
  String get incCambiar => 'Change';

  @override
  String get menuProspectos => 'Prospects';

  @override
  String get prosNuevo => 'New prospect';

  @override
  String get prosEditar => 'Edit prospect';

  @override
  String get prosExplica =>
      'A possible new-service customer. No field is required.';

  @override
  String get prosNombre => 'Name';

  @override
  String get prosSinLocalidad => 'No locality';

  @override
  String get prosQuien => 'Who found this prospect?';

  @override
  String get prosNadie => 'Nobody';

  @override
  String get prosDia => 'Installation date';

  @override
  String get prosSinDia => 'No date';

  @override
  String get prosComentario => 'Comment';

  @override
  String get prosFoto => 'Photo';

  @override
  String get prosTomarFoto => 'Take photo';

  @override
  String get prosGaleria => 'Gallery';

  @override
  String get prosQuitarFoto => 'Remove photo';

  @override
  String get prosFotoError => 'That photo could not be used.';

  @override
  String get prosGuardar => 'Save';

  @override
  String get prosGuardado => 'Prospect saved.';

  @override
  String get prosCrearOrden => 'Create order';

  @override
  String prosAsignado(String folio) {
    return 'Done: the prospect was assigned to order $folio.';
  }

  @override
  String prosDescripcionOrden(String texto) {
    return 'Prospect: $texto';
  }

  @override
  String get prosVacio => 'No prospects in these dates.';

  @override
  String get prosPendientes => 'Pending';

  @override
  String get prosAsignados => 'Assigned';

  @override
  String get prosLuzHoy => 'Install today (or overdue)';

  @override
  String get prosLuzManana => 'Install tomorrow';

  @override
  String prosOrden(String folio) {
    return 'Order $folio';
  }

  @override
  String get errProsDiaPasado =>
      'The installation date cannot be before today.';

  @override
  String get menuMapaDia => 'Map of the day';

  @override
  String get mapaCalles => 'Streets';

  @override
  String get mapaSatelite => 'Satellite';

  @override
  String mapaSinUbicacion(int n) {
    return '$n without location';
  }

  @override
  String get mapaVacio => 'No orders for today with a location.';

  @override
  String get mapaCreditos => '© OpenStreetMap · Esri';

  @override
  String get mapaCentrar => 'Show all';

  @override
  String get fotTitulo => 'Work photos';

  @override
  String get fotNinguna =>
      'No photos yet. Take photos of the work: the office sees them on the web.';

  @override
  String fotMax(int n) {
    return 'Up to $n photos per order.';
  }

  @override
  String get fotGuardadas => 'Photos saved.';

  @override
  String get fotQuitarPregunta => 'Remove this photo?';

  @override
  String get fotQuitarTexto => 'It is also removed from the order on the web.';

  @override
  String get fotQuitar => 'Remove';

  @override
  String get compTitulo => 'Transfer receipt';

  @override
  String get compExplica =>
      'Optional but helpful: with the photo the office completes the order without asking again.';
}
