import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class ChromaticSilenceController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  Color _currentColor = Colors.red;
  bool _isHolding = false;
  bool _isStable = false;
  
  // Colors: Red, Green, Blue, Yellow.
  // One is "Silent" (Stable). Others vibrate.
  // Let's say BLUE is stable.
  final Color _silentColor = Colors.blue; 
  
  Timer? _gameTimer;
  final Random _rnd = Random();
  
  Color get currentColor => _currentColor;
  bool get isStable => _isStable;
  bool get isHolding => _isHolding;
  @override
  int get score => _score;
  @override
  bool get isPlaying => _isPlaying;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _reset();
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) { // Shift color rapidly
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _update();
    });
    notifyListeners();
  }

  void _reset() {
    _score = 0;
    _isHolding = false;
    _isStable = false;
  }

  void hold(bool holding) {
    if (!_isPlaying) return;
    _isHolding = holding;
    checkState();
  }

  void checkState() {
     if (_isHolding) {
         if (_currentColor == _silentColor) {
             _isStable = true;
             _score = 1;
         } else {
             // Agitate if holding wrong color?
             _isStable = false;
         }
     } else {
         _isStable = false;
     }
     notifyListeners();
  }

  void _update() {
    if (_isStable) return; // Stop shifting if stabilized
    
    // Pick random color
    List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow];
    _currentColor = colors[_rnd.nextInt(colors.length)];
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

class ChromaticSilenceWidget extends StatelessWidget {
  final ChromaticSilenceController controller;
  const ChromaticSilenceWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Vibrate entire screen unless stable
        double offset = controller.isStable ? 0 : 5.0;
        
        return GestureDetector(
          onTapDown: (_) => controller.hold(true),
          onTapUp: (_) => controller.hold(false),
          onTapCancel: () => controller.hold(false),
          child: Transform.translate(
              offset: Offset(
                  controller.isStable ? 0 : (Random().nextDouble() - 0.5) * offset * 2, 
                  controller.isStable ? 0 : (Random().nextDouble() - 0.5) * offset * 2
              ),
              child: Container(
                  color: controller.currentColor,
                  child: Center(
                      child: controller.score > 0 
                      ? const Text("SILENCE FOUND", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))
                      : const SizedBox(),
                  ),
              ),
          ),
        );
      },
    );
  }
}
