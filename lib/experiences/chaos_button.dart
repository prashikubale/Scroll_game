import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChaosButton extends StatefulWidget {
  final bool active;
  const ChaosButton({super.key, required this.active});

  @override
  State<ChaosButton> createState() => _ChaosButtonState();
}

class _ChaosButtonState extends State<ChaosButton> with SingleTickerProviderStateMixin {
  int _seed = 0;
  late AnimationController _anim;
  
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  void _chaos() {
    setState(() {
      _seed = Random().nextInt(100000);
    });
    _anim.forward(from: 0.0);
  }
  
  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Generative Art Layer
          CustomPaint(
            painter: _ChaosPainter(seed: _seed, progress: _anim),
            size: Size.infinite,
          ),
          
          Center(
            child: GestureDetector(
              onTap: _chaos,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, child) {
                   return Transform.scale(
                     scale: 1.0 - (_anim.value * 0.1),
                     child: Container(
                       width: 200,
                       height: 200,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         shape: BoxShape.circle,
                         boxShadow: [
                           BoxShadow(
                             color: Colors.white.withOpacity(0.5),
                             blurRadius: 50,
                             spreadRadius: 10,
                           )
                         ]
                       ),
                       child: Center(
                         child: Text(
                           "CHAOS",
                           style: GoogleFonts.blackOpsOne(
                             fontSize: 40,
                             color: Colors.black,
                             letterSpacing: 2
                           ),
                         ),
                       ),
                     ),
                   );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ChaosPainter extends CustomPainter {
  final int seed;
  final Animation<double> progress;
  
  _ChaosPainter({required this.seed, required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (seed == 0) return;
    
    final rnd = Random(seed);
    final paint = Paint();
    
    // Draw 50 random shapes
    for(int i=0; i<50; i++) {
       paint.color = Color.fromRGBO(
         rnd.nextInt(256), 
         rnd.nextInt(256), 
         rnd.nextInt(256), 
         rnd.nextDouble() * progress.value // Fade in
       );
       
       double x = rnd.nextDouble() * size.width;
       double y = rnd.nextDouble() * size.height;
       double r = rnd.nextDouble() * 100;
       
       if (rnd.nextBool()) {
          canvas.drawCircle(Offset(x, y), r, paint);
       } else {
          canvas.drawRect(Rect.fromCenter(center: Offset(x,y), width: r, height: r), paint);
       }
       
       if (rnd.nextDouble() > 0.8) {
         paint.style = PaintingStyle.stroke;
         paint.strokeWidth = rnd.nextDouble() * 5;
         canvas.drawLine(
           Offset(x,y), 
           Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), 
           paint
         );
         paint.style = PaintingStyle.fill;
       }
    }
  }

  @override
  bool shouldRepaint(covariant _ChaosPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
