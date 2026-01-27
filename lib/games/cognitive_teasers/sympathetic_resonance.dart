import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class SympatheticResonanceController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0; // Not used for traditional scoring, but maybe for completion state?
  
  double _vibrationIntensity = 1.0;
  bool _isHoldingStaticLine = false;
  bool _isTouchingVibratingLine = false;
  
  Timer? _gameTimer;

  
  // Getters
  double get vibrationIntensity => _vibrationIntensity;
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
    _vibrationIntensity = 1.0;
    _score = 0;
  }

  void touchVibratingLine(bool touching) {
    _isTouchingVibratingLine = touching;
    if (touching) {
        // Feedback: Agitation
        _vibrationIntensity = min(2.0, _vibrationIntensity + 0.2);
        notifyListeners();
    }
  }

  void holdStaticLine(bool holding) {
    _isHoldingStaticLine = holding;
  }

  void _update() {
    if (_isHoldingStaticLine) {
        // Calming effect (Sympathetic grounding)
        _vibrationIntensity = max(0.0, _vibrationIntensity - 0.01);
    } else {
        // Natural chaos returns slowly if not fully calmed
        if (_vibrationIntensity > 0.05 && _vibrationIntensity < 1.0) {
             _vibrationIntensity += 0.005;
        }
    }
    
    // Aggravation
    if(_isTouchingVibratingLine) {
        _vibrationIntensity = min(3.0, _vibrationIntensity + 0.05);
    }

    // "Win" state? Insight moment.
    if (_vibrationIntensity <= 0.0) {
        _score = 1; // Solved
        // Keep it calm
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

class SympatheticResonanceWidget extends StatelessWidget {
  final SympatheticResonanceController controller;
  const SympatheticResonanceWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final rnd = Random();
        double shakeX = (rnd.nextDouble() - 0.5) * 10 * controller.vibrationIntensity;

        
        return Container(
          color: const Color(0xFF222222),
          child: Stack(
            children: [
                // Vibrating Line (Left)
                Positioned(
                    left: MediaQuery.of(context).size.width * 0.3 + shakeX,
                    top: 0, bottom: 0,
                    width: 60, // Hitbox
                    child: GestureDetector(
                        onTapDown: (_) => controller.touchVibratingLine(true),
                        onTapUp: (_) => controller.touchVibratingLine(false),
                        onTapCancel: () => controller.touchVibratingLine(false),
                        child: Center(
                            child: Container(
                                width: 4 + (controller.vibrationIntensity * 2), // Gets thicker/angrier
                                height: double.infinity,
                                color: Color.lerp(Colors.white, Colors.red, (controller.vibrationIntensity - 1.0).clamp(0.0, 1.0)),
                            ),
                        ),
                    ),
                ),
                
                // Static Line (Right)
                Positioned(
                    right: MediaQuery.of(context).size.width * 0.3,
                    top: 0, bottom: 0,
                    width: 60, // Hitbox
                    child: GestureDetector(
                        onTapDown: (_) => controller.holdStaticLine(true),
                        onTapUp: (_) => controller.holdStaticLine(false),
                        onTapCancel: () => controller.holdStaticLine(false),
                        child: Center(
                            child: Container(
                                width: 4,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: controller._isHoldingStaticLine ? [BoxShadow(color: Colors.white, blurRadius: 10)] : [],
                                ),
                            ),
                        ),
                    ),
                ),
                
                // Optional Text (Hidden mostly)
                if (controller.score > 0)
                   const Center(child: Text("RESONANCE GROUNDED", style: TextStyle(color: Colors.white30, letterSpacing: 4))),
            ],
          ),
        );
      },
    );
  }
}
