import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class PongController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  double _ballX = 0.5;
  double _ballY = 0.5;
  double _ballVelX = 0.015;
  double _ballVelY = 0.015;
  
  double _playerX = 0.5;
  double _aiX = 0.5;
  
  Timer? _gameTimer;

  double get ballX => _ballX;
  double get ballY => _ballY;
  double get playerX => _playerX;
  double get aiX => _aiX;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    resetBall();
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      update();
    });
  }
  
  void resetBall() {
    _ballX = 0.5;
    _ballY = 0.5;
    _ballVelX = 0.015 * (_ballVelX > 0 ? 1 : -1);
    _ballVelY = -0.015;
  }

  void update() {
    _ballX += _ballVelX;
    _ballY += _ballVelY;
    
    // AI Movement (Simple tracking)
    if (_aiX < _ballX) _aiX += 0.01;
    if (_aiX > _ballX) _aiX -= 0.01;
    _aiX = _aiX.clamp(0.1, 0.9);
    
    // Wall Collisions
    if (_ballX <= 0 || _ballX >= 1.0) _ballVelX *= -1;
    
    // Paddle Collisions
    // Player (Bottom)
    if (_ballY >= 0.9 && _ballY <= 0.95 && (_ballX - _playerX).abs() < 0.15) {
      _ballVelY = -_ballVelY.abs();
      _score++;
      notifyListeners();
    }
    
    // AI (Top)
    if (_ballY <= 0.1 && _ballY >= 0.05 && (_ballX - _aiX).abs() < 0.15) {
      _ballVelY = _ballVelY.abs();
    }
    
    // Miss
    if (_ballY > 1.0) {
      _isPlaying = false; // Game Over
      notifyListeners();
    }
    
    if (_ballY < 0.0) {
      // AI Missed (Win point) - Just bounce back for endless arcade feel or increment score massive?
      // Let's just bounce for now to keep it simple, or reset ball
      _ballVelY = _ballVelY.abs();
      _score += 5; // Bonus for beating AI
    }
    
    notifyListeners();
  }

  void movePaddle(double delta) {
    if (!_isPlaying) return;
    _playerX = (_playerX + delta).clamp(0.1, 0.9);
    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _gameTimer?.cancel();
  }

  @override
  void reset() {
    _gameTimer?.cancel();
    start();
  }

  @override
  int get score => _score;
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

class PongWidget extends StatelessWidget {
  final PongController controller;

  const PongWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: (details) {
            controller.movePaddle(details.delta.dx / MediaQuery.of(context).size.width);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.indigo.shade900],
              ),
            ),
            child: Stack(
              children: [
                // Mid Line
                Center(
                  child: Container(
                    height: 2,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                
                // AI Paddle
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.1,
                  left: controller.aiX * MediaQuery.of(context).size.width - 40,
                  child: Container(
                    width: 80,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                         BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
                
                // Player Paddle
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.1,
                  left: controller.playerX * MediaQuery.of(context).size.width - 40,
                  child: Container(
                    width: 80,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                         BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
                
                // Ball
                Positioned(
                  top: controller.ballY * MediaQuery.of(context).size.height - 10,
                  left: controller.ballX * MediaQuery.of(context).size.width - 10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 15),
                      ],
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
