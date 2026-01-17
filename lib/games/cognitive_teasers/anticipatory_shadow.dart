import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class AnticipatoryShadowController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  double _progress = 0.0; // 0.0 represents distance, 1.0 is IMPACT
  final double _speed = 0.005;
  bool _crashed = false;
  bool _caught = false;
  
  Timer? _gameTimer;
  
  double get progress => _progress;
  bool get crashed => _crashed;
  bool get caught => _caught;
  bool get isPlaying => _isPlaying;
  @override
  int get score => _score;

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
    _progress = 0.0;
    _crashed = false;
    _caught = false;
    _score = 0;
  }

  void tap() {
    if (_caught || _crashed) {
        // Restart on tap if ended
        if (_progress > 1.0 || _caught) _reset();
        return;
    }
    
    // Check timing
    if (_progress > 0.85 && _progress < 0.98) {
        // Success
        _caught = true;
        _score = 1;
    } else {
        // Too early or late (if not crashed yet)
        // If too early, punish? Maybe reset progress slightly?
        // Or just fail. "Too Early".
        // Let's just make it do nothing if too early, user must wait.
    }
    notifyListeners();
  }

  void _update() {
    if (_caught) return;
    if (_crashed) return;
    
    // Non-linear acceleration (Looming effect)
    // Looming is exponential visual expansion.
    // Progress 0->1.
    
    double loomFactor = 1.0 + (_progress * 2); // Speed increases
    _progress += _speed * loomFactor;
    
    if (_progress >= 1.0) {
        _crashed = true;
        _progress = 1.0;
        // Visual crash
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

class AnticipatoryShadowWidget extends StatelessWidget {
  final AnticipatoryShadowController controller;
  const AnticipatoryShadowWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: controller.tap,
          child: Container(
            color: Colors.white, // Bright "Glass" background
            child: Stack(
              children: [
                if (controller.crashed)
                    Container(color: Colors.black.withValues(alpha: 0.8), child: const Center(child: Text("CRASH", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)))),
                    
                if (controller.caught)
                    const Center(child: Text("INTERCEPTED", style: TextStyle(color: Colors.black, fontSize: 30, letterSpacing: 5))),

                if (!controller.crashed && !controller.caught)
                    Center(
                        child: Transform.scale(
                            scale: 0.1 + (controller.progress * 20), // Grows massive
                            child: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                    boxShadow: [
                                        BoxShadow(color: Colors.black, blurRadius: 20 + (100 * (1.0 - controller.progress))) // Sharpens as it gets closer
                                    ]
                                ),
                                child: Opacity(
                                    opacity: controller.progress.clamp(0.0, 1.0),
                                    child: const SizedBox(),
                                ),
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
