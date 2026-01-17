import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonFluid extends StatefulWidget {
  final bool active;
  const NeonFluid({super.key, required this.active});

  @override
  State<NeonFluid> createState() => _NeonFluidState();
}

class _NeonFluidState extends State<NeonFluid> with SingleTickerProviderStateMixin {
  final List<_Particle> _particles = [];
  late AnimationController _ticker;
  
  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _ticker.addListener(_tick);
  }

  void _tick() {
    if (!widget.active) return;
    
    setState(() {
      // Update existing particles
      for (var p in _particles) {
        p.life -= 0.02;
        p.x += p.vx;
        p.y += p.vy;
        p.vx *= 0.9;
        p.vy *= 0.9;
      }
      _particles.removeWhere((p) => p.life <= 0);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.active) return;
    
    // Spawn particles at touch
    final renderBox = context.findRenderObject() as RenderBox;
    final localPos = renderBox.globalToLocal(details.globalPosition);
    
    for (int i = 0; i < 3; i++) {
        _particles.add(_Particle(
          x: localPos.dx,
          y: localPos.dy,
          vx: (Random().nextDouble() - 0.5) * 5,
          vy: (Random().nextDouble() - 0.5) * 5,
          color: HSLColor.fromAHSL(1.0, (DateTime.now().millisecondsSinceEpoch / 20) % 360, 1.0, 0.5).toColor(),
        ));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanStart: (d) => _onPanUpdate(DragUpdateDetails(globalPosition: d.globalPosition, delta: Offset.zero)),
      child: Container(
        color: const Color(0xFF050505),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Center(
              child: Text(
                "PAINT WITH LIGHT",
                style: GoogleFonts.audiowide(color: Colors.white10, fontSize: 24),
              ),
            ),
            CustomPaint(
              painter: _ParticlePainter(_particles),
              size: Size.infinite,
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, life;
  Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color}) : life = 1.0;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    // Additive blending for neon effect
    final paint = Paint()..blendMode = BlendMode.plus; // Additive blending for neon effect may vary. 
    // Using standard srcOver with opacity for now, or modulate.
    
    for (var p in particles) {
      paint.color = p.color.withValues(alpha: p.life);
      paint.strokeWidth = p.life * 10;
      paint.strokeCap = StrokeCap.round;
      
      canvas.drawCircle(Offset(p.x, p.y), p.life * 15, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
