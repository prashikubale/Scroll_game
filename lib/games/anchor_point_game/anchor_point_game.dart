import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class AnchorPointGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  
  // Physics
  Offset _playerPos = const Offset(0.5, 0.5);
  Offset _playerVel = const Offset(0.005, 0.0);
  
  final List<Offset> _nodes = [];
  Offset? _anchoredNode;
  
  Timer? _gameTimer;
  final Random _rnd = Random();
  
  Offset get playerPos => _playerPos;
  List<Offset> get nodes => _nodes;
  Offset? get anchoredNode => _anchoredNode;
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
    _playerVel = const Offset(0.008, 0.0); // Initial speed
    _anchoredNode = null;
    _nodes.clear();
    _spawnNodes();
  }
  
  void _spawnNodes() {
    for(int i=0; i<10; i++) {
        _nodes.add(Offset(_rnd.nextDouble(), _rnd.nextDouble()));
    }
  }

  void anchor(Offset? node) {
    if (!_isPlaying) return;
    _anchoredNode = node;
    notifyListeners();
  }

  void _update() {
    if (_anchoredNode != null) {
      // Swing Physics (Centripetal)
      Offset toNode = _anchoredNode! - _playerPos;
      double dist = toNode.distance;
      if (dist > 0.001) {
          // Gravity towards node
          Offset gravity = toNode / dist * 0.001; // Pull strength
          _playerVel += gravity;
          
          // Damping (Drag) to prevent infinite orbit
          _playerVel *= 0.995;
      }
    } else {
        // Free Fall? No, Drift.
        // Maybe slight gravity down? Or zero G as per description.
        // "There is no global gravity. Gravity only exists towards the node..."
        // So drift linearly.
    }
    
    _playerPos += _playerVel;
    
    // Bounds: Wrap
    if (_playerPos.dx < 0) _playerPos = Offset(1, _playerPos.dy);
    if (_playerPos.dx > 1) _playerPos = Offset(0, _playerPos.dy);
    if (_playerPos.dy < 0) _playerPos = Offset(_playerPos.dx, 1);
    if (_playerPos.dy > 1) _playerPos = Offset(_playerPos.dx, 0);
    
    // Score based on speed/airtime?
    // Let's spawn collectables? 
    // Or just "Survival" (don't hit edges if not wrap)?
    // Prompt: "Goal: Sling object toward next node."
    // Let's award points for passing NEAR nodes without hitting them?
    // Or catching new nodes.
    _score++;
    
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

class AnchorPointGameWidget extends StatelessWidget {
  final AnchorPointGameController controller;
  const AnchorPointGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onLongPressStart: (d) {
             // Find nearest node within range
             final tapRel = Offset(d.localPosition.dx / MediaQuery.of(context).size.width, d.localPosition.dy / MediaQuery.of(context).size.height);
             
             Offset? bestNode;
             double bestDist = 0.2; // Max grab range
             
             for(var node in controller.nodes) {
                 double dist = (node - tapRel).distance;
                 if(dist < bestDist) {
                     bestDist = dist;
                     bestNode = node;
                 }
             }
             if (bestNode != null) {
                 controller.anchor(bestNode);
             }
          },
          onLongPressEnd: (d) {
              controller.anchor(null);
          },
          child: Container(
            color: const Color(0xFF1A051A), // Dark Purple
            child: Stack(
              children: [
                // Tether Line
                if (controller.anchoredNode != null)
                   CustomPaint(
                       painter: TetherPainter(start: controller.playerPos, end: controller.anchoredNode!),
                       size: Size.infinite,
                   ),
                   
                // Nodes
                ...controller.nodes.map((n) => Positioned(
                    left: n.dx * MediaQuery.of(context).size.width - 8,
                    top: n.dy * MediaQuery.of(context).size.height - 8,
                    child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                            color: Colors.pinkAccent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.5), blurRadius: 10)]
                        ),
                    ),
                )),
                
                // Player
                Positioned(
                    left: controller.playerPos.dx * MediaQuery.of(context).size.width - 10,
                    top: controller.playerPos.dy * MediaQuery.of(context).size.height - 10,
                    child: Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                        ),
                    ),
                ),
                
                if (!controller.isPlaying)
                   const Center(child: Text("ANCHOR POINT\nHold Node to Swing.\nRelease to Sling.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24))),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TetherPainter extends CustomPainter {
    final Offset start;
    final Offset end;
    TetherPainter({required this.start, required this.end});
    @override
    void paint(Canvas canvas, Size size) {
        final p1 = Offset(start.dx * size.width, start.dy * size.height);
        final p2 = Offset(end.dx * size.width, end.dy * size.height);
        canvas.drawLine(p1, p2, Paint()..color = Colors.white..strokeWidth = 2);
    }
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
