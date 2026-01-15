import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class UntetheredGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // Physics (Zero Friction)
  Offset _playerPos = const Offset(0.5, 0.5);
  Offset _playerVel = Offset.zero;
  double _playerRotation = 0;
  
  // Particles
  List<Particle> _particles = [];
  
  // Game Objects (Floating Debris/Coins)
  List<Offset> _coins = [];
  final Random _rnd = Random();
  Timer? _gameTimer;
  
  // Constants
  static const double recoilPower = 0.003;
  static const double maxSpeed = 0.02;
  static const double rotationSpeed = 0.1;

  Offset get playerPos => _playerPos;
  double get playerRotation => _playerRotation;
  List<Particle> get particles => _particles;
  List<Offset> get coins => _coins;
  bool get isPlaying => _isPlaying;
  int get score => _score;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _resetGame();
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _update();
    });
    notifyListeners();
  }
  
  void _resetGame() {
    _playerPos = const Offset(0.5, 0.5);
    _playerVel = Offset.zero;
    _playerRotation = 0;
    _particles = [];
    _coins = [];
    _spawnCoins(3);
  }
  
  void _spawnCoins(int count) {
    for (int i = 0; i < count; i++) {
      _coins.add(Offset(_rnd.nextDouble(), _rnd.nextDouble()));
    }
  }

  void thrust() {
    if (!_isPlaying) return;
    
    // Check if player tapped behind (in Logic, user interface calls this)
    // Actually, simple control: Tap launches propulsion BEHIND player
    // So player moves FORWARD (direction they are facing or user tap determines facing?)
    // Let's go with: Tap creates an explosion at tap location.
    // Player is pushed AWAY from tap.
  }
  
  void applyForce(Offset tapPos) {
    if (!_isPlaying) return;
    
    // Logic: Propulsion moves player AWAY from tap
    // Vector from Tap to Player
    Offset direction = _playerPos - tapPos;
    double distance = direction.distance;
    
    if (distance < 0.01) distance = 0.01; // prevent div/0
    
    // Normalize and Apply
    Offset force = direction / distance * recoilPower;
    _playerVel += force;
    
    // Cap Speed
    double speed = _playerVel.distance;
    if (speed > maxSpeed) {
      _playerVel = _playerVel / speed * maxSpeed;
    }
    
    // Rotate to face velocity
    if (_playerVel.distance > 0.001) {
       _playerRotation = atan2(_playerVel.dy, _playerVel.dx);
    }
    
    // Spawn Particles at tap position (propulsion)
    for(int i=0; i<5; i++) {
      _particles.add(Particle(
        pos: tapPos,
        vel: -force * (2.0 + _rnd.nextDouble()), // Particles fly opposite to force (towards tap source)
        life: 1.0,
      ));
    }
    
    notifyListeners();
  }

  void _update() {
    // Movement (Inertia - no friction)
    _playerPos += _playerVel;
    
    // Screen Wrap (Void topology)
    if (_playerPos.dx < 0) _playerPos = Offset(1.0, _playerPos.dy);
    if (_playerPos.dx > 1.0) _playerPos = Offset(0.0, _playerPos.dy);
    if (_playerPos.dy < 0) _playerPos = Offset(_playerPos.dx, 1.0);
    if (_playerPos.dy > 1.0) _playerPos = Offset(_playerPos.dx, 0.0);
    
    // Particles
    _particles.removeWhere((p) {
      p.pos += p.vel;
      p.life -= 0.05;
      return p.life <= 0;
    });
    
    // Coin Collection
    // Use reverse loop to remove safely
    for (int i = _coins.length - 1; i >= 0; i--) {
      if ((_playerPos - _coins[i]).distance < 0.05) {
        _coins.removeAt(i);
        _score += 10;
        // Effect
      }
    }
    
    if (_coins.isEmpty) _spawnCoins(3);
    
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
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

class Particle {
  Offset pos;
  Offset vel;
  double life;
  Particle({required this.pos, required this.vel, required this.life});
}

class UntetheredGameWidget extends StatelessWidget {
  final UntetheredGameController controller;

  const UntetheredGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (details) {
            // Convert to 0-1
            double x = details.localPosition.dx / MediaQuery.of(context).size.width;
            double y = details.localPosition.dy / MediaQuery.of(context).size.height;
            controller.applyForce(Offset(x, y));
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // Starfield Background
                CustomPaint(
                  painter: StarFieldPainter(),
                  size: Size.infinite,
                ),
                
                 if (!controller.isPlaying)
                   Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Text(
                           "THE UNTETHERED",
                           style: TextStyle(
                             color: Colors.white,
                             fontSize: 24,
                             fontWeight: FontWeight.bold,
                             letterSpacing: 4,
                           ),
                         ),
                         const SizedBox(height: 10),
                         Text(
                           "Tap BEHIND to push forward.\nZero Friction. Inertia is key.",
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             color: Colors.white.withOpacity(0.6),
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

                // Coins
                ...controller.coins.map((c) => Positioned(
                  left: c.dx * MediaQuery.of(context).size.width - 10,
                  top: c.dy * MediaQuery.of(context).size.height - 10,
                  child: const Icon(Icons.circle, color: Colors.yellowAccent, size: 20),
                )),
                
                // Particles
                ...controller.particles.map((p) => Positioned(
                  left: p.pos.dx * MediaQuery.of(context).size.width,
                  top: p.pos.dy * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 4, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(p.life),
                      shape: BoxShape.circle,
                    ),
                  ),
                )),
                
                // Player
                Positioned(
                  left: controller.playerPos.dx * MediaQuery.of(context).size.width - 15,
                  top: controller.playerPos.dy * MediaQuery.of(context).size.height - 15,
                  child: Transform.rotate(
                    angle: controller.playerRotation,
                    child: const Icon(Icons.navigation, color: Colors.white, size: 30),
                  ),
                ),
                
                // Score
                Positioned(
                  top: 40,
                  left: 20,
                  child: Text(
                    controller.score.toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 32,
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

class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42); // Fixed seed
    final paint = Paint()..color = Colors.white54;
    for(int i=0; i<50; i++) {
      canvas.drawCircle(
        Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height),
        rand.nextDouble() * 2,
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
