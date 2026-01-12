import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class PrecisionTargetController extends ChangeNotifier implements MiniGame {
  int _score = 0;
  bool _active = false;
  @override
  int get score => _score;
  @override
  void start() { _active = true; notifyListeners(); }
  @override
  void pause() { _active = false; notifyListeners(); }
  @override
  void reset() { _score = 0; notifyListeners(); }
  @override
  void dispose() { super.dispose(); }
  void addScore(int points) { _score += points; notifyListeners(); }
  bool get isActive => _active;
}

class PrecisionTargetWidget extends StatefulWidget {
  final PrecisionTargetController controller;
  const PrecisionTargetWidget({super.key, required this.controller});
  @override
  State<PrecisionTargetWidget> createState() => _PrecisionTargetWidgetState();
}

class _PrecisionTargetWidgetState extends State<PrecisionTargetWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  List<_Target> _targets = [];
  Timer? _spawner;
  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _ticker.addListener(_update);
    _spawner = Timer.periodic(const Duration(milliseconds: 1500), (_) => _spawnTarget());
  }
  void _spawnTarget() {
    if (!widget.controller.isActive || !mounted) return;
    setState(() {
      _targets.add(_Target(
        x: Random().nextDouble() * MediaQuery.of(context).size.width,
        y: Random().nextDouble() * (MediaQuery.of(context).size.height * 0.6) + 100,
        radius: Random().nextDouble() * 30 + 20,
        speedX: (Random().nextDouble() - 0.5) * 4,
        speedY: (Random().nextDouble() - 0.5) * 4,
      ));
    });
  }
  void _update() {
    if (!widget.controller.isActive) return;
    setState(() {
      for (var t in _targets) {
        t.x += t.speedX; t.y += t.speedY;
        if (t.x < 0 || t.x > MediaQuery.of(context).size.width) t.speedX *= -1;
        if (t.y < 0 || t.y > MediaQuery.of(context).size.height) t.speedY *= -1;
        t.life -= 0.005;
      }
      _targets.removeWhere((t) => t.life <= 0 || t.hit);
    });
  }
  void _handleTap(TapDownDetails details) {
    if (!widget.controller.isActive) return;
    final pos = details.localPosition;
    for (var t in _targets) {
      if (sqrt(pow(pos.dx - t.x, 2) + pow(pos.dy - t.y, 2)) < t.radius) {
        t.hit = true;
        widget.controller.addScore(100);
        break; 
      }
    }
  }
  @override
  void dispose() { _ticker.dispose(); _spawner?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTapDown: _handleTap, child: Container(color: Colors.black, child: CustomPaint(painter: _TargetPainter(_targets), size: Size.infinite)));
  }
}

class _Target {
  double x, y, radius, speedX, speedY;
  double life = 1.0;
  bool hit = false;
  _Target({required this.x, required this.y, required this.radius, this.speedX=0, this.speedY=0});
}

class _TargetPainter extends CustomPainter {
  final List<_Target> targets;
  _TargetPainter(this.targets);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var t in targets) {
      paint.color = Colors.redAccent.withOpacity(t.life);
      canvas.drawCircle(Offset(t.x, t.y), t.radius, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
