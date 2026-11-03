import 'package:geolocator/geolocator.dart';

enum FalloUbicacion { apagada, sinPermiso, otro }

class ErrorDeUbicacion implements Exception {
  const ErrorDeUbicacion(this.fallo);
  final FalloUbicacion fallo;
}

/// Dónde está el teléfono ahora (para «Usar mi ubicación» al crear una orden). Pide permiso solo en ese momento.
Future<({double lat, double lng})> miUbicacion() async {
  if (!await Geolocator.isLocationServiceEnabled()) throw const ErrorDeUbicacion(FalloUbicacion.apagada);
  var permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
  if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
    throw const ErrorDeUbicacion(FalloUbicacion.sinPermiso);
  }
  try {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
    );
    // 6 decimales ≈ 10 cm: suficiente y legible
    double corto(double x) => double.parse(x.toStringAsFixed(6));
    return (lat: corto(p.latitude), lng: corto(p.longitude));
  } catch (_) {
    throw const ErrorDeUbicacion(FalloUbicacion.otro);
  }
}
