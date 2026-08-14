import 'package:flutter/material.dart';

class SunsetBeach extends StatefulWidget {
  final bool active;
  const SunsetBeach({super.key, required this.active});

  @override
  State<SunsetBeach> createState() => _SunsetBeachState();
}

class _SunsetBeachState extends State<SunsetBeach>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: _SunsetPainter(_controller),
        size: Size.infinite,
      ),
    );
  }
}

class _SunsetPainter extends CustomPainter {
  final Animation<double> animation;
  _SunsetPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky Gradient
    final skyRect = Rect.fromLTWH(0, 0, w, h * 0.6);
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2E0954), // Deep Purple
        Color(0xFF8D2564), // Magenta
        Color(0xFFD45D55), // Salmon
        Color(0xFFFFB347), // Orange
      ],
    ).createShader(skyRect);
    canvas.drawRect(skyRect, Paint()..shader = skyGradient);

    // Sun
    final sunCenter = Offset(w / 2, h * 0.45);
    final sunRadius = w * 0.25;

    // Sun Glow
    canvas.drawCircle(
      sunCenter,
      sunRadius * 1.2,
      Paint()
        ..color = Colors.orangeAccent.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40),
    );

    // Sun Body Gradient
    final sunGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFE57F), Color(0xFFFF5252)],
    ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));

    canvas.drawCircle(sunCenter, sunRadius, Paint()..shader = sunGradient);

    // Sun Stripes (Retro Style)
    final stripePaint = Paint()
      ..color = Color(0xFF8D2564).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      double y = sunCenter.dy + (sunRadius * 0.3) + (i * sunRadius * 0.15);
      double height = sunRadius * 0.05 + (i * 2);
      if (y < sunCenter.dy + sunRadius) {
        canvas.drawRect(
          Rect.fromLTWH(sunCenter.dx - sunRadius, y, sunRadius * 2, height),
          stripePaint,
        );
      }
    }

    // Ocean
    final oceanRect = Rect.fromLTWH(0, h * 0.6, w, h * 0.4);
    final oceanGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2E0954), Color(0xFF1A0538)],
    ).createShader(oceanRect);
    canvas.drawRect(oceanRect, Paint()..shader = oceanGradient);

    // Grid / Waves on Water
    final gridPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    final perspectiveOrigin = Offset(w / 2, h * 0.6); // Horizon center

    // Vertical Perspective Lines
    for (double i = -1; i <= 2; i += 0.2) {
      double xBase = w * i;
      canvas.drawLine(
        perspectiveOrigin,
        Offset(xBase - (w / 2 - perspectiveOrigin.dx) * 4, h),
        gridPaint,
      );
    }

    // Horizontal Moving Lines
    double time = animation.value;
    for (int i = 0; i < 20; i++) {
      double p = (i + time) % 20 / 20.0;
      // Exponential spacing for perspective
      double y = h * 0.6 + (h * 0.4) * (p * p);
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        gridPaint..color = Colors.cyanAccent.withValues(alpha: 0.1 + (p * 0.4)),
      );
    }

    // Reflection of Sun
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.orange.withValues(alpha: 0.6), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4));
    Path path = Path();
    path.moveTo(w / 2 - sunRadius * 0.8, h * 0.6);
    path.lineTo(w / 2 + sunRadius * 0.8, h * 0.6);
    path.lineTo(w / 2 + sunRadius * 0.2, h);
    path.lineTo(w / 2 - sunRadius * 0.2, h);
    path.close();
    canvas.drawPath(path, reflectionPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
