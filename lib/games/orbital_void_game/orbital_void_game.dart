import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class OrbitalVoidGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // Game State
  double _worldRotation = 0;
  List<Asteroid> _asteroids = [];
  Timer? _gameTimer;
  Timer? _spawnTimer;
  
  double get worldRotation => _worldRotation;
  List<Asteroid> get asteroids => _asteroids;
  bool get isPlaying => _isPlaying;
  int get score => _score;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _worldRotation = 0;
    _asteroids = [];
    
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _update();
    });
    
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (_isPlaying) _spawnAsteroid();
    });
    notifyListeners();
  }
  
  void _spawnAsteroid() {
    // Spawn at radius 1.5 (outside screen usually) at random angle
    double angle = Random().nextDouble() * 2 * pi;
    _asteroids.add(Asteroid(
      angle: angle,
      distance: 1.5,
      speed: 0.005 + (_score * 0.0001), // Speed increases with score
    ));
  }

  void rotateWorld(double delta) {
    if (!_isPlaying) return;
    // Rotate the UNIVERSE, not the player
    _worldRotation += delta * 2.0; // Sensitivity
    notifyListeners();
  }

  void _update() {
    _score++; // Survival score
    
    // Update Asteroids
    for (var a in _asteroids) {
      a.distance -= a.speed;
    }
    
    // Check Collision
    // Player is at (0.5, 0.5) screen coords, or (0,0) polar.
    // Asteroid hits if distance < 0.1 approx
    for (var a in _asteroids) {
      if (a.distance < 0.1) {
        // Check angle match? No, they come to CENTER.
        // Wait, if they come to center, rotation doesn't matter unless...
        // Ah, the mechanic: "Objects drift toward the side... avoid them"
        // Let's refine: Objects fall "Down" relative to the screen, but rotating the world changes where they are.
        // OR: Objects come from specific absolute angles, and we rotate a SHIELD?
        // Let's go with: Player has a Gap in a Shield.
        // OR: Player is in orbit.
        
        // Re-read Design: "Avoid incoming asteroids... rotate the world so asteroid misses"
        // This implies the player is NOT a single point but has a shape/orientation?
        // Let's say Player is a Moon orbiting a Planet. 
        // No, player is Center. Asteroids spiral in.
        // If Asteroid hits center, Game Over.
        // BUT how does rotating help?
        // Maybe Player is a "C" shape shield?
        // Yes! Player is a shield at radius 0.1.
        // Rotating the world rotates the asteroids RELATIVE to the shield.
        // No, Rotating the world rotates the world. The shield is fixed on screen?
        // Let's say Shield is fixed DOWN. Rotating world moves asteroids.
        
        // If asteroid angle relative to world rotation aligns with Shield Gap -> Safe
        // If aligns with Shield -> Blocked/Score?
        // Let's play "Avoid": Player is a point on the rim of a circle.
        // Asteroids fall towards the circle. Rotating moves the player along the rim? NO, prompt says rotate UNIVERSE.
        
        // Revised Logic:
        // Player is fixed at Bottom of screen (Polar: distance 0.8, angle PI/2).
        // Asteroids exist in World Space.
        // Rotating World changes Asteroid's screen angle.
        // Asteroid falls towards Center (0,0).
        // If Asteroid passes through Player's radius at Player's angle -> Collision.
        
        // Actually simplest: Player is a dot at (0, 0.3) [Screen relative center offset]
        // World rotates around center.
        // Asteroids are static in world, but player moves through them?
        
        // Let's stick to "Orbital Void" description: "Circle of objects... rotating universe... avoid incoming".
        // Player is fixed at Center.
        // Objects come in.
        // There is a "Safe Zone" cone?
        // Let's make Player a Triangle pointing UP.
        // Asteroids fall from Top? No that's normal.
        
        // Let's try: Player is a small planet. 
        // Asteroids fall towards it.
        // Player has a Turret/Shield fixed UP.
        // You rotate the world to align Asteroids with the Turret to destroy them.
        // If they hit the planet elsewhere -> Damage.
        
        // Logic:
        // Player Shield is at Angle 0 (Up).
        // Asteroid is at `a.angle`.
        // Relative Angle = `a.angle + worldRotation`.
        // If `a.distance < 0.2` (Planet Surface):
        //   If `Relative Angle` is close to 0 (Shield): Destroy (Score +100).
        //   Else: Game Over.
        
        double relativeAngle = (a.angle + _worldRotation) % (2 * pi);
        if (relativeAngle < 0) relativeAngle += 2 * pi;
        
        // Shield is at -PI/2 (Up in Flutter coords is -PI/2? No, 0 is Right normally. Let's assume standard unit circle)
        // Let's render Shield at TOP.
        // If Flutter Canvas, 0 is Right, PI/2 is Down, -PI/2 is Up.
        
        double diff = (relativeAngle + pi/2).abs(); // Diff from Up
        // Normalize diff
        if (diff > pi) diff = 2*pi - diff;
        
        if (diff < 0.4) { // Shield Width
           a.distance = 100; // Remove
           _score += 500;
        } else {
           _isPlaying = false; // Hit planet
        }
      }
    }
    
    _asteroids.removeWhere((a) => a.distance > 50); // Removed ones
    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    notifyListeners();
  }

  @override
  void reset() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    start();
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }
}

class Asteroid {
  double angle; // In World Space
  double distance; // 0..1+
  double speed;
  Asteroid({required this.angle, required this.distance, required this.speed});
}

class OrbitalVoidGameWidget extends StatelessWidget {
  final OrbitalVoidGameController controller;

  const OrbitalVoidGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: (details) {
             // Swipe L/R rotates world
             controller.rotateWorld(details.delta.dx * 0.01);
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // Instructions
                 if (!controller.isPlaying)
                   Center(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Text(
                           "ORBITAL VOID",
                           style: TextStyle(
                             color: Colors.purpleAccent,
                             fontSize: 24,
                             fontWeight: FontWeight.bold,
                             letterSpacing: 4,
                           ),
                         ),
                         const SizedBox(height: 10),
                         Text(
                           "Swipe to Rotate Reality.\nCatch meteors with your Shield (Top).",
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
                   )
                 else
                   Positioned.fill(
                     child: GestureDetector(
                       behavior: HitTestBehavior.translucent,
                        onTap: () {
                          // Allow tap to start logic to propagate if needed, 
                          // but restart is handled via overlay usually or logic
                        }, 
                        child: CustomPaint(
                          painter: VoidPainter(
                            rotation: controller.worldRotation,
                            asteroids: controller.asteroids,
                          ),
                        ),
                     ),
                   ),

                // Start Button overlay helper if needed
                if (!controller.isPlaying)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: controller.start,
                      behavior: HitTestBehavior.translucent,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  
                // Score
                Positioned(
                  top: 40,
                  right: 20,
                  child: Text(
                    controller.score.toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
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

class VoidPainter extends CustomPainter {
  final double rotation;
  final List<Asteroid> asteroids;
  
  VoidPainter({required this.rotation, required this.asteroids});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.4;
    
    // Draw Planet (Player)
    final planetPaint = Paint()..color = Colors.purple.shade900;
    canvas.drawCircle(center, 40, planetPaint);
    
    // Draw Shield (Fixed Up)
    final shieldPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
      
    // Arc at top (-PI/2)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 50),
      -pi / 2 - 0.4, // Start
      0.8, // Sweep
      false,
      shieldPaint,
    );
    
    // Draw Asteroids (Rotated by World Rotation)
    final asteroidPaint = Paint()..color = Colors.redAccent;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation); // Rotate the universe context
    
    for (var a in asteroids) {
      if (a.distance > 50) continue; // Dead
      
      // Convert Polar to Cartesian
      // Distance is normalized radius (1.0 = screen width?? No, logic said 0.1 collision)
      // Let's map distance 1.5 -> Screen edge
      double r = a.distance * size.width * 0.6;
      double x = r * cos(a.angle);
      double y = r * sin(a.angle);
      
      canvas.drawCircle(Offset(x, y), 8, asteroidPaint);
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
