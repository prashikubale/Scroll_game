import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class CausalityEchoGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  Offset _playerPos = const Offset(0.5, 0.5);
  Offset _targetPos = const Offset(0.8, 0.2);
  
  // Input Queue (TimeStamped)
  final Queue<ActionEvents> _futureActions = Queue();
  static const int delayMs = 1500; // 1.5 seconds delay
  
  Timer? _gameTimer;
  final Random _rnd = Random();
  
  Offset get playerPos => _playerPos;
  Offset get targetPos => _targetPos;
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
    _playerPos = const Offset(0.5, 0.5);
    _spawnTarget();
    _futureActions.clear();
  }
  
  void _spawnTarget() {
    _targetPos = Offset(_rnd.nextDouble() * 0.8 + 0.1, _rnd.nextDouble() * 0.8 + 0.1);
  }

  void input(Offset tapPos) {
    if (!_isPlaying) return;
    // Schedule Move
    _futureActions.add(ActionEvents(
        executeTime: DateTime.now().add(const Duration(milliseconds: delayMs)),
        type: ActionType.move,
        data: tapPos
    ));
    // Visual Feedback of "Ghost" touch? Handled in UI
    notifyListeners();
  }

  void _update() {
    final now = DateTime.now();
    
    // Process Actions
    while (_futureActions.isNotEmpty && _futureActions.first.executeTime.isBefore(now)) {
        final action = _futureActions.removeFirst();
        if (action.type == ActionType.move) {
            // "Teleport" or Move towards?
            // Let's make it a Force Push towards tap.
            Offset dir = (action.data as Offset) - _playerPos;
            _playerPos += dir * 0.2; // Jump 20% towards tap
        }
    }
    
    // Bounds
    _playerPos = Offset(_playerPos.dx.clamp(0.0, 1.0), _playerPos.dy.clamp(0.0, 1.0));
    
    // Check Target
    if ((_playerPos - _targetPos).distance < 0.05) {
        _score++;
        _spawnTarget();
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

enum ActionType { move }
class ActionEvents {
    DateTime executeTime;
    ActionType type;
    dynamic data;
    ActionEvents({required this.executeTime, required this.type, required this.data});
}

class CausalityEchoGameWidget extends StatelessWidget {
  final CausalityEchoGameController controller;
  const CausalityEchoGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (d) {
             final rel = Offset(d.localPosition.dx / MediaQuery.of(context).size.width, d.localPosition.dy / MediaQuery.of(context).size.height);
             controller.input(rel);
          },
          child: Container(
            color: Colors.brown[900], // Sepia/Time theme
            child: Stack(
              children: [
                // Target
                 Positioned(
                    left: controller.targetPos.dx * MediaQuery.of(context).size.width - 15,
                    top: controller.targetPos.dy * MediaQuery.of(context).size.height - 15,
                    child: const Icon(Icons.hourglass_bottom, color: Colors.amberAccent, size: 30),
                ),
                
                // Player
                Positioned(
                    left: controller.playerPos.dx * MediaQuery.of(context).size.width - 15,
                    top: controller.playerPos.dy * MediaQuery.of(context).size.height - 15,
                    child: const Icon(Icons.circle, color: Colors.white, size: 30),
                ),
                
                // Delay Indicator (Simple Bar)
                // "Echo Lag: 1.5s"
                
                if (!controller.isPlaying)
                   const Center(child: Text("CAUSALITY ECHO\nActions happen 1.5s later.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24))),
                   
                 Positioned(top: 40, right: 20, child: Text(controller.score.toString(), style: const TextStyle(color: Colors.white, fontSize: 32))),
              ],
            ),
          ),
        );
      },
    );
  }
}
