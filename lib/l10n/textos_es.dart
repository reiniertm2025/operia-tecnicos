// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'textos.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class TextosEs extends Textos {
  TextosEs([String locale = 'es']) : super(locale);

  @override
  String get appTitulo => 'Operia Técnicos';

  @override
  String get conectando => 'Conectando';

  @override
  String get tuMundo => 'tu mundo';

  @override
  String get loginSubtitulo => 'Atiende tus órdenes de trabajo desde donde estés.';

  @override
  String get loginInstruccion => 'Entra con el usuario y la contraseña que te dio la oficina.';

  @override
  String get usuario => 'Usuario';

  @override
  String get contrasena => 'Contraseña';

  @override
  String get verContrasena => 'Ver contraseña';

  @override
  String get ocultarContrasena => 'Ocultar contraseña';

  @override
  String get entrar => 'Entrar';

  @override
  String get recordarDatos => 'Recordar usuario y contraseña';

  @override
  String get errFaltanDatos => 'Escribe tu usuario y tu contraseña.';

  @override
  String get errDatosIncorrectos => 'Usuario o contraseña incorrectos.';

  @override
  String errTipoDesconocido(String detalle) {
    return 'Tipo de contraseña desconocido ($detalle). Habla con la oficina.';
  }

  @override
  String get errSinAccesoApp => 'Tu usuario no tiene acceso a la app. Pídeselo a la oficina.';

  @override
  String get errCuentaDesactivada => 'Tu cuenta está desactivada. Habla con la oficina.';

  @override
  String get errDemasiadosIntentos => 'Demasiados intentos seguidos. Espera unos minutos y vuelve a intentar.';

  @override
  String get errSinInternet => 'No hay conexión a internet. Revisa tus datos o el wifi.';

  @override
  String errOtro(String detalle) {
    return 'No se pudo completar ($detalle).';
  }

  @override
  String get errYaTomada => 'Otro técnico ya aceptó esta orden.';

  @override
  String get errSinPermiso => 'No tienes permiso para cambiar esta orden. Habla con la oficina.';

  @override
  String get navPendientes => 'Pendientes';

  @override
  String get navEnProceso => 'En proceso';

  @override
  String get navCulminadas => 'Culminadas';

  @override
  String get navHistorial => 'Historial';

  @override
  String get todas => 'Todas';

  @override
  String get atrasadas => 'Atrasadas';

  @override
  String get hoy => 'Hoy';

  @override
  String get proximosDias => 'Próximos días';

  @override
  String seccion(String titulo, int n) {
    return '$titulo ($n)';
  }

  @override
  String get vacioPendientes => 'No hay órdenes pendientes.';

  @override
  String get vacioEnProceso => 'No tienes órdenes en proceso.';

  @override
  String get vacioCulminadas => 'Hoy todavía no se culmina ninguna orden.';

  @override
  String get vacioHistorial => 'Todavía no hay órdenes en el historial.';

  @override
  String errorCargar(String detalle) {
    return 'No se pudieron cargar las órdenes.\nRevisa tu internet.\n\n($detalle)';
  }

  @override
  String get cargarMas => 'Ver más';

  @override
  String hola(String nombre) {
    return 'Hola, $nombre';
  }

  @override
  String get todasLasLocalidades => 'Todas las localidades';

  @override
  String get menuAyuda => 'Ayuda y manual';

  @override
  String get menuNovedades => 'Novedades';

  @override
  String get menuIdioma => 'Idioma';

  @override
  String get idiomaAutomatico => 'Automático (el del teléfono)';

  @override
  String get menuApariencia => 'Apariencia';

  @override
  String get temaAutomatico => 'Automático (como el teléfono)';

  @override
  String get temaClaro => 'Claro';

  @override
  String get temaOscuro => 'Oscuro';

  @override
  String get idiomaEspanol => 'Español';

  @override
  String get idiomaIngles => 'English';

  @override
  String get cerrarSesion => 'Cerrar sesión';

  @override
  String get cerrarSesionPregunta => '¿Cerrar sesión?';

  @override
  String get cerrarSesionTexto => 'Tendrás que volver a escribir tu usuario y contraseña.';

  @override
  String get cancelar => 'Cancelar';

  @override
  String version(String v) {
    return 'Versión $v';
  }

  @override
  String get estPendiente => 'Pendiente';

  @override
  String get estEnProceso => 'En proceso';

  @override
  String get estCompletada => 'Completada';

  @override
  String get estCancelada => 'Cancelada';

  @override
  String get estFaltaCobro => 'Falta cobro';

  @override
  String get sinNombre => 'Sin nombre';

  @override
  String folio(String f) {
    return 'Folio $f';
  }

  @override
  String get orden => 'Orden';

  @override
  String get sinTecnico => 'Sin técnico';

  @override
  String get llamar => 'Llamar';

  @override
  String get verEnMapa => 'Ver en mapa';

  @override
  String get telefono => 'Teléfono';

  @override
  String get direccion => 'Dirección';

  @override
  String get localidad => 'Localidad';

  @override
  String get servicio => 'Servicio';

  @override
  String get diaServicio => 'Día de servicio';

  @override
  String get descripcion => 'Descripción';

  @override
  String get notaOficina => 'Nota de la oficina';

  @override
  String get tecnico => 'Técnico';

  @override
  String get misComentarios => 'Mis comentarios';

  @override
  String get comentariosTecnico => 'Comentarios del técnico';

  @override
  String culminadaEl(String fecha) {
    return 'Culminada: $fecha';
  }

  @override
  String get guardarComentarios => 'Guardar comentarios';

  @override
  String get comentariosGuardados => 'Comentarios guardados.';

  @override
  String get empezar => 'Empezar';

  @override
  String get marcasteInicio => 'Marcaste el inicio.';

  @override
  String get aceptarOrden => 'Aceptar orden';

  @override
  String get aceptarPregunta => '¿Aceptar esta orden?';

  @override
  String get aceptarTexto => 'Quedará a tu nombre y pasará a «En proceso». La oficina lo verá en la web.';

  @override
  String get aceptar => 'Aceptar';

  @override
  String get ordenAceptada => 'La orden ya es tuya.';

  @override
  String get termine => 'Terminé';

  @override
  String get terminePregunta => '¿Terminaste el trabajo?';

  @override
  String get terminarDirecto => 'La orden quedará como completada.';

  @override
  String get siTermine => 'Sí, terminé';

  @override
  String get ordenCompletada => 'Orden completada.';

  @override
  String get msgCancelada => 'Esta orden fue cancelada.';

  @override
  String get msgCompletada => 'Orden completada.';

  @override
  String msgOtroTecnico(String nombre) {
    return 'Esta orden la tiene $nombre.';
  }

  @override
  String get otroTecnicoSinNombre => 'otro técnico';

  @override
  String get sinSenal => 'Sin señal: se enviará en cuanto haya internet.';

  @override
  String get noSePudoAbrir => 'No se pudo abrir en este celular.';

  @override
  String get cobroTitulo => 'Cobro';

  @override
  String cobroPaso(int n) {
    return 'Paso $n de 2';
  }

  @override
  String get cobroQueSeCobro => '¿Qué se cobró?';

  @override
  String cobroMarcaPlan(String cliente) {
    return 'Marca el plan que contrató $cliente.';
  }

  @override
  String cobroMarcaServicio(String cliente) {
    return 'Marca lo que se le cobró a $cliente.';
  }

  @override
  String get elCliente => 'el cliente';

  @override
  String get cobroSinConceptos => 'No hay cobros registrados. Se agregan en la web, en Sistema › Cobro de servicios.';

  @override
  String get importe => 'Importe';

  @override
  String get comentarioCobro => 'Comentario del cobro';

  @override
  String get total => 'Total';

  @override
  String get continuar => 'Continuar';

  @override
  String get atras => 'Atrás';

  @override
  String get completarSinCobro => 'Completar sin cobro';

  @override
  String get cobroComoPago => '¿Cómo pagó el cliente?';

  @override
  String get pagoEfectivo => 'Efectivo';

  @override
  String get pagoTransferencia => 'Transferencia';

  @override
  String get pagoPendiente => 'Pendiente de pago';

  @override
  String get pagoSinCosto => 'Sin costo';

  @override
  String get notaEfectivo => 'La orden quedará completada.';

  @override
  String get notaTransferencia => 'Toma foto del comprobante: la oficina lo revisa en la web y completa la orden.';

  @override
  String get notaPendiente =>
      'La orden sigue en proceso hasta que la oficina lo autorice; el cliente quedará pendiente de pago.';

  @override
  String get notaSinCosto => 'No se cobra. La orden sigue en proceso hasta que la oficina lo autorice.';

  @override
  String get guardarCompletar => 'Guardar y completar';

  @override
  String get enviarOficina => 'Enviar a la oficina';

  @override
  String get elegirFormaPago => 'Elige cómo pagó el cliente.';

  @override
  String errImporteCobro(String nombre) {
    return 'Escribe un importe válido para «$nombre».';
  }

  @override
  String errNotaCobro(String nombre) {
    return 'Escribe un comentario que explique el cobro de «$nombre».';
  }

  @override
  String get cobroEnviado => 'Listo, se envió a la oficina.';

  @override
  String get msgPorAutorizar => 'Esperando que la oficina autorice el cobro.';

  @override
  String get msgTransferencia => 'La oficina revisará el comprobante de la transferencia y completará la orden.';

  @override
  String get estPorAutorizar => 'Por autorizar';

  @override
  String get ayudaTitulo => 'Ayuda';

  @override
  String get pestManual => 'Manual';

  @override
  String get pestNovedades => 'Novedades';

  @override
  String get pestAcerca => 'Acerca de';

  @override
  String get acercaTexto =>
      'App de los técnicos de Operia. Usa la misma información que la web: lo que haces aquí lo ve la oficina al momento.';

  @override
  String get versionInstalada => 'Versión instalada';

  @override
  String get usuarioActual => 'Usuario';

  @override
  String get rol => 'Rol';

  @override
  String get menuIps => 'IPs libres';

  @override
  String get ipsDescripcion => 'Aparta la IP que vas a usar para que nadie más la tome.';

  @override
  String ipsRouter(String fecha) {
    return 'Lista del router: $fecha';
  }

  @override
  String get ipsLibres => 'Libres';

  @override
  String get ipsOcupadas => 'Ocupadas';

  @override
  String get ipsMias => 'Mías';

  @override
  String get ipsTodas => 'Todas';

  @override
  String get ipsBuscar => 'Buscar IP o segmento';

  @override
  String get ipsVacio =>
      'Todavía no hay IPs publicadas para tus localidades. La oficina las publica desde la web, en Herramientas › IPs libres.';

  @override
  String get ipsSinFiltro => 'No hay IPs con estos filtros.';

  @override
  String ipsVlan(String vlan) {
    return 'VLAN $vlan';
  }

  @override
  String ipsCuantasLibres(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n libres', one: '1 libre');
    return '$_temp0';
  }

  @override
  String get ipsLibre => 'Libre';

  @override
  String get ipsOcupada => 'Ocupada';

  @override
  String get ipsDesdeApp => 'desde la app';

  @override
  String get ipsDesdeWeb => 'desde la web';

  @override
  String get ipsApartar => 'Apartar';

  @override
  String get ipsLiberar => 'Liberar';

  @override
  String ipsApartarPregunta(String ip) {
    return '¿Apartar la IP $ip?';
  }

  @override
  String get ipsApartarTexto =>
      'Queda ocupada a tu nombre para que nadie más la use. La oficina y los demás técnicos lo ven al momento.';

  @override
  String ipsLiberarPregunta(String ip) {
    return '¿Liberar la IP $ip?';
  }

  @override
  String get ipsLiberarTexto => 'Vuelve a quedar libre para que otra persona la pueda usar.';

  @override
  String ipsApartadaOk(String ip) {
    return 'Apartaste la IP $ip: ya sale ocupada.';
  }

  @override
  String ipsLiberadaOk(String ip) {
    return 'Liberaste la IP $ip.';
  }

  @override
  String get ipsCopiar => 'Copiar IP';

  @override
  String ipsCopiada(String ip) {
    return 'IP $ip copiada.';
  }

  @override
  String get errIpOcupada => 'Esa IP ya no está libre: otra persona la ocupó o la oficina cambió la lista.';

  @override
  String get ipsTodasVlan => 'Todas';

  @override
  String get ipsFiltroVlan => 'VLAN';

  @override
  String get ipsFiltroSegmentos => 'Segmentos (marca uno o varios)';

  @override
  String terminosAntes(String nombre) {
    return 'Antes de empezar, $nombre';
  }

  @override
  String get terminosTitulo => 'Términos y condiciones';

  @override
  String terminosActualizados(String fecha) {
    return 'Actualizados: $fecha';
  }

  @override
  String get terminosDesliza => 'Desliza hasta el final para poder aceptar';

  @override
  String get terminosLeiAcepto => 'Leí y acepto los términos y condiciones';

  @override
  String get terminosAceptar => 'Aceptar y entrar';

  @override
  String get terminosNoAcepto => 'No acepto';

  @override
  String get terminosSalirPregunta => '¿Salir sin aceptar?';

  @override
  String get terminosSalirTexto =>
      'Para usar la app necesitas aceptar los términos y condiciones. Puedes volver a entrar cuando quieras.';

  @override
  String get terminosSalir => 'Salir';

  @override
  String get histTodasFechas => 'Todas las fechas';

  @override
  String get histSemana => 'Esta semana';

  @override
  String get histMes => 'Este mes';

  @override
  String get histMesAnterior => 'Mes anterior';

  @override
  String get histElegirFechas => 'Elegir fechas';

  @override
  String get histVacioRango => 'No hay órdenes creadas en esas fechas.';

  @override
  String get buscarOrdenes => 'Buscar: cliente, folio, teléfono, dirección…';

  @override
  String buscarSinResultados(String texto) {
    return 'No hay órdenes que coincidan con «$texto».';
  }

  @override
  String get avisoCanalFijo => 'Aviso fijo';

  @override
  String get avisoCanalOrdenes => 'Órdenes nuevas';

  @override
  String get avisoFijoTitulo => 'Atento a órdenes nuevas';

  @override
  String get avisoFijoTexto => 'Te aviso en cuanto llegue una orden.';

  @override
  String avisoFijoPendientes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n órdenes pendientes',
      one: '1 orden pendiente',
      zero: 'Sin órdenes pendientes',
    );
    return '$_temp0';
  }

  @override
  String avisoNueva(String folio) {
    return 'Nueva orden $folio';
  }

  @override
  String avisoAsignada(String folio) {
    return 'Te asignaron la orden $folio';
  }

  @override
  String get nuevaOrden => 'Nueva orden';

  @override
  String get editarOrden => 'Editar orden';

  @override
  String get foSubtituloNueva => 'Llena los datos: la oficina y los técnicos la ven al momento.';

  @override
  String get foSeccionCliente => 'Cliente';

  @override
  String get foCliente => 'Nombre del cliente';

  @override
  String get foDireccion => 'Dirección (calle, número, colonia, referencias)';

  @override
  String get foSeccionUbicacion => 'Ubicación';

  @override
  String get foCoordenadas => 'Coordenadas o enlace de Google Maps';

  @override
  String get foMiUbicacion => 'Usar mi ubicación';

  @override
  String get foElegirServicio => 'Elige el servicio';

  @override
  String get foCuando => '¿Cuándo?';

  @override
  String get foManana => 'Mañana';

  @override
  String get foOtroDia => 'Otro día';

  @override
  String get foSinHora => 'Sin hora';

  @override
  String get foElegirHora => 'Elegir hora';

  @override
  String get foCrear => 'Crear orden';

  @override
  String get foGuardar => 'Guardar cambios';

  @override
  String get errFoCliente => 'Escribe el nombre del cliente.';

  @override
  String errFoTelefono(String pais) {
    return 'Ese teléfono no es válido para $pais. Revisa el número o cambia el país.';
  }

  @override
  String get errFoCoordenadas =>
      'No entiendo esas coordenadas: escribe «latitud, longitud» o pega un enlace de Google Maps.';

  @override
  String get errFoLocalidad => 'Elige la localidad.';

  @override
  String get errFoServicio => 'Elige el servicio.';

  @override
  String get errFoDiaPasado => 'El día no puede ser anterior a hoy.';

  @override
  String get errFoHoraPasada => 'Esa hora ya pasó.';

  @override
  String get errFoCompletadaFutura => 'Una orden completada no puede pasar a un día futuro.';

  @override
  String get errUbicacionApagada => 'Activa la ubicación del teléfono.';

  @override
  String get errUbicacionPermiso => 'Sin permiso de ubicación: actívalo en los ajustes del teléfono.';

  @override
  String get errUbicacionOtro => 'No se pudo obtener la ubicación. Intenta de nuevo.';

  @override
  String ordenCreada(String folio) {
    return 'Listo: se creó la orden $folio.';
  }

  @override
  String get ordenGuardada => 'Cambios guardados.';

  @override
  String get menuEditar => 'Editar';

  @override
  String get menuEliminar => 'Eliminar';

  @override
  String eliminarPregunta(String folio) {
    return '¿Eliminar la orden $folio?';
  }

  @override
  String get eliminarTexto => 'Se va a la Papelera de la web: ahí se puede restaurar durante 30 días.';

  @override
  String get ordenEliminada => 'La orden se movió a la Papelera.';

  @override
  String get msgSoloConsulta => 'Tu rol es de consulta: puedes ver la orden, pero no cambiarla.';

  @override
  String get menuModems => 'Módems por recuperar';

  @override
  String get menuComisiones => 'Pago de comisiones';

  @override
  String get modemDescripcion =>
      'Clientes que cancelaron: un comisionista va por el módem y se marca cuando lo traiga.';

  @override
  String get modemSinAsignar => 'Sin asignar';

  @override
  String get modemAsignados => 'Asignados';

  @override
  String get modemInternet => 'Módem Internet';

  @override
  String get modemDoblePlay => 'Módem Doble Play';

  @override
  String get modemLoRecuperasTu => 'Lo recuperas tú';

  @override
  String modemLoRecupera(String nombre) {
    return 'Lo recupera $nombre';
  }

  @override
  String modemComision(String importe) {
    return 'Comisión $importe';
  }

  @override
  String get modemSoltar => 'Soltar';

  @override
  String get modemAsignar => 'Asignar';

  @override
  String get modemYaLoRecupere => 'Ya lo recuperé';

  @override
  String get modemQuienRecupera => '¿Qué comisionista recupera el módem?';

  @override
  String get modemSoltado => 'El módem quedó sin asignar.';

  @override
  String modemAsignadoA(String nombre) {
    return 'Módem asignado a $nombre.';
  }

  @override
  String get modemRecuperadoPregunta => '¿Ya tienes el módem?';

  @override
  String modemRecuperadoTexto(String cliente) {
    return 'Confirma que ya se recuperó el módem de $cliente. La oficina lo ve al momento.';
  }

  @override
  String modemGanas(String importe) {
    return 'Comisión: $importe.';
  }

  @override
  String get modemRecuperadoOk => '¡Listo! Módem recuperado: la comisión ya cuenta.';

  @override
  String get modemVacio => 'No hay módems por recuperar. ¡Todo al día!';

  @override
  String get modemVacioFiltro => 'No hay módems con este filtro.';

  @override
  String get comTotalPeriodo => 'Total del periodo';

  @override
  String get comPorEntregar => 'Por entregar';

  @override
  String get comEntregadas => 'Entregadas';

  @override
  String get comEntregada => 'Entregada';

  @override
  String get comSinImporte => 'Sin importe';

  @override
  String get comVacio => 'No hay comisiones en este periodo.';

  @override
  String get foOpcional => 'Opcional';

  @override
  String get foBuscarPais => 'Buscar país o lada';

  @override
  String get foLlegaSinTecnico => 'La orden llega sin técnico: el primero que la acepte se la queda.';

  @override
  String get foDatosNuevo => 'Datos del servicio nuevo';

  @override
  String get foPlan => 'Plan (módem que se instala)';

  @override
  String get foTelevisiones => 'Televisiones';

  @override
  String get foTvConCosto => 'TV con costo';

  @override
  String get foTvSinCosto => 'TV sin costo';

  @override
  String foTvPrecio(String precio, String total) {
    return 'Cada TV con costo se cobra $precio al completar. Total: $total.';
  }

  @override
  String get foQuienLoConsiguio => '¿Quién consiguió este servicio?';

  @override
  String get foNingunoSinComision => 'Ninguno (sin comisión)';

  @override
  String get foDatosBaja => 'Cancelación definitiva';

  @override
  String get foMotivo => 'Motivo';

  @override
  String get foOtros => 'Otros';

  @override
  String get foEscribeMotivo => 'Escribe el motivo';

  @override
  String get foModemRecuperar => 'Módem a recuperar';

  @override
  String get foDatosTemporal => 'Cancelación temporal';

  @override
  String get foMotivoOpcional => 'Motivo (opcional)';

  @override
  String get foRecogeModem => '¿Se recoge el módem?';

  @override
  String get foSi => 'Sí';

  @override
  String get foNo => 'No';

  @override
  String get foModemSeRecoge => 'Módem que se recoge';

  @override
  String get foFechaRegreso => 'Fecha supuesta de regreso';

  @override
  String get foElegirFecha => 'Elegir fecha';

  @override
  String get foFechaRegresoAyuda => 'La web avisa 3 días antes.';

  @override
  String get foSinCategoriasModem => 'No hay categorías de módem: agrégalas en la web (Sistema › Activos).';

  @override
  String get errFoPlan => 'Elige el plan (el módem que se instala).';

  @override
  String get errFoComision => 'Elige la comisión de quien consiguió el servicio.';

  @override
  String get errFoMotivo => 'Elige el motivo de la cancelación.';

  @override
  String get errFoMotivoOtro => 'Escribe el motivo de la cancelación.';

  @override
  String get errFoModem => 'Elige la categoría del módem.';

  @override
  String get errFoRecoge => 'Elige si se recoge el módem.';

  @override
  String get errFoRegreso => 'Elige la fecha supuesta de regreso.';

  @override
  String get errFoRegresoPasada => 'La fecha de regreso no puede ser anterior a hoy.';

  @override
  String get menuAdmin => 'Administración';

  @override
  String get menuDashboard => 'Dashboard';

  @override
  String get menuOrdenesTrabajo => 'Órdenes de trabajo';

  @override
  String get menuDelDia => 'Del día';

  @override
  String get menuHistorico => 'Histórico';

  @override
  String get menuPorAutorizar => 'Por autorizar';

  @override
  String get menuRecuperarModem => 'Recuperar módem';

  @override
  String get menuReportes => 'Reportes';

  @override
  String get menuHerramientas => 'Herramientas';

  @override
  String get dashRecibidas => 'Solicitudes';

  @override
  String get dashRecibidasSub => 'recibidas';

  @override
  String get dashCompletadas => 'Completadas';

  @override
  String dashCumplimiento(int p) {
    return '$p % de cumplimiento';
  }

  @override
  String get dashAbiertas => 'Abiertas';

  @override
  String dashAbiertasSub(int p, int e) {
    return '$p pendientes · $e en proceso';
  }

  @override
  String get dashTiempo => 'Tiempo de atención';

  @override
  String dashTiempoSub(int n) {
    return 'promedio de $n servicios';
  }

  @override
  String get dashNuevos => 'Nuevos servicios';

  @override
  String get dashNuevosSub => 'instalaciones';

  @override
  String get dashIngresos => 'Ingresos cobrados';

  @override
  String dashIngresosSub(int n) {
    return '$n cobros';
  }

  @override
  String get dashPorCobrar => 'Pendiente de cobro';

  @override
  String get dashPorCobrarSub => 'por cobrar';

  @override
  String get dashPospuestas => 'Pospuestas';

  @override
  String get dashCanceladas => 'Canceladas';

  @override
  String dashDeLasSolicitudes(int p) {
    return '$p % de las solicitudes';
  }

  @override
  String dashVsAnterior(int dias) {
    return 'Las flechas comparan con los $dias días anteriores.';
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
    return '$d días';
  }

  @override
  String get dashTendencia => 'Recibidas y completadas';

  @override
  String get dashEstados => 'Cómo van las solicitudes';

  @override
  String get dashPorLocalidad => 'Por localidad';

  @override
  String get dashPorTecnico => 'Por técnico';

  @override
  String dashLocalidadDetalle(int n, int d) {
    return '$n recibidas · $d completadas';
  }

  @override
  String dashTecnicoDetalle(int n, String tiempo) {
    return '$n completadas · $tiempo en promedio';
  }

  @override
  String get dashSinLocalidad => 'Sin localidad';

  @override
  String get dashSinDatos => 'No hay órdenes registradas en estas fechas.';

  @override
  String get dashNota =>
      'Cuenta las órdenes registradas en el periodo (como el Dashboard de la web). Por técnico: las que completó en el periodo.';

  @override
  String get dashToca => 'Toca una barra para ver sus números.';

  @override
  String dashTramo(String fecha, int r, int c) {
    return '$fecha: $r recibidas · $c completadas';
  }

  @override
  String get autVacio => 'No hay cobros esperando autorización.';

  @override
  String get autNota => 'Se autorizan desde la web, en Finanzas › Pendientes de pago.';

  @override
  String get dashNuevo => 'Nuevo';

  @override
  String dashPuntos(String n) {
    return '$n pts';
  }

  @override
  String avisoRegreso(String folio) {
    return 'La orden $folio regresó a Pendientes';
  }

  @override
  String get comNota =>
      'Las comisiones las cobran los comisionistas (Sistema › Comisionistas de la web). Se entregan desde la web.';

  @override
  String get comTipoInstalacion => 'Instalación';

  @override
  String get comTipoModem => 'Módem recuperado';

  @override
  String get comTipoIsp => 'Módem de Importados ISP';

  @override
  String get comSinNombre => 'Sin nombre';

  @override
  String comDeQuien(String nombre, String importe) {
    return '$nombre · $importe';
  }

  @override
  String get menuFinanzas => 'Finanzas';

  @override
  String get menuResumenFinanzas => 'Resumen';

  @override
  String get finResultado => 'Resultado del periodo';

  @override
  String get finEntradas => 'Entradas';

  @override
  String get finSalidas => 'Salidas';

  @override
  String get finIngresosServicios => 'Ingresos de servicios';

  @override
  String get finCobrosOrdenes => 'Cobros de órdenes';

  @override
  String finCobrosDetalle(int n) {
    return '$n órdenes cobradas en efectivo o transferencia';
  }

  @override
  String get finGastos => 'Gastos';

  @override
  String get finComisiones => 'Comisiones';

  @override
  String get finComisionesNoCuentan => 'No cuentan como gasto: en la web no está la partida de comisiones.';

  @override
  String get finSinFormaPago => 'Sin forma de pago';

  @override
  String get finOtrosGastos => 'Otros gastos';

  @override
  String get finNada => 'Nada en este periodo.';

  @override
  String get finNota =>
      'Es un resumen del Estado financiero de la web. Salarios y materiales (AFT, insumos) se ven en la web.';

  @override
  String get comTodos => 'Todos los comisionistas';

  @override
  String get matTitulo => 'Materiales';

  @override
  String get matExplica =>
      'Marca el módem que se instaló y los insumos que se usaron. Salen del inventario de la oficina.';

  @override
  String get matModem => 'Módem instalado';

  @override
  String get matModemNinguno => 'Ninguno';

  @override
  String get matModemNingunoSub => 'No se instaló módem (sin gasto)';

  @override
  String get matInsumos => 'Lleva insumos';

  @override
  String get matInsumoElige => 'Elige el insumo';

  @override
  String get matCantidad => 'Cantidad';

  @override
  String get matAgregar => 'Agregar insumo';

  @override
  String get matQuitar => 'Quitar';

  @override
  String get matSinPred => 'Este servicio no trae insumos: agrégalos si se usaron.';

  @override
  String get matGastoModem => 'Gasto del módem';

  @override
  String get matGastoInsumos => 'Gasto de insumos';

  @override
  String get matTotal => 'Total de materiales';

  @override
  String get matContinuar => 'Continuar';

  @override
  String get matSinLista =>
      'Sin señal no se pudo leer la lista de materiales: la orden se termina igual y la oficina los anota en la web.';

  @override
  String get menuInconclusas => 'Inconclusas';

  @override
  String get incMarcar => 'Marcar inconclusa';

  @override
  String get incTitulo => 'Orden inconclusa';

  @override
  String get incExplica => 'Se completó pero quedó algo pendiente. Elige cuándo se regresa y qué falta.';

  @override
  String get incFecha => 'Fecha de regreso';

  @override
  String get incMotivo => '¿Qué quedó pendiente?';

  @override
  String get incChipModem => 'Falta poner el módem correcto';

  @override
  String get incChipMaterial => 'Falta material';

  @override
  String get incChipTerminar => 'Falta terminar la instalación';

  @override
  String get incChipSenal => 'Regresar a revisar la señal';

  @override
  String get incGuardar => 'Guardar';

  @override
  String get incFaltaFecha => 'Elige la fecha de regreso.';

  @override
  String get incFaltaMotivo => 'Escribe qué quedó pendiente.';

  @override
  String get incGuardada => 'Orden marcada como inconclusa.';

  @override
  String get incResolver => 'Resolver';

  @override
  String get incResolverPregunta => '¿Ya se resolvió?';

  @override
  String incResolverTexto(String folio) {
    return 'La orden $folio deja de estar inconclusa.';
  }

  @override
  String get incResuelta => 'Inconclusa resuelta.';

  @override
  String incVuelve(String fecha) {
    return 'Vuelve el $fecha';
  }

  @override
  String get incSinFecha => 'Sin fecha de regreso';

  @override
  String get incAtrasadas => 'Atrasadas';

  @override
  String get incProximas => 'Próximas';

  @override
  String get incVacio => 'No hay órdenes inconclusas. ¡Todo terminado!';

  @override
  String get incCambiar => 'Cambiar';

  @override
  String get menuProspectos => 'Prospectos';

  @override
  String get prosNuevo => 'Nuevo prospecto';

  @override
  String get prosEditar => 'Editar prospecto';

  @override
  String get prosExplica => 'Posible cliente de un servicio nuevo. Ningún dato es obligatorio.';

  @override
  String get prosNombre => 'Nombre';

  @override
  String get prosSinLocalidad => 'Sin localidad';

  @override
  String get prosQuien => '¿Quién lo prospectó?';

  @override
  String get prosNadie => 'Nadie';

  @override
  String get prosDia => 'Fecha de instalación';

  @override
  String get prosSinDia => 'Sin fecha';

  @override
  String get prosComentario => 'Comentario';

  @override
  String get prosFoto => 'Foto';

  @override
  String get prosTomarFoto => 'Tomar foto';

  @override
  String get prosGaleria => 'Galería';

  @override
  String get prosQuitarFoto => 'Quitar foto';

  @override
  String get prosFotoError => 'No se pudo usar esa foto.';

  @override
  String get prosGuardar => 'Guardar';

  @override
  String get prosGuardado => 'Prospecto guardado.';

  @override
  String get prosCrearOrden => 'Crear orden';

  @override
  String prosAsignado(String folio) {
    return 'Listo: el prospecto quedó asignado a la orden $folio.';
  }

  @override
  String prosDescripcionOrden(String texto) {
    return 'Prospecto: $texto';
  }

  @override
  String get prosVacio => 'No hay prospectos en estas fechas.';

  @override
  String get prosPendientes => 'Pendientes';

  @override
  String get prosAsignados => 'Asignados';

  @override
  String get prosLuzHoy => 'Instalar hoy (o ya pasó)';

  @override
  String get prosLuzManana => 'Instalar mañana';

  @override
  String prosOrden(String folio) {
    return 'Orden $folio';
  }

  @override
  String get errProsDiaPasado => 'La fecha de instalación no puede ser anterior a hoy.';

  @override
  String get menuMapaDia => 'Mapa del día';

  @override
  String get mapaCalles => 'Calles';

  @override
  String get mapaSatelite => 'Satélite';

  @override
  String mapaSinUbicacion(int n) {
    return '$n sin ubicación';
  }

  @override
  String get mapaVacio => 'No hay órdenes para hoy con ubicación.';

  @override
  String get mapaCreditos => '© OpenStreetMap · Esri';

  @override
  String get mapaCentrar => 'Ver todas';

  @override
  String get fotTitulo => 'Fotos del trabajo';

  @override
  String get fotNinguna => 'Todavía no hay fotos. Toma fotos del trabajo: la oficina las ve en la web.';

  @override
  String fotMax(int n) {
    return 'Máximo $n fotos por orden.';
  }

  @override
  String get fotGuardadas => 'Fotos guardadas.';

  @override
  String get fotQuitarPregunta => '¿Quitar esta foto?';

  @override
  String get fotQuitarTexto => 'Se borra de la orden también en la web.';

  @override
  String get fotQuitar => 'Quitar';

  @override
  String get compTitulo => 'Comprobante de la transferencia';

  @override
  String get compExplica => 'Opcional, pero ayuda: con la foto la oficina completa la orden sin pedírtelo otra vez.';

  @override
  String get menuNuevosServicios => 'Nuevos Servicios';

  @override
  String get menuCancelados => 'Cancelados';

  @override
  String get menuFuturo => 'Futuro';

  @override
  String get menuNsPendientes => 'Pendientes';

  @override
  String get menuFacturaIsp => 'Eliminar factura del ISP';

  @override
  String get menuNsHistorico => 'Histórico';

  @override
  String get menuNcNuevos => 'Nuevos Servicios';

  @override
  String get menuTvCable => 'TV Cable';

  @override
  String get menuTvDoblePlay => 'TV Doble Play';

  @override
  String get menuDefinitivos => 'Definitivos';

  @override
  String get menuTemporales => 'Temporales';

  @override
  String get nsAtrasado1 => 'Atrasado 1 día';

  @override
  String nsAtrasadoN(int n) {
    return 'Atrasado $n días';
  }

  @override
  String get nsTocaHoy => 'Toca hoy';

  @override
  String get nsManana => 'Mañana';

  @override
  String nsEnDias(int n) {
    return 'En $n días';
  }

  @override
  String get listaVacia => 'No hay órdenes en estas fechas.';

  @override
  String get futVacio => 'No hay órdenes para los días que vienen.';

  @override
  String get npVacio => 'No hay servicios nuevos pendientes.';

  @override
  String get defModemRecuperado => 'Módem recuperado';

  @override
  String get tcActiva => 'Activa';

  @override
  String get tcReactivada => 'Reactivada';

  @override
  String tcRegresa(String fecha) {
    return 'Regresa el $fecha';
  }

  @override
  String tcRecogerModem(String modem) {
    return 'Recoger módem: $modem';
  }

  @override
  String get tcVencida => 'Ya toca regresar';

  @override
  String get tcPronto => 'Regresa pronto';

  @override
  String get tcVacio => 'No hay cancelaciones temporales en estas fechas.';

  @override
  String get ifaExplica =>
      'Servicios nuevos ya instalados que pagaron al instalarse: hay que eliminar en el ISP la factura de su primer pago para que no les suspendan el servicio.';

  @override
  String ifaFactura(String fecha) {
    return 'Factura del ISP: $fecha';
  }

  @override
  String ifaPago(String de, String a) {
    return 'Pago del $de al $a';
  }

  @override
  String get ifaMarcar => 'Ya la eliminé';

  @override
  String get ifaDeshacer => 'Deshacer';

  @override
  String get ifaHecha => 'Completado';

  @override
  String get ifaPendientes => 'Pendientes';

  @override
  String get ifaHechas => 'Completadas';

  @override
  String get ifaVacio => 'No hay facturas por eliminar en estas fechas.';

  @override
  String get ifaSinFechas => 'No hay Fechas de pago: se configuran en la web, en Sistema › Fechas de pago.';

  @override
  String get ifaGuardada => 'Marcada como eliminada en el ISP.';

  @override
  String get menuSistema => 'Sistema';

  @override
  String get menuUsuariosApp => 'Usuarios app';

  @override
  String get menuRoles => 'Roles';

  @override
  String get menuOcupacion => 'Ocupación';

  @override
  String get menuLocalidades => 'Localidades';

  @override
  String get menuFechasPago => 'Fechas de pago';

  @override
  String get menuZonas => 'Zonas';

  @override
  String get menuServicios => 'Servicios';

  @override
  String get menuComisionesCat => 'Comisiones';

  @override
  String get menuComisionistas => 'Comisionistas';

  @override
  String get menuActivos => 'Activos';

  @override
  String get menuInsumos => 'Insumos';

  @override
  String get menuMotivosCancelacion => 'Motivos de Cancelación';

  @override
  String get menuCobroServicios => 'Cobro de servicios';

  @override
  String get menuFormasPago => 'Formas de pago';

  @override
  String get menuPartidaGastos => 'Partida de Gastos';

  @override
  String get sisSoloVer => 'Aquí solo se ve. Para agregar o cambiar, usa la web (Sistema).';

  @override
  String get sisVacio => 'No hay nada registrado.';

  @override
  String get sisBuscar => 'Buscar';

  @override
  String sisUsuarios(int n) {
    return '$n usuarios';
  }

  @override
  String sisPago(String de, String a) {
    return 'Pago del $de al $a';
  }

  @override
  String sisFacturaDia(String d) {
    return 'factura el día $d';
  }

  @override
  String sisInstalaciones(String de, String a) {
    return 'instalaciones del $de al $a';
  }

  @override
  String get sisLlevaComision => 'Lleva comisión';

  @override
  String get sisLlevaCobro => 'Lleva cobro';

  @override
  String get sisLlevaMateriales => 'Lleva materiales';

  @override
  String get sisPideMotivo => 'Pide escribir el motivo';

  @override
  String get sisAutomatica => 'Se calcula sola';

  @override
  String get sisInactiva => 'Inactiva';

  @override
  String get sisSinAcceso => 'Sin acceso a la app';

  @override
  String get sisAgregar => 'Agregar';

  @override
  String get sisNuevo => 'Nuevo';

  @override
  String get sisGuardar => 'Guardar';

  @override
  String get sisBorrar => 'Borrar';

  @override
  String get sisGuardado => 'Guardado.';

  @override
  String get sisBorrado => 'Borrado: queda en la Papelera de la web.';

  @override
  String sisBorrarPregunta(String nombre) {
    return '¿Borrar «$nombre»?';
  }

  @override
  String get sisBorrarTexto => 'Se va a la Papelera de la web; ahí se puede restaurar.';

  @override
  String get sisBorrarLocalidad => 'También se borran sus zonas. Las órdenes ya hechas no cambian.';

  @override
  String get sisNombreFijo => 'El nombre se cambia en la web: allá también se cambia en todas las órdenes que lo usan.';

  @override
  String get sisElegir => 'Elegir';

  @override
  String get sisCampoName => 'Nombre';

  @override
  String get sisCampoServiceName => 'Nombre del cobro';

  @override
  String get sisCampoDescription => 'Descripción';

  @override
  String get sisCampoAmount => 'Importe';

  @override
  String get sisCampoPrice => 'Precio';

  @override
  String get sisCampoUnit => 'Unidad (pza, m…)';

  @override
  String get sisCampoBrand => 'Marca';

  @override
  String get sisCampoModel => 'Modelo';

  @override
  String get sisCampoCategory => 'Categoría';

  @override
  String get sisCampoZoneIds => 'Localidades (sin ninguna = todas)';

  @override
  String get sisCampoLocality => 'Localidad';

  @override
  String get sisCampoCommissionIds => 'Comisiones que cobra';

  @override
  String get sisCampoIsp => 'Va con el ISP';

  @override
  String get sisCampoPayFrom => 'Pago desde el día';

  @override
  String get sisCampoPayTo => 'Pago hasta el día';

  @override
  String get sisCampoInvoiceDay => 'Día de la factura del ISP';

  @override
  String get sisCampoInstallFrom => 'Instalaciones desde el día';

  @override
  String get sisCampoInstallTo => 'Instalaciones hasta el día';

  @override
  String get errSisNombre => 'Escribe el nombre.';

  @override
  String get errSisYaExiste => 'Ya hay uno con ese nombre.';

  @override
  String get errSisDia => 'Los días van del 1 al 31.';

  @override
  String get errSisImporte => 'Escribe un importe válido.';

  @override
  String get errSisLocalidad => 'Elige la localidad.';

  @override
  String get errSisCategoria => 'Elige la categoría.';

  @override
  String get errSisFechaChoca => 'Esos días de instalación ya entran en otra fecha de pago de la misma localidad.';

  @override
  String get sisCampoPermission => 'Permiso';

  @override
  String get errSisPermiso => 'Elige el permiso.';

  @override
  String get permisoAdmin => 'Administrador del sistema (control total)';

  @override
  String get permisoConsultor => 'Consultor (solo ve, no cambia nada)';

  @override
  String get permisoTecnico => 'Técnico (crea y procesa, no borra)';

  @override
  String get usuCorreo => 'Correo';

  @override
  String get usuRol => 'Rol';

  @override
  String get usuOcupacion => 'Ocupación';

  @override
  String get usuSinOcupacion => 'Sin ocupación';

  @override
  String get usuLocalidadesAyuda => 'Si no marcas ninguna, ve todas.';

  @override
  String get usuAsalariado => 'Tiene sueldo';

  @override
  String get usuSueldo => 'Sueldo semanal';

  @override
  String get usuComisionista => 'Cobra comisiones';

  @override
  String get usuAcceso => 'Entra a la app';

  @override
  String get usuUsuario => 'Usuario de la app';

  @override
  String get usuUsuarioAyuda => 'De 3 a 30 letras sin acentos, números, punto o guion. Sin espacios.';

  @override
  String get usuContrasena => 'Contraseña';

  @override
  String get usuContrasenaCambiar => 'Déjala vacía para no cambiarla.';

  @override
  String get usuContrasenaNueva => 'Al menos 8 caracteres.';

  @override
  String get usuMostrar => 'Mostrar contraseña';

  @override
  String get usuOcultar => 'Ocultar contraseña';

  @override
  String get usuBorrarTexto =>
      'Se le quita la entrada a la app y su ficha va a la Papelera de la web. Desde ahí se recupera la ficha; para volver a entrar a la app hay que ponerle una contraseña nueva.';

  @override
  String get errUsuTelefono => 'Ese teléfono no es válido para el país elegido. Revisa el número o cambia el país.';

  @override
  String get errUsuCorreo => 'El correo no es válido (ejemplo: nombre@correo.com).';

  @override
  String get errUsuCorreoRepetido => 'Ya hay otro usuario con ese correo.';

  @override
  String get errUsuRol => 'Elige el rol.';

  @override
  String get errUsuSueldo => 'Escribe el sueldo semanal.';

  @override
  String get errUsuUsuario => 'Escribe el usuario con el que entrará a la app.';

  @override
  String get errUsuUsuarioFormato =>
      'El usuario debe tener de 3 a 30 letras sin acentos, números, punto o guion, sin espacios.';

  @override
  String get errUsuUsuarioOcupado => 'Ese usuario ya lo tiene otra persona.';

  @override
  String get errUsuContrasena => 'Escribe la contraseña para la app.';

  @override
  String get errUsuContrasenaCorta => 'La contraseña debe tener al menos 8 caracteres.';

  @override
  String errUsuCuenta(String detalle) {
    return 'La ficha se guardó, pero no se pudo dar o cambiar su acceso a la app ($detalle). Ábrela y vuelve a guardar, o hazlo en la web.';
  }
}
