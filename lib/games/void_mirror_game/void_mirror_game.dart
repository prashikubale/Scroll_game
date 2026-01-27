import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class VoidMirrorGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // Dual Characters
  Offset _p1Pos = const Offset(0.2, 0.8); // Top World (Gravity Down)
  Offset _p2Pos = const Offset(0.2, 0.2); // Bottom World (Gravity Up)
  Offset _p1Vel = Offset.zero;
  Offset _p2Vel = Offset.zero;
  
  // Obstacles
  final List<Rect> _obs1 = []; // Top Obstacles
  final List<Rect> _obs2 = []; // Bottom Obstacles
  
  Timer? _gameTimer;

  
  Offset get p1Pos => _p1Pos;
  Offset get p2Pos => _p2Pos;
  List<Rect> get obs1 => _obs1;
  List<Rect> get obs2 => _obs2;
  bool get isPlaying => _isPlaying;
  @override
  int get score => _score;

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
    _p1Pos = const Offset(0.2, 0.8);
    _p2Pos = const Offset(0.2, 0.2); // Starts near top of its screen
    _p1Vel = Offset.zero;
    _p2Vel = Offset.zero;
    _generateLevel();
  }
  
  void _generateLevel() {
    // Generate obstacles moving Left to Right? Endless runner style
    _obs1.clear(); _obs2.clear();
  }

  void jump() {
    if(!_isPlaying) return;
    // P1 Jumps Up (Against Gravity Down)
    if (_p1Pos.dy >= 0.8) { // Grounded check simplified
        _p1Vel = const Offset(0, -0.02);
    }
    
    // P2 Jumps Down (Against Gravity Up)
    if (_p2Pos.dy <= 0.2) { // "Ceiling" grounded check
        _p2Vel = const Offset(0, 0.02);
    }
  }

  void _update() {
    // Gravity
    _p1Vel += const Offset(0, 0.001); // Down
    _p2Vel += const Offset(0, -0.001); // Up
    
    // Move
    _p1Pos += _p1Vel;
    _p2Pos += _p2Vel;
    
    // Ground Constraints (Simulated Floor/Ceiling)
    if (_p1Pos.dy > 0.8) { _p1Pos = Offset(_p1Pos.dx, 0.8); _p1Vel = Offset(_p1Vel.dx, 0); }
    if (_p2Pos.dy < 0.2) { _p2Pos = Offset(_p2Pos.dx, 0.2); _p2Vel = Offset(_p2Vel.dx, 0); }
    
    // Score
    _score++;
    
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

class VoidMirrorGameWidget extends StatelessWidget {
  final VoidMirrorGameController controller;
  const VoidMirrorGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: controller.jump,
          child: Column(
            children: [
                // Top World (Gravity Down)
                Expanded(
                    child: Container(
                        color: Colors.blueGrey[900],
                        child: Stack(
                            children: [
                                const Center(child: Text("GRAVITY DOWN", style: TextStyle(color: Colors.white10))),
                                Positioned(
                                    left: controller.p1Pos.dx * MediaQuery.of(context).size.width,
                                    top: controller.p1Pos.dy * (MediaQuery.of(context).size.height / 2),
                                    child: Container(width: 20, height: 20, color: Colors.cyan),
                                ),
                                // Floor
                                Positioned(bottom: 0, left: 0, right: 0, height: (1.0 - 0.8) * (MediaQuery.of(context).size.height/2), child: Container(color: Colors.white24))
                            ],
                        ),
                    ),
                ),
                Container(height: 2, color: Colors.white),
                // Bottom World (Gravity Up)
                Expanded(
                    child: Container(
                        color: Colors.red[900],
                        child: Stack(
                            children: [
                                const Center(child: Text("GRAVITY UP", style: TextStyle(color: Colors.white10))),
                                Positioned(
                                    left: controller.p2Pos.dx * MediaQuery.of(context).size.width,
                                    top: controller.p2Pos.dy * (MediaQuery.of(context).size.height / 2),
                                    child: Container(width: 20, height: 20, color: Colors.orange),
                                ),
                                // Floor (Top)
                                Positioned(top: 0, left: 0, right: 0, height: 0.2 * (MediaQuery.of(context).size.height/2), child: Container(color: Colors.white24))
                            ],
                        ),
                    ),
                ),
            ],
          ),
        );
      },
    );
  }
}
