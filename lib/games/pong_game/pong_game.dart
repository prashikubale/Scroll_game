import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class PongController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // Game Constants (Relative to screen size 1.0 x 1.0)
  final double paddleWidth = 0.25;
  final double paddleHeight = 0.02;
  final double ballSize = 0.04; // Diameter relative to screen width (approx)
  
  double _ballX = 0.5;
  double _ballY = 0.5;
  double _ballVelX = 0.01;
  double _ballVelY = 0.01;
  
  double _playerX = 0.5;
  double _aiX = 0.5;
  
  Timer? _gameTimer;
  final Random _random = Random();

  double get ballX => _ballX;
  double get ballY => _ballY;
  double get playerX => _playerX;
  double get aiX => _aiX;
  bool get isPlaying => _isPlaying;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _resetBall();
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _update();
    });
    notifyListeners();
  }
  
  void _resetBall() {
    _ballX = 0.5;
    _ballY = 0.5;
    // Randomize start direction slightly
    _ballVelX = (_random.nextBool() ? 1 : -1) * (0.008 + _random.nextDouble() * 0.005);
    _ballVelY = 0.012; // Always starts falling towards player lightly
    notifyListeners();
  }

  void _update() {
    _ballX += _ballVelX;
    _ballY += _ballVelY;
    
    // AI Movement
    // AI tries to follow ballX but has a max speed and reaction delay simulated by 'lerp' conceptually
    double targetX = _ballX;
    // Add some error to AI if ball is moving fast or far
    if (_ballY > 0.5) {
       // AI relaxes when ball is on player side
    } else {
       // AI tries to center paddle on ball
       if (_aiX < targetX - 0.02) _aiX += 0.012;
       else if (_aiX > targetX + 0.02) _aiX -= 0.012;
    }
    _aiX = _aiX.clamp(paddleWidth / 2, 1.0 - paddleWidth / 2);
    
    // Wall Collisions (Left/Right)
    if (_ballX <= 0 || _ballX >= 1.0) {
      _ballVelX *= -1;
      _ballX = _ballX.clamp(0.0, 1.0); // Prevent sticking
    }
    
    // Paddle Collisions
    // Player (Bottom) is at Y ~ 0.9
    // AI (Top) is at Y ~ 0.1
    
    // Player Hit Detection
    if (_ballY >= 0.9 - paddleHeight && _ballY <= 0.9 + paddleHeight && _ballVelY > 0) {
      if ((_ballX - _playerX).abs() < (paddleWidth / 2) + ballSize) {
        // Hit!
        _ballVelY = -_ballVelY.abs(); // Bounce up
        
        // Speed up slightly
        _ballVelY *= 1.05;
        _ballVelX *= 1.05;
        
        // Add "English" / Angling based on where it hit the paddle
        double hitOffset = (_ballX - _playerX) / (paddleWidth / 2); // -1.0 to 1.0
        _ballVelX += hitOffset * 0.005; 
        
        // Cap speed
        if (_ballVelY.abs() > 0.035) _ballVelY = 0.035 * (_ballVelY > 0 ? 1 : -1);
        
        _score++;
        notifyListeners();
      }
    }
    
    // AI Hit Detection
    if (_ballY <= 0.1 + paddleHeight && _ballY >= 0.1 - paddleHeight && _ballVelY < 0) {
      if ((_ballX - _aiX).abs() < (paddleWidth / 2) + ballSize) {
        _ballVelY = _ballVelY.abs(); // Bounce down
        
        // Slightly less speedup from AI hits
         double hitOffset = (_ballX - _aiX) / (paddleWidth / 2);
        _ballVelX += hitOffset * 0.002;
      }
    }
    
    // Game Over / Miss
    // Player Misses
    if (_ballY > 1.05) {
      _isPlaying = false;
      notifyListeners();
    }
    
    // AI Misses (score bonus?)
    if (_ballY < -0.05) {
      // Player beats AI
       _score += 10;
       _resetBall(); // New round
    }
    
    notifyListeners();
  }

  void movePaddle(double delta) {
    if (!_isPlaying) return;
    _playerX += delta;
    _playerX = _playerX.clamp(paddleWidth / 2, 1.0 - paddleWidth / 2);
    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _gameTimer?.cancel();
    notifyListeners();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // Ensure consistent aspect ratio logic if needed, but for now we rely on relative 0..1
        
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque, // Capture all touches
              onPanStart: (details) {
                 if (!controller.isPlaying) {
                   controller.start();
                 }
              },
              onPanUpdate: (details) {
                // Determine movement relative to screen width
                controller.movePaddle(details.delta.dx / width);
              },
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.indigo.shade900],
                  ),
                  borderRadius: BorderRadius.circular(20), // Matches game container usually
                ),
                child: Stack(
                  children: [
                    // Start Prompt
                    if (!controller.isPlaying)
                      Center(
                        child: Text(
                          "TAP TO START",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      
                    // Score
                    Positioned(
                      top: height * 0.45,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          controller.score.toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.1),
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Mid Line
                    Center(
                      child: Container(
                        height: 2,
                        width: double.infinity,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    
                    // AI Paddle (Top)
                    Positioned(
                      top: height * 0.1 - (height * controller.paddleHeight / 2),
                      left: (controller.aiX * width) - (width * controller.paddleWidth / 2),
                      child: Container(
                        width: width * controller.paddleWidth,
                        height: height * controller.paddleHeight,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                             BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    
                    // Player Paddle (Bottom)
                    Positioned(
                      top: height * 0.9 - (height * controller.paddleHeight / 2),
                      left: (controller.playerX * width) - (width * controller.paddleWidth / 2),
                      child: Container(
                         width: width * controller.paddleWidth,
                        height: height * controller.paddleHeight,
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                             BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    
                    // Ball
                    Positioned(
                      // Position is Top-Left of the ball, so subtract half radius to center visually
                      top: (controller.ballY * height) - (width * controller.ballSize / 2),
                      left: (controller.ballX * width) - (width * controller.ballSize / 2),
                      child: Container(
                        width: width * controller.ballSize,
                        height: width * controller.ballSize, // Keep it circular based on width
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 10),
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
      },
    );
  }
}

