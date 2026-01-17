import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class AntiGravityGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // Physics
  Offset _playerPos = const Offset(0.5, 0.9);
  Offset _playerVel = Function.apply(() => Offset.zero, []); // dynamic gravity logic
  Offset _gravityDir = const Offset(0, 1); // Down initially
  bool _isGrounded = true;
  double _playerRotation = 0; // 0, 90, 180, 270 degrees in radians
  
  // Game Objects
  Offset _targetPos = const Offset(0.5, 0.2);
  final Random _rnd = Random();
  Timer? _gameTimer;
  
  // Getters
  Offset get playerPos => _playerPos;
  double get playerRotation => _playerRotation;
  Offset get targetPos => _targetPos;
  bool get isPlaying => _isPlaying;
  @override
  int get score => _score;

  // Constants
  static const double gravityPower = 0.0015;
  static const double jumpPower = 0.035;
  static const double moveSpeed = 0.015;
  static const double playerSize = 0.08;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _resetPlayer();
    _spawnTarget();
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _update();
    });
    notifyListeners();
  }

  void _resetPlayer() {
    _playerPos = const Offset(0.5, 0.9);
    _playerVel = Offset.zero;
    _gravityDir = const Offset(0, 1);
    _playerRotation = 0;
    _isGrounded = false; // Let it fall to floor to init
  }

  void _spawnTarget() {
    // Spawn somewhat away from player
    double x = _rnd.nextDouble() * 0.8 + 0.1;
    double y = _rnd.nextDouble() * 0.8 + 0.1;
    _targetPos = Offset(x, y);
  }

  void jump() {
    if (!_isPlaying || !_isGrounded) return;
    
    // Jump OPPOSITE to gravity
    _playerVel = -_gravityDir * jumpPower;
    _isGrounded = false;
    notifyListeners();
  }
  
  void move(double deltaX, double deltaY) {
    if (!_isPlaying) return;
    
    // Move perpendicular to gravity
    // If gravity is (0, 1) [Down], valid move is X axis
    // If gravity is (1, 0) [Right], valid move is Y axis
    
    if (_gravityDir.dy.abs() > 0.5) {
      // Gravity is Vertical (Down or Up)
      // We only care about X input
      _playerVel = Offset(deltaX * moveSpeed, _playerVel.dy);
    } else {
      // Gravity is Horizontal (Left or Right)
      // We only care about Y input
      _playerVel = Offset(_playerVel.dx, deltaY * moveSpeed);
    }
  }

  void _update() {
    // Apply Gravity
    if (!_isGrounded) {
      _playerVel += _gravityDir * gravityPower;
    }
    
    // Apply Velocity
    _playerPos += _playerVel;
    
    // Collision Detect with Walls (The Paradox Logic)
    _checkWallCollision();
    
    // Target Collection
    if ((_playerPos - _targetPos).distance < playerSize) {
      _score++;
      _spawnTarget();
      // Increase speed slightly?
    }
    
    notifyListeners();
  }
  
  void _checkWallCollision() {
    bool hit = false;
    
    // Left Wall
    if (_playerPos.dx <= 0) {
      _playerPos = Offset(0, _playerPos.dy);
      _setGravity(const Offset(-1, 0), -pi / 2);
      hit = true;
    }
    // Right Wall
    else if (_playerPos.dx >= 1.0) {
      _playerPos = Offset(1.0, _playerPos.dy);
      _setGravity(const Offset(1, 0), pi / 2);
      hit = true;
    }
    
    // Top Wall
    if (_playerPos.dy <= 0) {
      _playerPos = Offset(_playerPos.dx, 0);
      _setGravity(const Offset(0, -1), pi);
      hit = true;
    }
    // Bottom Wall
    else if (_playerPos.dy >= 1.0) {
      _playerPos = Offset(_playerPos.dx, 1.0);
      _setGravity(const Offset(0, 1), 0);
      hit = true;
    }
    
    if (hit) {
      // If we hit a wall that is our CURRENT gravity direction, stop.
      // E.g. Falling Down (0,1) and hit Bottom (y>=1).
      // Dot product > 0 means we are moving INTO the wall
      
      // Simplified: Just kill velocity into the wall
      _isGrounded = true; 
      
      // Stop velocity in the gravity direction, keep tangential velocity (friction?)
      // For this game, let's just stop all velocity on impact for precise control
      // _playerVel = Offset.zero; // Too harsh?
      
      // Project velocity to remove component in gravity direction
      // If gravity is (0, 1), we want to keep dx, zero dy.
      if (_gravityDir.dx.abs() > 0) {
        _playerVel = Offset(0, _playerVel.dy * 0.9); // Friction
      } else {
        _playerVel = Offset(_playerVel.dx * 0.9, 0);
      }
    }
  }
  
  void _setGravity(Offset dir, double rotation) {
    // Only change if different (landing on a new surface)
    if (_gravityDir != dir) {
      _gravityDir = dir;
      _playerRotation = rotation;
    }
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
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

class AntiGravityGameWidget extends StatelessWidget {
  final AntiGravityGameController controller;

  const AntiGravityGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: controller.jump,
          onPanUpdate: (details) {
            // Normalize Drag
            // We pass raw delta, controller decides which axis to use based on gravity
            // This is key: User swipes "Left" on screen, does it move player Left?
            // Yes, visual mapping should be 1:1 for "Movement"
            double dx = details.delta.dx;
            double dy = details.delta.dy;
            
            // Sensitivity boost
            dx *= 2.0;
            dy *= 2.0;
            
            controller.move(dx, dy);
          },
          child: Container(
            color: Colors.grey[900], // Dark Void
            child: Stack(
              children: [
                // Grid Background (Visual Aid)
                Center(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white10, width: 2),
                      gradient: RadialGradient(
                        colors: [Colors.grey.shade800, Colors.black],
                        radius: 1.2,
                      ),
                    ),
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                ),
                
                // Instructions
                 if (!controller.isPlaying)
                   Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Text(
                           "THE SURFACE PARADOX",
                           style: TextStyle(
                             color: Colors.cyanAccent,
                             fontSize: 24,
                             fontWeight: FontWeight.bold,
                             letterSpacing: 3,
                           ),
                         ),
                         const SizedBox(height: 10),
                         Text(
                           "Tap to Jump • Swipe to Move\nGravity follows the wall you touch.",
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             color: Colors.white.withValues(alpha: 0.7),
                             fontSize: 14,
                           ),
                         ),
                         const SizedBox(height: 20),
                         const Text(
                           "TAP TO START",
                           style: TextStyle(color: Colors.white, fontSize: 18),
                         )
                       ],
                     ),
                   ),

                // Target Orb
                Positioned(
                  left: controller.targetPos.dx * MediaQuery.of(context).size.width - 15,
                  top: controller.targetPos.dy * MediaQuery.of(context).size.height - 15,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.amberAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(color: Colors.amber.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.star, size: 20, color: Colors.white),
                  ),
                ),
                
                // Player
                Positioned(
                  left: controller.playerPos.dx * MediaQuery.of(context).size.width - 20,
                  top: controller.playerPos.dy * MediaQuery.of(context).size.height - 20,
                  child: Transform.rotate(
                    angle: controller.playerRotation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.cyan,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 10),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end, // Feet at bottom
                        children: [
                          // Eyes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(width: 8, height: 8, color: Colors.black),
                              Container(width: 8, height: 8, color: Colors.black),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Score
                Positioned(
                  top: 40,
                  right: 20,
                  child: Text(
                    controller.score.toString(),
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
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

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
      
    final double step = size.width / 10;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
