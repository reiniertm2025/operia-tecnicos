import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Fondo animado del inicio de sesión «Conectando tu mundo», igual que el de la web
/// (src/features/login-art/cable-art.ts de Operia): foto de fibra óptica y, encima, pulsos de luz por los hilos,
/// la avenida de luz hacia la ciudad y la señal de la torre. La foto no se mueve. Se usa la versión «ligera» de la web
/// (la de teléfonos). Con «quitar animaciones» del teléfono queda la foto fija.
class FondoLogin extends StatefulWidget {
  const FondoLogin({super.key});

  @override
  State<FondoLogin> createState() => _FondoLoginState();
}

/// Igual que el CSS de la web en teléfonos: `background-position: 86% 62%; background-size: cover`.
const _alineacion = Alignment(0.72, 0.24);

class _FondoLoginState extends State<FondoLogin> with SingleTickerProviderStateMixin {
  final _escena = _Escena();
  late final Ticker _ticker = createTicker(_cuadro);
  Duration _anterior = Duration.zero;

  void _cuadro(Duration ahora) {
    final dt = min(0.05, (ahora - _anterior).inMicroseconds / 1e6);
    _anterior = ahora;
    _escena.avanzar(ahora.inMicroseconds / 1e6, dt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieto = MediaQuery.of(context).disableAnimations;
    if (quieto && _ticker.isActive) _ticker.stop();
    if (!quieto && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _escena.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF050E24)),
        Image.asset('assets/login/fibra-noche.webp', fit: BoxFit.cover, alignment: _alineacion),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.4, 1],
              colors: [Color(0xB3050E24), Color(0x40050E24), Color(0xB3050E24)],
            ),
          ),
        ),
        RepaintBoundary(child: CustomPaint(painter: _Pintor(_escena))),
      ],
    );
  }
}

// ---------- Datos de la foto (1200 × 876), copiados de la web ----------

const _anchoFoto = 1200.0;
const _altoFoto = 876.0;

/// Punta de cada hilo de fibra; salen de la boca del cable (x ≈ 458).
const _puntas = <Offset>[
  Offset(700, 535),
  Offset(758, 532),
  Offset(788, 547),
  Offset(848, 537),
  Offset(905, 572),
  Offset(570, 590),
  Offset(760, 603),
  Offset(850, 593),
  Offset(830, 617),
  Offset(890, 632),
  Offset(750, 645),
  Offset(910, 668),
  Offset(770, 690),
  Offset(920, 712),
  Offset(875, 745),
  Offset(845, 793),
  Offset(700, 825),
  Offset(610, 826),
  Offset(500, 822),
  Offset(720, 766),
  Offset(805, 816),
  Offset(590, 712),
  Offset(665, 668),
  Offset(640, 628),
];

/// Hilos que en la foto son naranjas.
const _ambar = {16, 19};

/// Carriles de la avenida de luz, del frente (abajo) hacia la ciudad.
const _carriles = <(List<Offset>, bool ambar, bool alReves)>[
  (
    [
      Offset(1150, 876),
      Offset(1132, 780),
      Offset(1098, 680),
      Offset(1048, 585),
      Offset(988, 518),
      Offset(905, 480),
      Offset(822, 460),
      Offset(748, 440),
      Offset(708, 410),
      Offset(728, 374),
      Offset(792, 344),
    ],
    false,
    false,
  ),
  (
    [
      Offset(1200, 790),
      Offset(1188, 700),
      Offset(1160, 605),
      Offset(1112, 532),
      Offset(1042, 482),
      Offset(960, 456),
      Offset(880, 442),
      Offset(800, 424),
      Offset(746, 402),
      Offset(762, 366),
      Offset(805, 336),
    ],
    false,
    false,
  ),
  (
    [
      Offset(1095, 876),
      Offset(1085, 790),
      Offset(1055, 700),
      Offset(1010, 620),
      Offset(960, 560),
      Offset(905, 520),
      Offset(840, 500),
    ],
    false,
    false,
  ),
  (
    [
      Offset(1138, 560),
      Offset(1126, 640),
      Offset(1092, 700),
      Offset(1044, 745),
      Offset(1000, 775),
      Offset(940, 806),
      Offset(870, 842),
    ],
    true,
    true,
  ),
];

const _balizas = [(Offset(1054, 53), 1.0, 0.0), (Offset(1072, 226), 0.8, 1.15)];
const _paneles = [
  (Offset(1012, 313), 60.0),
  (Offset(1099, 316), 58.0),
  (Offset(1046, 330), 64.0),
  (Offset(1093, 447), 42.0),
];
const _antena = Offset(1048, 138);
const _baseTorre = Offset(1050, 468);
const _boca = Offset(462, 715);

// ---------- Caminos ----------

class _Camino {
  _Camino(this.puntos) : largos = List.filled(puntos.length, 0) {
    for (var i = 1; i < puntos.length; i++) {
      total += (puntos[i] - puntos[i - 1]).distance;
      largos[i] = total;
    }
  }

  final List<Offset> puntos;
  final List<double> largos;
  double total = 0;

  /// Punto a una distancia `d` del inicio.
  Offset en(double d) {
    var lo = 0, hi = largos.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) >> 1;
      if (largos[mid] < d) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final tramo = largos[hi] - largos[lo];
    final t = ((d - largos[lo]) / (tramo == 0 ? 1 : tramo)).clamp(0.0, 1.0);
    return Offset.lerp(puntos[lo], puntos[hi], t)!;
  }
}

List<Offset> _bezier(Offset a, Offset b, Offset c, Offset d, int n) => [
  for (var i = 0; i <= n; i++)
    () {
      final t = i / n, u = 1 - t;
      return a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t);
    }(),
];

/// Curva suave que pasa por todos los puntos (Catmull-Rom).
List<Offset> _suave(List<Offset> p, [int porTramo = 10]) {
  final out = <Offset>[];
  for (var i = 0; i < p.length - 1; i++) {
    final p0 = p[max(0, i - 1)], p1 = p[i], p2 = p[i + 1], p3 = p[min(p.length - 1, i + 2)];
    for (var k = 0; k < porTramo; k++) {
      final t = k / porTramo, t2 = t * t, t3 = t2 * t;
      double f(double a, double b, double c, double d) =>
          0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3);
      out.add(Offset(f(p0.dx, p1.dx, p2.dx, p3.dx), f(p0.dy, p1.dy, p2.dy, p3.dy)));
    }
  }
  out.add(p.last);
  return out;
}

// ---------- Escena (lo que se mueve) ----------

class _Pulso {
  _Pulso(this.d, this.v, this.largo, this.ambar, this.cian, this.cual);
  double d;
  final double v, largo;
  final bool ambar, cian;
  final int cual;
}

class _Hilo {
  _Hilo(this.camino, this.ambar);
  final _Camino camino;
  final bool ambar;
  double destello = 0;
}

class _Escena extends ChangeNotifier {
  _Escena() {
    for (var i = 0; i < _puntas.length; i++) {
      final punta = _puntas[i];
      final oy = (645 + (punta.dy - 530) / 300 * 150).clamp(640.0, 800.0);
      final o = Offset(458, oy);
      final pts = _bezier(
        o,
        Offset(545, oy + (punta.dy - oy) * 0.1),
        Offset(punta.dx - (punta.dx - 458) * 0.35, punta.dy + (oy - punta.dy) * 0.08),
        punta,
        36,
      );
      hilos.add(_Hilo(_Camino(pts), _ambar.contains(i)));
    }
    for (final (pts, ambar, alReves) in _carriles) {
      final s = _suave(pts);
      carriles.add((_Camino(alReves ? s.reversed.toList() : s), ambar));
    }
  }

  final _azar = Random();
  final hilos = <_Hilo>[];
  final carriles = <(_Camino, bool)>[];
  final bajadaTorre = _Camino(
    _suave([
      _antena,
      const Offset(1049, 300),
      _baseTorre,
      const Offset(1030, 520),
      const Offset(988, 518),
      const Offset(905, 480),
      const Offset(822, 460),
    ], 8),
  );

  final pulsosFibra = <_Pulso>[];
  final pulsosCarril = <_Pulso>[];
  final pulsosTorre = <double>[];
  final anillos = <double>[];
  double t = 0;
  double _sigFibra = 0, _sigCarril = 0, _sigAnillo = 1.2, _sigTorre = 4;

  void avanzar(double ahora, double dt) {
    t = ahora;
    // avenida de luz
    _sigCarril -= dt;
    if (_sigCarril <= 0) {
      final i = _azar.nextInt(carriles.length);
      final ambar = carriles[i].$2;
      pulsosCarril.add(
        _Pulso(
          0,
          (ambar ? 170 : 220) + _azar.nextDouble() * 160,
          90 + _azar.nextDouble() * 110,
          ambar,
          _azar.nextDouble() < 0.4,
          i,
        ),
      );
      _sigCarril = 0.55 + _azar.nextDouble() * 0.35;
    }
    pulsosCarril.removeWhere((p) {
      final (camino, ambar) = carriles[p.cual];
      final lejos = p.d / camino.total;
      p.d += p.v * dt * (ambar ? 1 : 1.15 - lejos * 0.75);
      return p.d - p.largo > camino.total;
    });
    // fibras
    _sigFibra -= dt;
    if (_sigFibra <= 0) {
      final i = _azar.nextInt(hilos.length);
      pulsosFibra.add(
        _Pulso(
          0,
          260 + _azar.nextDouble() * 260,
          60 + _azar.nextDouble() * 70,
          hilos[i].ambar || _azar.nextDouble() < 0.08,
          _azar.nextDouble() < 0.45,
          i,
        ),
      );
      _sigFibra = 0.22 + _azar.nextDouble() * 0.12;
    }
    pulsosFibra.removeWhere((p) {
      final h = hilos[p.cual];
      p.d += p.v * dt;
      if (p.d < h.camino.total) return false;
      h.destello = min(1.4, h.destello + 0.9);
      return true;
    });
    for (final h in hilos) {
      h.destello = max(0, h.destello - dt * 2.2);
    }
    // torre
    _sigAnillo -= dt;
    if (_sigAnillo <= 0) {
      anillos.add(0);
      _sigAnillo = 1.5;
    }
    for (var i = anillos.length - 1; i >= 0; i--) {
      anillos[i] += dt / 4.2;
      if (anillos[i] >= 1) anillos.removeAt(i);
    }
    _sigTorre -= dt;
    if (_sigTorre <= 0) {
      pulsosTorre.add(0);
      _sigTorre = 5 + _azar.nextDouble() * 4;
    }
    for (var i = pulsosTorre.length - 1; i >= 0; i--) {
      pulsosTorre[i] += 230 * dt;
      if (pulsosTorre[i] - 120 > bajadaTorre.total) pulsosTorre.removeAt(i);
    }
    notifyListeners();
  }
}

// ---------- Dibujo ----------

class _Pintor extends CustomPainter {
  _Pintor(this.escena) : super(repaint: escena);

  final _Escena escena;

  static final _azul = _destello(const Color(0xFF388CFF), const Color(0xFFDCF0FF));
  static final _cian = _destello(const Color(0xFF22D3EE), const Color(0xFFE6FFFF));
  static final _ambarD = _destello(const Color(0xFFFFA63C), const Color(0xFFFFF5DC));
  static final _rojo = _destello(const Color(0xFFFF2828), const Color(0xFFFFDCDC));
  static final _suaveD = _destello(const Color(0xFF78B4FF), const Color(0xFFC8E6FF));

  /// Destello radial pre-dibujado (más barato que crear un degradado en cada cuadro).
  static ui.Image _destello(Color color, Color centro) {
    final grabadora = ui.PictureRecorder();
    final lienzo = Canvas(grabadora);
    final pintura = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(32, 32),
        32,
        [centro, color.withValues(alpha: 0.95), color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        [0, 0.12, 0.35, 1],
      );
    lienzo.drawRect(const Rect.fromLTWH(0, 0, 64, 64), pintura);
    return grabadora.endRecording().toImageSync(64, 64);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // foto → pantalla, igual que BoxFit.cover con la alineación del fondo
    final sc = max(size.width / _anchoFoto, size.height / _altoFoto);
    final ox = (size.width - _anchoFoto * sc) * (_alineacion.x + 1) / 2;
    final oy = (size.height - _altoFoto * sc) * (_alineacion.y + 1) / 2;
    Offset p(Offset f) => Offset(ox + f.dx * sc, oy + f.dy * sc);
    final z = max(0.6, sc);
    final e = escena;
    final img = Paint()..blendMode = BlendMode.plus;
    final linea = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void brillo(ui.Image imagen, Offset f, double r, double a) {
      if (a <= 0.003) return;
      img.color = Color.fromRGBO(0, 0, 0, min(1, a));
      canvas.drawImageRect(imagen, const Rect.fromLTWH(0, 0, 64, 64), Rect.fromCircle(center: p(f), radius: r), img);
    }

    /// Estela: trozo del camino entre d-largo y d, más brillante hacia la cabeza.
    void estela(_Camino c, double d, double largo, Color color, double ancho, double alfa) {
      const n = 8;
      for (var k = 0; k < n; k++) {
        final a = c.en(max(0, d - largo + largo * k / n));
        final b = c.en(max(0, d - largo + largo * (k + 1) / n));
        linea
          ..color = color.withValues(alpha: (alfa * pow((k + 1) / n, 1.6)).clamp(0.0, 1.0))
          ..strokeWidth = ancho * (0.5 + 0.5 * (k + 1) / n);
        canvas.drawLine(p(a), p(b), linea);
      }
    }

    // brillo que respira en la boca del cable
    brillo(_suaveD, _boca, 120 * z, 0.16 + 0.07 * sin(e.t * 1.3));

    // avenida de luz
    for (final pu in e.pulsosCarril) {
      final (camino, _) = e.carriles[pu.cual];
      final lejos = pu.d / camino.total;
      final fade = min(1.0, pu.d / 60) * min(1.0, (camino.total - pu.d + pu.largo) / 120);
      final color = pu.ambar ? const Color(0xFFFFAA46) : (pu.cian ? const Color(0xFF5AE1FF) : const Color(0xFF5096FF));
      estela(
        camino,
        min(pu.d, camino.total),
        pu.largo * (1.1 - lejos * 0.6),
        color,
        (3.2 - lejos * 2) * z,
        0.55 * fade,
      );
      if (pu.d < camino.total) {
        brillo(pu.ambar ? _ambarD : (pu.cian ? _cian : _azul), camino.en(pu.d), (16 - lejos * 9) * z, 0.75 * fade);
      }
    }

    // fibras
    for (final pu in e.pulsosFibra) {
      final h = e.hilos[pu.cual];
      final color = pu.ambar ? const Color(0xFFFFAA46) : (pu.cian ? const Color(0xFF78EBFF) : const Color(0xFF6EAAFF));
      estela(h.camino, pu.d, pu.largo, color, 1.6 * z, 0.7);
      brillo(pu.ambar ? _ambarD : (pu.cian ? _cian : _azul), h.camino.en(pu.d), 9 * z, 0.9);
    }
    for (final h in e.hilos) {
      if (h.destello > 0.01) brillo(h.ambar ? _ambarD : _cian, h.camino.en(h.camino.total), 20 * z, h.destello * 0.55);
    }

    // torre: balizas rojas, paneles azules que respiran, ondas de señal
    for (final (pos, tam, fase) in _balizas) {
      final ph = ((e.t + fase) % 2.6) / 2.6;
      final encendida = ph < 0.42 ? pow(sin(ph / 0.42 * pi), 2).toDouble() : 0.0;
      brillo(_rojo, pos, 26 * tam * z, 0.12 + 0.85 * encendida);
    }
    for (var i = 0; i < _paneles.length; i++) {
      final (pos, alto) = _paneles[i];
      img.color = Color.fromRGBO(0, 0, 0, 0.12 + 0.12 * (0.5 + 0.5 * sin(e.t * 0.9 + i * 1.7)));
      final arriba = p(Offset(pos.dx, pos.dy - alto / 2));
      canvas.drawImageRect(
        _cian,
        const Rect.fromLTWH(0, 0, 64, 64),
        Rect.fromLTWH(arriba.dx - 9 * z, arriba.dy - 6 * z, 18 * z, (alto + 12) * sc),
        img,
      );
    }
    for (final a in e.anillos) {
      final crece = 1 - pow(1 - a, 1.6);
      final fade = pow(1 - a, 1.3) * min(1.0, a * 8);
      final ovalo = Rect.fromCenter(
        center: p(_antena),
        width: 2 * (16 + crece * 260) * sc,
        height: 2 * (10 + crece * 150) * sc,
      );
      linea
        ..color = Color.fromRGBO(110, 200, 255, 0.16 * fade)
        ..strokeWidth = 7 * z;
      canvas.drawOval(ovalo, linea);
      linea
        ..color = Color.fromRGBO(110, 200, 255, 0.5 * fade)
        ..strokeWidth = 1.6;
      canvas.drawOval(ovalo, linea);
    }
    for (final d in e.pulsosTorre) {
      final c = e.bajadaTorre;
      estela(c, min(d, c.total), 120, const Color(0xFF78C8FF), 2.4 * z, 0.5);
      if (d < c.total) brillo(_cian, c.en(d), 14 * z, 0.7);
    }
  }

  @override
  bool shouldRepaint(_Pintor old) => old.escena != escena;
}
