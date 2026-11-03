import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../l10n/textos.dart';
import '../logica/avisos.dart';
import '../logica/orden.dart';
import 'ordenes.dart';
import 'sesion.dart';

/// Aviso fijo («aviso fijo siempre activo», decisión del dueño): un servicio en primer plano con su notificación fija que
/// escucha las órdenes abiertas que le tocan y avisa (con sonido) cada orden nueva o asignada, aunque la app esté cerrada.
/// Sin plan Blaze de Firebase no hay mensajes desde el servidor: por eso el teléfono escucha él mismo.
/// Gasta pocas lecturas: una al encender y luego solo los cambios de esas órdenes.
class Avisos {
  static const _canalOrdenes = 'ordenes_nuevas';

  /// Una vez, al abrir la app.
  static void preparar(Textos t) {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'aviso_fijo',
        channelName: t.avisoCanalFijo,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Enciende (o reinicia con los datos de quien entró) el aviso fijo. Pide permiso de notificaciones y de batería.
  static Future<void> encender(Tecnico t, String idioma, Textos textos) async {
    if (await FlutterForegroundTask.checkNotificationPermission() != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    await FlutterForegroundTask.saveData(key: 'quien', value: jsonEncode(_quienAMapa(t)));
    await FlutterForegroundTask.saveData(key: 'idioma', value: idioma);
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.remoteMessaging],
        notificationTitle: textos.avisoFijoTitulo,
        notificationText: textos.avisoFijoTexto,
        callback: iniciarVigia,
      );
    }
  }

  /// Al cerrar sesión: se apaga y se olvida quién era.
  static Future<void> apagar() async {
    await FlutterForegroundTask.removeData(key: 'quien');
    await FlutterForegroundTask.stopService();
  }

  static Map<String, Object> _quienAMapa(Tecnico t) => {
    'userId': t.userId,
    'nombre': t.nombre,
    'zonas': t.zonas,
    'esAdmin': t.esAdmin,
  };

  static Tecnico? _quienDeTexto(String? texto) {
    if (texto == null || texto.isEmpty) return null;
    final m = jsonDecode(texto) as Map<String, dynamic>;
    return Tecnico(
      userId: '${m['userId']}',
      nombre: '${m['nombre'] ?? ''}',
      zonas: [for (final z in (m['zonas'] as List? ?? const [])) '$z'],
      esAdmin: m['esAdmin'] == true,
    );
  }
}

/// Arranque del servicio (corre aparte de la pantalla, también al encender el teléfono).
@pragma('vm:entry-point')
void iniciarVigia() => FlutterForegroundTask.setTaskHandler(_VigiaDeOrdenes());

class _VigiaDeOrdenes extends TaskHandler {
  final _notificaciones = FlutterLocalNotificationsPlugin();
  StreamSubscription<List<Orden>>? _escucha;
  late Textos _t;
  var _siguienteId = 1000;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    WidgetsFlutterBinding.ensureInitialized();
    _t = lookupTextos(Locale(await FlutterForegroundTask.getData<String>(key: 'idioma') ?? 'es'));
    final quien = Avisos._quienDeTexto(await FlutterForegroundTask.getData<String>(key: 'quien'));
    if (quien == null) {
      // nadie con sesión (por ejemplo, al encender el teléfono después de cerrar sesión)
      await FlutterForegroundTask.stopService();
      return;
    }
    if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: firebaseOptions);
    await _notificaciones.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher_monochrome')),
    );
    await _notificaciones
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(Avisos._canalOrdenes, _t.avisoCanalOrdenes, importance: Importance.high),
        );
    final servicio = ServicioOrdenes();
    var zonas = const <String, String>{};
    try {
      zonas = await servicio.zonas();
    } catch (_) {
      // sin nombres de localidad el aviso sigue sirviendo
    }
    final vigia = Vigia(quien);
    _escucha = servicio
        .abiertas(quien)
        .listen(
          (lista) {
            for (final a in vigia.revisar(lista)) {
              _avisar(a, zonas);
            }
            FlutterForegroundTask.updateService(
              notificationTitle: _t.avisoFijoTitulo,
              notificationText: _t.avisoFijoPendientes(vigia.pendientes),
            );
          },
          onError: (Object _) {
            // sin internet o sin permiso: Firestore reintenta solo
          },
        );
  }

  void _avisar(Aviso a, Map<String, String> zonas) {
    final o = a.orden;
    final titulo = switch (a.tipo) {
      TipoAviso.asignada => _t.avisoAsignada(o.folio),
      TipoAviso.regreso => _t.avisoRegreso(o.folio),
      TipoAviso.nueva => _t.avisoNueva(o.folio),
    };
    final texto = [o.cliente, o.servicio, zonas[o.zonaId] ?? o.zonaId].where((x) => x.isNotEmpty).join(' · ');
    _notificaciones.show(
      id: _siguienteId++,
      title: titulo,
      body: texto,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          Avisos._canalOrdenes,
          _t.avisoCanalOrdenes,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          styleInformation: BigTextStyleInformation(texto),
        ),
      ),
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _escucha?.cancel();
  }

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();
}
