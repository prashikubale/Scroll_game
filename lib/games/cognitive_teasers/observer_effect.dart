import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class ObserverEffectController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  bool _isObserved = false;
  Offset _keyPos = const Offset(0.5, 0.5);
  final Offset _lockPos = const Offset(0.8, 0.2);
  
  // Wave properties
  double _time = 0.0;
  
  Timer? _gameTimer;
  
  bool get isObserved => _isObserved;
  Offset get keyPos => _keyPos;
  Offset get lockPos => _lockPos;
  double get time => _time;
  @override
  int get score => _score;
  bool get isPlaying => _isPlaying;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _reset();
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _update();
    });
    notifyListeners();
  }

  void _reset() {
    _keyPos = const Offset(0.5, 0.5);
    _score = 0;
  }

  void interact(bool touching, Offset? pos, Size size) {
    _isObserved = touching;
    if (touching && pos != null) {
        // Drag logic if key is collapsed
        Offset relPos = Offset(pos.dx / size.width, pos.dy / size.height);
        if ((relPos - _keyPos).distance < 0.1) {
            _keyPos = relPos;
        }
    }
  }

  void _update() {
    _time += 0.05;
    
    if (!_isObserved) {
        // Wave function evolution (Key drifts or spreads?)
        // Let's just animate visuals. Logic-wise it resets to "Cloud" state conceptually
        // For gameplay, maybe key slowly drifts back to center?
        _keyPos += (const Offset(0.5, 0.5) - _keyPos) * 0.01;
    }
    
    // Check lock
    if ((_keyPos - _lockPos).distance < 0.05 && _isObserved) {
        _score = 1;
    }
    
    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _gameTimer?.cancel();
    notifyListeners();
  }
  @override
  void reset() => start();
  @override
  void dispose() { _gameTimer?.cancel(); super.dispose(); }
}

class ObserverEffectWidget extends StatelessWidget {
  final ObserverEffectController controller;
  const ObserverEffectWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanStart: (d) => controller.interact(true, d.localPosition, MediaQuery.of(context).size),
          onPanUpdate: (d) => controller.interact(true, d.localPosition, MediaQuery.of(context).size),
          onPanEnd: (_) => controller.interact(false, null, Size.zero),
          child: Container(
            color: Colors.indigo[900], // Quantum field
            child: Stack(
              children: [
                // Lock
                Positioned(
                    left: controller.lockPos.dx * MediaQuery.of(context).size.width - 20,
                    top: controller.lockPos.dy * MediaQuery.of(context).size.height - 20,
                    child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
                    ),
                ),
                
                // The Entity
                controller.isObserved 
                ? Positioned( // Particle State (Solid)
                    left: controller.keyPos.dx * MediaQuery.of(context).size.width - 15,
                    top: controller.keyPos.dy * MediaQuery.of(context).size.height - 15,
                    child: Container(
                        width: 30, height: 30,
                        color: Colors.white,
                        child: const Center(child: Text("KEY", style: TextStyle(fontSize: 8))),
                    ),
                )
                : CustomPaint( // Wave State (Field)
                    painter: WaveFuncPainter(controller.keyPos, controller.time),
                    size: Size.infinite,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WaveFuncPainter extends CustomPainter {
    final Offset center;
    final double time;
    WaveFuncPainter(this.center, this.time);
    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()
           ..style = PaintingStyle.stroke
           ..strokeWidth = 1
           ..color = Colors.cyan.withValues(alpha: 0.5);
           
        // Draw interference rings
        for(int i=0; i<5; i++) {
            double r = 50.0 * (i+1) + sin(time)*10;
            canvas.drawCircle(Offset(center.dx * size.width, center.dy * size.height), r, paint);
        }
    }
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
