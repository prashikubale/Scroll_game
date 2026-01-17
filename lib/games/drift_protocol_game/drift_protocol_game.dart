import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class DriftProtocolGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // Simulation Board (0.0 to 1.0)
  final List<DriftParticle> _particles = [];
  DriftParticle? _keyParticle;
  Offset _destinationZone = const Offset(0.9, 0.9); // Bottom Right
  
  // User Inputs
  final List<FieldModifier> _modifiers = [];
  
  Timer? _gameTimer;
  final Random _rnd = Random();
  
  // Getters
  List<DriftParticle> get particles => _particles;
  DriftParticle? get keyParticle => _keyParticle;
  List<FieldModifier> get modifiers => _modifiers;
  Offset get destinationZone => _destinationZone;
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
    _modifiers.clear();
    _particles.clear();
    
    // Spawn Swarm at Top Left
    for (int i = 0; i < 50; i++) {
        _particles.add(DriftParticle(
          pos: Offset(_rnd.nextDouble() * 0.2, _rnd.nextDouble() * 0.2),
          vel: Offset(_rnd.nextDouble() * 0.005 + 0.002, _rnd.nextDouble() * 0.005 + 0.002),
          isKey: false,
          color: Colors.white.withValues(alpha: 0.3),
        ));
    }
    
    // Spawn Key Particle
    _keyParticle = DriftParticle(
      pos: const Offset(0.1, 0.1),
      vel: const Offset(0.005, 0.005),
      isKey: true,
      color: Colors.cyanAccent,
      size: 6.0,
    );
    _particles.add(_keyParticle!);
    
    // Random Destination
    double destX = _rnd.nextBool() ? 0.9 : 0.1;
    double destY = _rnd.nextBool() ? 0.9 : 0.1;
    // Ensure destination isn't spawn
    if (destX < 0.3 && destY < 0.3) destX = 0.9;
    _destinationZone = Offset(destX, destY);
  }

  void addModifier(Offset pos, ModifierType type) {
    if (!_isPlaying) return;
    // Limit modifiers?
    if (_modifiers.length > 5) _modifiers.removeAt(0);
    _modifiers.add(FieldModifier(pos: pos, type: type, life: 1.0));
    notifyListeners();
  }

  void _update() {
    // Current Flow Field (Default Drift: slightly down-right but chaotic)
    Offset globalFlow = const Offset(0.001, 0.001);

    // Update Modifiers
    for (var m in _modifiers) {
      m.life -= 0.005;
    }
    _modifiers.removeWhere((m) => m.life <= 0);

    // Update Particles
    for (var p in _particles) {
      // Base Inertia + Global Flow
      p.vel += globalFlow * 0.1;

      // Interaction with Modifiers
      for (var m in _modifiers) {
        double dist = (p.pos - m.pos).distance;
        if (dist < m.radius) {
          if (m.type == ModifierType.densityWell) {
            // Slow down (Density)
            p.vel *= 0.90;
          } else if (m.type == ModifierType.repulsionField) {
            // Push away
            Offset dir = (p.pos - m.pos) / dist;
            p.vel += dir * 0.001; 
          }
        }
      }
      
      // Apply Velocity
      p.pos += p.vel;
      
      // Bounce off walls
      if (p.pos.dx < 0 || p.pos.dx > 1.0) {
        p.vel = Offset(-p.vel.dx, p.vel.dy);
        p.pos = Offset(p.pos.dx.clamp(0.0, 1.0), p.pos.dy);
      }
      if (p.pos.dy < 0 || p.pos.dy > 1.0) {
        p.vel = Offset(p.vel.dx, -p.vel.dy);
        p.pos = Offset(p.pos.dx, p.pos.dy.clamp(0.0, 1.0));
      }
      
      // Check Win Condition (Key Particle in Zone)
      if (p.isKey) {
        if ((p.pos - _destinationZone).distance < 0.1) {
          _score += 100;
          _resetLevel(); // Next Level
          break; // Stop processing this frame
        }
      }
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
  void reset() {
    start();
  }
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

enum ModifierType { densityWell, repulsionField }

class DriftParticle {
  Offset pos;
  Offset vel;
  bool isKey;
  Color color;
  double size;

  DriftParticle({
    required this.pos,
    required this.vel,
    required this.isKey,
    required this.color,
    this.size = 3.0,
  });
}

class FieldModifier {
  Offset pos;
  ModifierType type;
  double life; // 1.0 to 0.0
  double radius = 0.15;
  
  FieldModifier({required this.pos, required this.type, required this.life});
}

class DriftProtocolGameWidget extends StatelessWidget {
  final DriftProtocolGameController controller;

  const DriftProtocolGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (details) {
             final pos = _getRelPos(context, details.localPosition);
             controller.addModifier(pos, ModifierType.densityWell);
          },
          onLongPressStart: (details) {
             final pos = _getRelPos(context, details.localPosition);
             controller.addModifier(pos, ModifierType.repulsionField);
          },
          child: Container(
            color: const Color(0xFF05101A), // Deep Ocean/Space Blue
            child: Stack(
              children: [
                // Instructions / HUD
                if (!controller.isPlaying)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         const Text("THE DRIFT PROTOCOL", style: TextStyle(color: Colors.cyan, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                         const SizedBox(height: 10),
                         Text("Tap: Place Density Well (Slow)\nHold: Place Repulsor (Push)\nGuide the Cyan Particle.",
                           textAlign: TextAlign.center,
                           style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                         ),
                         const SizedBox(height: 20),
                         const Text("TAP TO INITIALIZE", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),

                // Destination Zone
                Positioned(
                  left: controller.destinationZone.dx * MediaQuery.of(context).size.width - 40,
                  top: controller.destinationZone.dy * MediaQuery.of(context).size.height - 40,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 2),
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                    ),
                    child: const Center(child: Icon(Icons.flag, color: Colors.greenAccent)),
                  ),
                ),

                // Modifiers
                ...controller.modifiers.map((m) {
                   final px = m.pos.dx * MediaQuery.of(context).size.width;
                   final py = m.pos.dy * MediaQuery.of(context).size.height;
                   final rad = m.radius * MediaQuery.of(context).size.width; // Approximation
                   return Positioned(
                     left: px - rad,
                     top: py - rad,
                     child: Container(
                       width: rad * 2,
                       height: rad * 2,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         color: m.type == ModifierType.densityWell 
                             ? Colors.blue.withValues(alpha: 0.3 * m.life)
                             : Colors.orange.withValues(alpha: 0.3 * m.life),
                         border: Border.all(
                            color: m.type == ModifierType.densityWell ? Colors.blue : Colors.orange,
                            width: 1,
                         ),
                       ),
                     ),
                   );
                }),

                // Particles
                CustomPaint(
                  painter: ParticleSwarmPainter(controller.particles),
                  size: Size.infinite,
                ),

                // Score
                Positioned(
                  top: 40, right: 20,
                  child: Text(controller.score.toString(), style: const TextStyle(color: Colors.white24, fontSize: 32)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Offset _getRelPos(BuildContext context, Offset local) {
    final size = MediaQuery.of(context).size;
    return Offset(local.dx / size.width, local.dy / size.height);
  }
}

class ParticleSwarmPainter extends CustomPainter {
  final List<DriftParticle> particles;
  ParticleSwarmPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      canvas.drawCircle(
        Offset(p.pos.dx * size.width, p.pos.dy * size.height), 
        p.size, 
        paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
