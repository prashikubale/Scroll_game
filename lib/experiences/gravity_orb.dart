import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:sensors_plus/sensors_plus.dart'; 
// Note: Imports might need adjustment based on pubspec. Using standard assumption.
import 'package:sensors_plus/sensors_plus.dart';

class GravityOrb extends StatefulWidget {
  final bool active;
  const GravityOrb({super.key, required this.active});

  @override
  State<GravityOrb> createState() => _GravityOrbState();
}

class _GravityOrbState extends State<GravityOrb> with SingleTickerProviderStateMixin {
  // Physics State
  double _x = 0;
  double _y = 0;
  double _vx = 0;
  double _vy = 0;
  
  // Sensor Subscription
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  // Visual State
  late AnimationController _pulseController;
  Color _orbColor = Colors.cyanAccent;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 2)
    )..repeat(reverse: true);
    
    if (widget.active) {
      _startSensors();
    }
  }

  @override
  void didUpdateWidget(covariant GravityOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _startSensors();
      } else {
        _stopSensors();
      }
    }
  }

  void _startSensors() {
    _gyroSubscription?.cancel();
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      
      setState(() {
         // Simple Euler integration
         // Tilt (event.y) controls X, Tilt (event.x) controls Y
         // Multiplier adjustments for feeling
         double ax = event.y * 2.0; 
         double ay = event.x * 2.0;

         _vx += ax;
         _vy += ay;
         
         // Friction/Damping
         _vx *= 0.95;
         _vy *= 0.95;
         
         _x += _vx;
         _y += _vy;
         
         // Boundary constraints (soft bounce)
         // Assuming normalized coordinates -1.0 to 1.0 (roughly)
         if (_x > 150) { _x = 150; _vx = -_vx * 0.5; _changeColor(); }
         if (_x < -150) { _x = -150; _vx = -_vx * 0.5; _changeColor(); }
         if (_y > 250) { _y = 250; _vy = -_vy * 0.5; _changeColor(); }
         if (_y < -250) { _y = -250; _vy = -_vy * 0.5; _changeColor(); }
      });
    });
  }

  void _stopSensors() {
    _gyroSubscription?.cancel();
  }
  
  void _changeColor() {
     final colors = [
       Colors.cyanAccent, Colors.purpleAccent, Colors.amberAccent, 
       Colors.greenAccent, Colors.deepOrangeAccent
     ];
     _orbColor = colors[Random().nextInt(colors.length)];
  }

  @override
  void dispose() {
    _stopSensors();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        // Optional subtle grid or starfield
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
           // Hint Text
           Positioned(
             top: 100,
             child: Opacity(
               opacity: 0.3,
               child: Text(
                 "TILT TO MOVE",
                 style: GoogleFonts.audiowide(color: Colors.white, fontSize: 16, letterSpacing: 5),
               ),
             ),
           ),
           
           // The Orb
           AnimatedBuilder(
             animation: _pulseController,
             builder: (context, child) {
               return Transform.translate(
                 offset: Offset(_x, _y),
                 child: Container(
                   width: 100,
                   height: 100,
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     gradient: RadialGradient(
                       colors: [
                         Colors.white, 
                         _orbColor, 
                         _orbColor.withValues(alpha: 0.0)
                       ],
                       stops: const [0.1, 0.4, 1.0],
                     ),
                     boxShadow: [
                       BoxShadow(
                         color: _orbColor.withValues(alpha: 0.3 + (_pulseController.value * 0.2)),
                         blurRadius: 30 + (_pulseController.value * 20),
                         spreadRadius: 10,
                       )
                     ]
                   ),
                 ),
               );
             },
           ),
        ],
      ),
    );
  }
}
