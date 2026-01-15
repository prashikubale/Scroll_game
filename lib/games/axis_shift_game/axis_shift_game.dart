import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class AxisShiftGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // Game State
  Offset _playerPos = const Offset(0.5, 0.5);
  Offset _playerVel = Offset.zero;
  double _gravityRotation = 0; // 0, pi/2, pi, 3pi/2
  double _visualRotation = 0; // Tweened value for camera
  
  // Level Data (Walls in normalized coords)
  List<Rect> _walls = [
    // Box
    const Rect.fromLTWH(0, 0, 1, 0.05), // Top
    const Rect.fromLTWH(0, 0.95, 1, 0.05), // Bottom
    const Rect.fromLTWH(0, 0, 0.05, 1), // Left
    const Rect.fromLTWH(0.95, 0, 0.05, 1), // Right
    // Obstacles
    const Rect.fromLTWH(0.3, 0.4, 0.4, 0.05), // Mid plat
    const Rect.fromLTWH(0.5, 0.6, 0.05, 0.2), // Vert wall
  ];
  Offset _goalPos = const Offset(0.8, 0.8);
  
  Timer? _gameTimer;
  
  // Getters
  Offset get playerPos => _playerPos;
  double get visualRotation => _visualRotation;
  List<Rect> get walls => _walls;
  Offset get goalPos => _goalPos;
  bool get isPlaying => _isPlaying;
  @override
  int get score => _score;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _resetLevel();
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _update();
    });
    notifyListeners();
  }

  void _resetLevel() {
    _playerPos = const Offset(0.1, 0.8);
    _playerVel = Offset.zero;
    _gravityRotation = 0;
    _visualRotation = 0;
    _generateLevel();
    notifyListeners();
  }
  
  void _generateLevel() {
    final rnd = Random();
    _walls = [
        const Rect.fromLTWH(0, 0, 1, 0.02),
        const Rect.fromLTWH(0, 0.98, 1, 0.02),
        const Rect.fromLTWH(0, 0, 0.02, 1),
        const Rect.fromLTWH(0.98, 0, 0.02, 1),
    ];
    // Random simple maze
    for(int i=0; i<5; i++) {
        _walls.add(Rect.fromLTWH(rnd.nextDouble()*0.8, rnd.nextDouble()*0.8, rnd.nextBool()?0.3:0.05, rnd.nextBool()?0.05:0.3));
    }
    _goalPos = Offset(rnd.nextDouble() * 0.8 + 0.1, rnd.nextDouble() * 0.8 + 0.1);
  }

  void rotateWorld() {
    if (!_isPlaying) return;
    // Rotate 90 degrees Clockwise
    _gravityRotation += pi / 2;
    // _visualRotation handled by tween in widget usually, but let's correct logic here:
    // Actually we rotate GRAVITY vector.
    // 0: Down (0, 1)
    // PI/2: Left (-1, 0)? No, if world rotates CW, gravity relative to screen is...
    // Let's say we rotate the CAMERA.
    // If Camera rotates 90 deg CW, Gravity (which is "Down" in world) appears to point Left?
    // Let's stick to simplest: Double tap rotates Gravity Vector AND Visuals.
    // 0 -> Gravity Down
    // 90 -> Gravity Right
    // 180 -> Gravity Up
    // 270 -> Gravity Left
    notifyListeners();
  }
  
  void movePlayer(double dx, double dy) {
    // Air control / Ground movement
    // Dependent on gravity?
     _playerVel += Offset(dx * 0.002, dy * 0.002);
  }

  void _update() {
    // Determine Gravity Vector based on _gravityRotation
    // 0 = Down (0, 0.001)
    double gPower = 0.0015;
    double gx = sin(_gravityRotation) * gPower; // 0 -> 0, 90 -> 1 ... wait
    double gy = cos(_gravityRotation) * gPower; // 0 -> 1, 90 -> 0
    // Fix:
    // 0 deg: Down (0, 1)
    // 90 deg: Right (1, 0)
    // 180 deg: Up (0, -1)
    // 270 deg: Left (-1, 0)
    // Formula: dx = sin(rot), dy = cos(rot) ?? 
    // sin(0)=0, cos(0)=1 -> (0,1) OK.
    // sin(90)=1, cos(90)=0 -> (1,0) OK.
    
    Offset gravity = Offset(sin(_gravityRotation) * gPower, cos(_gravityRotation) * gPower);
    
    _playerVel += gravity;
    _playerVel *= 0.98; // Friction
    
    // Prediction for collision
    Offset nextPos = _playerPos + _playerVel;
    
    // Collision against walls
    for (var wall in _walls) {
      // A simple AABB check won't work perfectly with rotation if we rotated walls.
      // But here we rotate the VIEW and GRAVITY. The walls stay axis-aligned in DATA.
      // So Simple AABB works.
      
      Rect playerRect = Rect.fromCenter(center: nextPos, width: 0.04, height: 0.04);
      if (playerRect.overlaps(wall)) {
        // Resolve collision (Simple clamp)
        // Determine collision normal? Too complex for 'fatfat'.
        // Just Stop velocity.
        _playerVel = Offset.zero;
        // Don't update pos
        nextPos = _playerPos; 
      }
    }
    
    _playerPos = nextPos;
    
    // Check Goal
    if ((_playerPos - _goalPos).distance < 0.05) {
        _score += 10;
        _resetLevel();
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

class AxisShiftGameWidget extends StatelessWidget {
  final AxisShiftGameController controller;
  const AxisShiftGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Tween rotation
        double targetRot = controller._gravityRotation;
        
        return GestureDetector(
          onDoubleTap: controller.rotateWorld,
          onPanUpdate: (d) {
             // Move relative to rotation? simpler to just add force
             controller.movePlayer(d.delta.dx, d.delta.dy);
          },
          child: Container(
            color: Colors.grey[900],
            child: Stack(
              children: [
                // Layer that rotates
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: -targetRot), // Rotate world OPPOSITE to gravity to keep "Down" visual? 
                  // No, "The entire space rotates... what was up becomes down". 
                  // So we rotate the CONTAINER.
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutBack,
                  builder: (context, rot, child) {
                    return Transform.rotate(
                      angle: rot,
                      alignment: Alignment.center,
                      child: Stack(
                        children: [
                          // Walls
                          ...controller.walls.map((w) => Positioned(
                            left: w.left * MediaQuery.of(context).size.width,
                            top: w.top * MediaQuery.of(context).size.height,
                            width: w.width * MediaQuery.of(context).size.width,
                            height: w.height * MediaQuery.of(context).size.height,
                            child: Container(color: Colors.white24),
                          )),
                          
                          // Goal
                          Positioned(
                              left: controller.goalPos.dx * MediaQuery.of(context).size.width - 15,
                              top: controller.goalPos.dy * MediaQuery.of(context).size.height - 15,
                              child: const Icon(Icons.emergency, color: Colors.amber, size: 30),
                          ),

                          // Player
                          Positioned(
                              left: controller.playerPos.dx * MediaQuery.of(context).size.width - 10,
                              top: controller.playerPos.dy * MediaQuery.of(context).size.height - 10,
                              child: Container(width: 20, height: 20, color: Colors.cyan),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // HUD (Static)
                if (!controller.isPlaying)
                   const Center(child: Text("AXIS SHIFT\nDouble Tap to Rotate Gravity", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24))),
                   
                 Positioned(top: 40, right: 20, child: Text(controller.score.toString(), style: const TextStyle(color: Colors.white, fontSize: 32))),
              ],
            ),
          ),
        );
      },
    );
  }
}
