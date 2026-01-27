import 'dart:math';
import 'package:flutter/material.dart';

class BlossomWind extends StatefulWidget {
  final bool active;
  const BlossomWind({super.key, required this.active});

  @override
  State<BlossomWind> createState() => _BlossomWindState();
}

class _BlossomWindState extends State<BlossomWind> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Petal> _petals = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _controller.addListener(_update);
    
    for (int i=0; i<40; i++) {
        _spawnPetal(randomY: true);
    }
  }

  void _spawnPetal({bool randomY = false}) {
      _petals.add(_Petal(
          x: _rnd.nextDouble(),
          y: randomY ? _rnd.nextDouble() : -0.1,
          size: 8 + _rnd.nextDouble() * 8,
          speedY: 0.003 + _rnd.nextDouble() * 0.005,
          speedX: 0.001 + _rnd.nextDouble() * 0.002,
          rotationAxis: _rnd.nextDouble() * pi * 2,
          rotationSpeed: 0.05 + _rnd.nextDouble() * 0.1,
          color: Color.lerp(Colors.pinkAccent, Colors.white, _rnd.nextDouble())!.withValues(alpha: 0.8),
      ));
  }

  void _update() {
    if (!widget.active) return;
    setState(() {
       for (var p in _petals) {
           p.y += p.speedY;
           p.x += p.speedX + sin(p.y * 10) * 0.002; // Wind wave
           p.rotation += p.rotationSpeed;
           p.flip += p.rotationSpeed * 0.5;
       }
       _petals.removeWhere((p) => p.y > 1.1 || p.x > 1.1);
       if (_rnd.nextDouble() < 0.1) {
           _spawnPetal();
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
          color: Color(0xFFFCE4EC), // Very dark pink / light
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8BBD0), Color(0xFFF48FB1)],
          )
      ),
      child: CustomPaint(
        painter: _PetalPainter(_petals),
        size: Size.infinite,
      ),
    );
  }
}

class _Petal {
    double x, y;
    double size;
    double speedY, speedX;
    double rotationAxis;
    double rotation = 0;
    double flip = 0;
    double rotationSpeed;
    Color color;

    _Petal({required this.x, required this.y, required this.size, required this.speedX, required this.speedY, required this.rotationAxis, required this.rotationSpeed, required this.color});
}

class _PetalPainter extends CustomPainter {
  final List<_Petal> petals;
  _PetalPainter(this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in petals) {
        canvas.save();
        canvas.translate(p.x * size.width, p.y * size.height);
        
        // 3D Flip effect simulation
        double scaleX = cos(p.flip);
        
        canvas.rotate(p.rotation);
        canvas.scale(scaleX, 1.0);
        
        Paint paint = Paint()..color = p.color;
        
        // Simple oval petal
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5), paint);
        
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
