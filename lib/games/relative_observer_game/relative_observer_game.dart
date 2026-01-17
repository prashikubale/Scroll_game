import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class RelativeObserverGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // State: 0 = Player Moves, 1 = World Moves
  // BUT the visual feedback must be identical: relative velocity.
  bool _controlsWorld = false; 
  
  Offset _playerPos = const Offset(0.5, 0.5); // Screen Coords
  Offset _worldOffset = Offset.zero; // For scrolling background
  Offset _playerVel = Offset.zero;
  
  final List<Offset> _stars = []; // Parallax stars
  Offset _dockPos = const Offset(0.0, -0.5); // Relative position
  
  Timer? _gameTimer;
  Timer? _modeSwapTimer;
  final Random _rnd = Random();

  bool get isPlaying => _isPlaying;
  Offset get playerPos => _playerPos;
  Offset get dockPos => _dockPos;
  List<Offset> get stars => _stars;
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
    
    _modeSwapTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if(_isPlaying) {
            _controlsWorld = !_controlsWorld; // Swap physics rule silently 
            // Optional: Subtle gltich effect?
        }
    });
    
    notifyListeners();
  }

  void _reset() {
    _playerPos = const Offset(0.5, 0.5);
    _worldOffset = Offset.zero;
    _playerVel = Offset.zero;
    _controlsWorld = false;
    _spawnStars();
    _spawnDock();
  }
  
  void _spawnStars() {
    _stars.clear();
    for(int i=0; i<100; i++) {
        _stars.add(Offset(_rnd.nextDouble() * 2 - 1, _rnd.nextDouble() * 2 - 1));
    }
  }
  
  void _spawnDock() {
    _dockPos = Offset(_rnd.nextDouble() * 1.5 - 0.75, _rnd.nextDouble() * 1.5 - 0.75);
  }

  void input(double dx, double dy) {
    if(!_isPlaying) return;
    
    // Input is THRUST.
    // If Player Controls: Adds velocity to Player.
    // If World Controls: Adds velocity to World (Inverse).
    
    Offset thrust = Offset(dx, dy) * 0.001;
    
    if (_controlsWorld) {
        // We are moving the UNIVERSE globally.
        // Actually, to make "Visuals Identical", moving player Right = Stars go Left.
        // Moving World Left = Stars go Left.
        // The difference is MOMENTUM persistence.
        // If Player Moves: Player has inertia.
        // If World Moves: World has inertia.
        // Visually: 
        // Case A: Player moves. Player screen pos changes? No, Camera follows??
        // Game Design: "Am I moving or everything else?"
        // Let's fix Player to Center visibly. 
        // Then EVERYTHING moves relative to center.
        // BUT logic changes:
        // Case A (Player): Player Vel += Thrust. World Offset -= Player Vel.
        // Case B (World): World Vel += Thrust (Inverse). World Offset += World Vel.
        // Is there a difference?
        // Relativistically NO. F=ma. 
        // UNLESS... Density/Drag differs? Or boundaries?
        // Ah, "Inertia".
        // Let's make it so:
        // Mode A: High Inertia (Space ship).
        // Mode B: Zero Inertia (Direct Cam Control).
        // That creates a "Feel" difference.
        
        // Let's implement EXACT relative motion.
        // Player is ALWAYS center (0.5, 0.5).
        // We track _relativeWorldVel.
        
        // The TRICK:
        // When ControlsWorld = true, Input directly translates position (God Mode/cam pan).
        // When ControlsWorld = false, Input adds Force (Thruster physics).
        
        if (_controlsWorld) {
             // Direct Move (No inertia, stops when no input)
             // Or maybe just HIGH drag.
             _playerVel = thrust * 50; 
        } else {
             // Newtonian
             _playerVel += thrust;
        }
    } else {
        // Normal Newtonian
         _playerVel += thrust;
    }
  }

  void _update() {
    // Only one update logic: Move World based on Relative Vel.
    // Actually, let's simplify for the "Brain Teaser":
    // The "Goal" is fixed to the Background.
    // WE need to align Player (Center) with Goal.
    
    // Update World Offset
    // If _controlsWorld (God Move), velocity decays instantly if no input?
    if (_controlsWorld) {
        _playerVel *= 0.8; // High friction
    } 
    // If Player (Ship), velocity persists
    
    _worldOffset -= _playerVel;
    
    // Check Docking
    // Player is at (0,0) relative to world offset?
    // Dock pos is world-relative.
    // Distance check:
    // Screen Center = WorldOffset + PlayerPos?? 
    // Let's say WorldOffset is the camera position.
    // Dock is at _dockPos (absolute world coords).
    // Player is at WorldOffset (Camera center).
    
    double dist = (_worldOffset - _dockPos).distance;
    if (dist < 0.1) {
        if (_playerVel.distance < 0.01) { // must stop to dock
            _score += 100;
            _spawnDock();
            _playerVel = Offset.zero;
        }
    }
    
    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _modeSwapTimer?.cancel();
    notifyListeners();
  }
  @override
  void reset() => start();
  @override
  void dispose() { 
    _gameTimer?.cancel(); 
    _modeSwapTimer?.cancel(); 
    super.dispose(); 
  }
}

class RelativeObserverGameWidget extends StatelessWidget {
  final RelativeObserverGameController controller;
  const RelativeObserverGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: (d) {
             controller.input(d.delta.dx, d.delta.dy);
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // Starfield (Moves with WorldOffset)
                // Use modulo for infinite scroll
                ...controller.stars.map((s) {
                    // Parallax/Scroll
                    double x = (s.dx - controller._worldOffset.dx) % 2.0; 
                    double y = (s.dy - controller._worldOffset.dy) % 2.0;
                    if (x > 1) x -= 2; if (x < -1) x += 2;
                    if (y > 1) y -= 2; if (y < -1) y += 2;
                    // Map -1..1 to Screen
                    double sx = (x + 1)/2 * MediaQuery.of(context).size.width;
                    double sy = (y + 1)/2 * MediaQuery.of(context).size.height;
                    return Positioned(
                        left: sx, top: sy,
                        child: Container(width: 2, height: 2, color: Colors.white),
                    );
                }),
                
                // Docking Target
                Builder(builder: (ctx) {
                    double dx = (controller.dockPos.dx - controller._worldOffset.dx);
                    double dy = (controller.dockPos.dy - controller._worldOffset.dy);
                    // Map center
                    double sx = dx * MediaQuery.of(context).size.width + MediaQuery.of(context).size.width/2;
                    double sy = dy * MediaQuery.of(context).size.height + MediaQuery.of(context).size.height/2;
                    
                    return Positioned(
                        left: sx - 20, top: sy - 20,
                        child: Container(
                            width: 40, height: 40, 
                            decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 2), shape: BoxShape.circle),
                            child: const Center(child: Text("DOCK", style: TextStyle(color: Colors.green, fontSize: 8))),
                        ),
                    );
                }),

                // Player (Fixed Center)
                Center(
                    child: Container(
                        width: 30, height: 30,
                        decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket, color: Colors.white, size: 20),
                    ),
                ),
                
                 if (!controller.isPlaying)
                   const Center(child: Text("THE RELATIVE OBSERVER\nSwipe to Thrust. Stop on Dock.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24))),
                   
                 Positioned(top: 40, left: 20, child: Text(controller.score.toString(), style: const TextStyle(color: Colors.white, fontSize: 32))),
              ],
            ),
          ),
        );
      },
    );
  }
}
