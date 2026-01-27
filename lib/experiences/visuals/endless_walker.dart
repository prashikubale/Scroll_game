import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EndlessWalker extends StatefulWidget {
  final bool active;
  const EndlessWalker({super.key, required this.active});

  @override
  State<EndlessWalker> createState() => _EndlessWalkerState();
}

class _EndlessWalkerState extends State<EndlessWalker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background & Parallax
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) { 
                return CustomPaint(
                    painter: _ParallaxPainter(_controller.value),
                    size: Size.infinite,
                );
            }
          ),
        ),
        
        // Quote Overlay
        Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Center(
                child: Text(
                    "KEEP MOVING",
                    style: GoogleFonts.bebasNeue(
                        fontSize: 30,
                        color: Colors.white24,
                        letterSpacing: 10
                    ),
                ),
            ),
        ),
      ],
    );
  }
}

class _ParallaxPainter extends CustomPainter {
  final double animationValue; // 0 to 1 loop
  // Global time for scrolling
  double get time => DateTime.now().millisecondsSinceEpoch / 1000.0;
  
  _ParallaxPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky
    final skyPaint = Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, skyPaint);
    
    // 2. Stars (Static-ish)
    final rnd = Random(1337);
    final starPaint = Paint()..color = Colors.white;
    for(int i=0; i<50; i++) {
        double x = rnd.nextDouble() * size.width;
        double y = rnd.nextDouble() * size.height * 0.6;
        double s = rnd.nextDouble() * 2;
        canvas.drawCircle(Offset(x, y), s, starPaint..color = Colors.white.withValues(alpha: 0.3 + rnd.nextDouble()*0.5));
    }
    
    // 3. Mountains (Slow Parallax)
    _drawLayer(canvas, size, speed: 20, color: Color(0xFF152A38), seed: 1, height: size.height * 0.5, complexity: 5);

    // 4. City/Trees (Medium Parallax)
    _drawLayer(canvas, size, speed: 60, color: Color(0xFF0B1820), seed: 2, height: size.height * 0.65, complexity: 20);

    // 5. Ground (Fast Parallax)
    _drawLayer(canvas, size, speed: 150, color: Colors.black, seed: 3, height: size.height * 0.85, complexity: 2, flat: true);
    
    // 6. Walker
    _drawWalker(canvas, size);
  }
  
  void _drawLayer(Canvas canvas, Size size, {required double speed, required Color color, required int seed, required double height, int complexity = 10, bool flat = false}) {
      double offset = (time * speed) % size.width;
      
      Paint paint = Paint()..color = color;
      
      // Draw 2 copies for wrap effect
      canvas.save();
      canvas.translate(-offset, 0);
      _drawSceneryInternal(canvas, size, height, complexity, paint, seed);
      canvas.translate(size.width, 0);
      _drawSceneryInternal(canvas, size, height, complexity, paint, seed); // Loop segment
      canvas.translate(size.width, 0); 
      _drawSceneryInternal(canvas, size, height, complexity, paint, seed); // Safety segment
      canvas.restore();
  }
  
  void _drawSceneryInternal(Canvas canvas, Size size, double baseHeight, int seed, Paint paint, int complexity) {
      // Procedural jagged line
      Path path = Path();
      path.moveTo(0, size.height);
      path.lineTo(0, baseHeight);
      
      final rnd = Random(seed);
      double segmentWidth = size.width / complexity;
      
      for(int i=0; i<=complexity; i++) {
          double h = baseHeight - rnd.nextDouble() * 50; 
          path.lineTo(i * segmentWidth, h);
      }
      
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
  }

  void _drawWalker(Canvas canvas, Size size) {
      // Simple stick figure
      double cx = size.width / 2;
      double cy = size.height * 0.85 - 40; // Ground levelish
      
      // Animation cycle t from 0 to 2pi
      double t = animationValue * pi * 2;
      
      Paint p = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
      Paint headP = Paint()..color = Colors.white..style = PaintingStyle.fill;
      
      // Body Bob
      double bob = sin(t * 2) * 2;
      cy += bob;
      
      // Head
      canvas.drawCircle(Offset(cx, cy - 25), 6, headP);
      
      // Torso
      canvas.drawLine(Offset(cx, cy - 20), Offset(cx, cy + 10), p);
      
      // Arms (oppose legs)
      double armAngle = sin(t) * 0.5;
      Offset shoulder = Offset(cx, cy - 15);
      Offset elbowL = shoulder + Offset(sin(armAngle)*10, cos(armAngle)*10);
      Offset handL = elbowL + Offset(sin(armAngle - 0.5)*10, cos(armAngle - 0.5)*10);
      
      Offset elbowR = shoulder + Offset(sin(-armAngle)*10, cos(-armAngle)*10);
      Offset handR = elbowR + Offset(sin(-armAngle - 0.5)*10, cos(-armAngle - 0.5)*10);
      
      canvas.drawLine(shoulder, handL, p);
      canvas.drawLine(shoulder, handR, p);

      // Legs
      Offset hip = Offset(cx, cy + 10);
      double legAngle = sin(t) * 0.8;
      
      // Leg L
      canvas.drawLine(hip, hip + Offset(sin(legAngle)*15, cos(legAngle)*15) + Offset(0, 15), p);
      
      // Leg R
      canvas.drawLine(hip, hip + Offset(sin(-legAngle)*15, cos(-legAngle)*15) + Offset(0, 15), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
