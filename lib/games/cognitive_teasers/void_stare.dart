import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class VoidStareController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  Offset _eyePos = const Offset(0.5, 0.5);
  Offset _targetPos = const Offset(0.5, 0.5); // Where the user is touching (or not)
  double _eyeOpenness = 0.5; // 0.0 closed (flinch), 1.0 open (safe)
  
  Timer? _gameTimer;
  DateTime? _lastInputTime;
  
  bool get isPlaying => _isPlaying;
  double get eyeOpenness => _eyeOpenness;
  Offset get eyePos => _eyePos;
  @override
  int get score => _score; // 1 if full open

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
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
    _eyeOpenness = 0.5;
    _lastInputTime = DateTime.now();
  }

  void onInput(Offset localPos, Size size) {
    _lastInputTime = DateTime.now();
    _targetPos = Offset(localPos.dx / size.width, localPos.dy / size.height);
    
    // Immediate flinch on input
    _eyeOpenness = max(0.0, _eyeOpenness - 0.1);
  }

  void _update() {
    final now = DateTime.now();
    final timeSinceInput = now.difference(_lastInputTime ?? now).inMilliseconds;
    
    if (timeSinceInput > 2000) { // 2 seconds silence
        // Open slowly
        _eyeOpenness = min(1.0, _eyeOpenness + 0.005);
    } else {
        // Closing/Closed
        // Flinch recovery is slow, but active input keeps it closed
    }
    
    // Eye tracking logic (Ease towards input or center if no input)
    // If no input, eye centers itself to "stare back"
    Offset desired = (timeSinceInput > 2000) ? const Offset(0.5, 0.5) : _targetPos;
    
    _eyePos += (desired - _eyePos) * 0.1;
    
    if (_eyeOpenness >= 0.95) {
        _score = 1; // Insight
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

class VoidStareWidget extends StatelessWidget {
  final VoidStareController controller;
  const VoidStareWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: (d) => controller.onInput(d.localPosition, MediaQuery.of(context).size),
          onTapDown: (d) => controller.onInput(d.localPosition, MediaQuery.of(context).size),
          child: Container(
            color: Colors.black,
            child: CustomPaint(
              painter: EyePainter(
                pos: controller.eyePos, 
                openness: controller.eyeOpenness
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class EyePainter extends CustomPainter {
  final Offset pos;
  final double openness;
  
  EyePainter({required this.pos, required this.openness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(pos.dx * size.width, pos.dy * size.height);
    final maxRadius = size.width * 0.4;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withOpacity(0.5);

    // Sclera boundaries (Eyelids)
    // Draw using two curves clipping? Or just scale height.
    // Let's draw concentric circles but squash the Y axis based on openness.
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    
    // Jitter if closed/flinching?
    if (openness < 0.3) {
        canvas.translate(Random().nextDouble()*4 - 2, Random().nextDouble()*4 - 2);
    }
    
    // Iris / Pupil layers
    // Providing depth
    for(int i=0; i<5; i++) {
        double r = maxRadius * (1.0 - i*0.2);
        // Squash Y for blink
        double ovalH = r * openness;
        
        canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: r*2, height: ovalH*2), 
            paint..color = Colors.cyanAccent.withOpacity(0.1 + (i*0.1))
        );
    }
    
    // Solid Pupil
    Paint pupilPaint = Paint()..color = Colors.black;
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 30, height: 30 * openness), 
        pupilPaint
    );
    
    canvas.restore();
    
    // "Fog" overlay if not fully open?
    if (openness >= 0.95) {
       // Clear view
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
