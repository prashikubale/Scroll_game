import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class MetaDecayController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  double _clarity = 0.0; // 0.0 dirty, 1.0 clean
  List<Offset> _dustParticles = [];
  
  Timer? _gameTimer;
  
  double get clarity => _clarity;
  List<Offset> get dustParticles => _dustParticles; 
  @override
  int get score => _score;
  @override
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
    _clarity = 0.0;
    _score = 0;
    _generateDust();
  }
  
  void _generateDust() {
      _dustParticles.clear();
      for(int i=0; i<100; i++) {
          _dustParticles.add(Offset(Random().nextDouble(), Random().nextDouble()));
      }
  }

  void scrub() {
    if (!_isPlaying) return;
    _clarity = (_clarity + 0.03).clamp(0.0, 1.0);
    // Remove dust
    if (_dustParticles.isNotEmpty) {
        _dustParticles.removeLast(); // Simple remove
    }
  }

  void _update() {
    // Dirt accumulates back if not fully clean
    if (_clarity < 1.0) {
        _clarity = max(0.0, _clarity - 0.005);
    }
    
    if (_clarity > 0.95 && _dustParticles.isEmpty) {
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

class MetaDecayWidget extends StatelessWidget {
  final MetaDecayController controller;
  const MetaDecayWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: (_) => controller.scrub(),
          child: Container(
            color: Colors.white, // The "Pure" underlying UI
            child: Stack(
              children: [
                const Center(child: Text("SYSTEM OPTIMAL", style: TextStyle(color: Colors.green, fontSize: 30))),
                
                // The filth layer
                Opacity(
                    opacity: 1.0 - controller.clarity,
                    child: Container(
                        color: Colors.black.withOpacity(0.9), // Thick grime
                        child: CustomPaint(
                            painter: DustPainter(controller.dustParticles),
                            size: Size.infinite,
                        ),
                    ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DustPainter extends CustomPainter {
    final List<Offset> points;
    DustPainter(this.points);
    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()..color = Colors.grey..strokeWidth = 3;
        for(var p in points) {
            canvas.drawCircle(Offset(p.dx * size.width, p.dy * size.height), Random().nextDouble() * 5 + 1, paint);
        }
    }
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
