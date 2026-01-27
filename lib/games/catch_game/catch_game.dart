import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class CatchGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  int _timeLeft = 30;
  double _basketX = 0.5;
  List<FallingObject> _objects = [];
  Timer? _gameTimer;
  Timer? _spawnTimer;

  double get basketX => _basketX;
  List<FallingObject> get objects => _objects;
  int get timeLeft => _timeLeft;

  void moveBasket(double delta) {
    if (!_isPlaying) return;
    _basketX = (_basketX + delta).clamp(0.1, 0.9);
    notifyListeners();
  }

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _timeLeft = 30;
    _objects = [];
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeLeft--;
      if (_timeLeft <= 0) {
        _isPlaying = false;
        timer.cancel();
        _spawnTimer?.cancel();
      }
      notifyListeners();
    });

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _spawnObject();
    });

    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _updateObjects();
    });
  }

  void _spawnObject() {
    if (_objects.length >= 30) return; // limit to 30 objects
    final random = Random();
    _objects.add(FallingObject(
      x: random.nextDouble() * 0.8 + 0.1,
      y: 0.0,
      isGood: random.nextBool(),
    ));
  }

  void _updateObjects() {
    _objects.removeWhere((obj) {
      obj.y += 0.01;
      
      // Check collision with basket (widened hitbox for better gameplay)
      if (obj.y >= 0.8 && obj.y <= 0.95 && (obj.x - _basketX).abs() < 0.15) {
        if (obj.isGood) {
          _score += 10;
        } else {
          _score = max(0, _score - 5);
        }
        return true;
      }
      
      return obj.y > 1.0;
    });
    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
  }

  @override
  void reset() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    start();
  }

  @override
  int get score => _score;

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }
}

class FallingObject {
  double x;
  double y;
  final bool isGood;

  FallingObject({required this.x, required this.y, required this.isGood});
}

class CatchGameWidget extends StatelessWidget {
  final CatchGameController controller;

  const CatchGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: (details) {
            controller.moveBasket(details.delta.dx / MediaQuery.of(context).size.width);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.lightBlue.shade300, Colors.lightBlue.shade700],
              ),
            ),
            child: Stack(
              children: [
                // Falling objects
                ...controller.objects.map((obj) {
                  return Positioned(
                    left: obj.x * MediaQuery.of(context).size.width - 20,
                    top: obj.y * MediaQuery.of(context).size.height,
                    child: Icon(
                      obj.isGood ? Icons.star : Icons.close,
                      size: 40,
                      color: obj.isGood ? Colors.yellow : Colors.red,
                    ),
                  );
                }),
                
                // Basket
                Positioned(
                  left: controller.basketX * MediaQuery.of(context).size.width - 40,
                  top: 0.8 * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade700,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                      border: Border.all(color: Colors.brown.shade900, width: 3),
                    ),
                  ),
                ),
                
                // Time display
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Time: ${controller.timeLeft}s',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 10, color: Colors.black54),
                        ],
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
