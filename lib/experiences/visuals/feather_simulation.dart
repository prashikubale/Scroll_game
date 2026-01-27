import 'dart:math';
import 'package:flutter/material.dart';

class FeatherSimulation extends StatefulWidget {
  final bool active;
  const FeatherSimulation({super.key, required this.active});

  @override
  State<FeatherSimulation> createState() => _FeatherSimulationState();
}

class _FeatherSimulationState extends State<FeatherSimulation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Feather> _feathers = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _controller.addListener(_update);
    
    // Initial spawn
    for (int i=0; i<20; i++) {
        _spawnFeather(randomY: true);
    }
  }
  
  void _spawnFeather({bool randomY = false}) {
      _feathers.add(_Feather(
          x: _rnd.nextDouble(),
          y: randomY ? _rnd.nextDouble() : -0.1,
          size: 20 + _rnd.nextDouble() * 30,
          speed: 0.002 + _rnd.nextDouble() * 0.003,
          swayFreq: 2 + _rnd.nextDouble() * 3,
          swayAmp: 0.05 + _rnd.nextDouble() * 0.1,
          phase: _rnd.nextDouble() * pi * 2,
          rotationSpeed: (_rnd.nextDouble() - 0.5) * 0.02,
      ));
  }

  void _update() {
    if (!widget.active) return;
    
    setState(() {
      for (var f in _feathers) {
          f.y += f.speed;
          f.rotation += f.rotationSpeed;
          f.phase += 0.05;
      }
      
      _feathers.removeWhere((f) => f.y > 1.2);
      
      if (_rnd.nextDouble() < 0.05) {
          _spawnFeather();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)], // Soft Sky Blue
          )
      ),
      child: CustomPaint(
        painter: _FeatherPainter(_feathers),
        size: Size.infinite,
      ),
    );
  }
}

class _Feather {
    double x, y;
    double size;
    double speed;
    double swayFreq;
    double swayAmp;
    double phase;
    double rotation;
    double rotationSpeed;
    
    _Feather({required this.x, required this.y, required this.size, required this.speed, required this.swayFreq, required this.swayAmp, required this.phase, required this.rotationSpeed}) : rotation = 0;
}

class _FeatherPainter extends CustomPainter {
    final List<_Feather> feathers;
    _FeatherPainter(this.feathers);
    
    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()..color = Colors.white.withValues(alpha: 0.9)..style = PaintingStyle.fill;
        final rachisPaint = Paint()..color = Colors.grey.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1;

        for (var f in feathers) {
            canvas.save();
            
            // Calculate Sway x
            double sway = sin(f.phase) * f.swayAmp;
            
            canvas.translate((f.x + sway) * size.width, f.y * size.height);
            canvas.rotate(f.rotation + sway); // Rotate with sway
            
            // Draw Feather
            Path path = Path();
            double w = f.size / 3;
            double h = f.size;
            
            path.moveTo(0, -h/2);
            path.quadraticBezierTo(w, -h/4, 0, h/2); // Right side
            path.moveTo(0, -h/2);
            path.quadraticBezierTo(-w, -h/4, 0, h/2); // Left side
            
            canvas.drawPath(path, paint);
            canvas.drawLine(Offset(0, -h/2), Offset(0, h/2), rachisPaint);
            
            canvas.restore();
        }
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
