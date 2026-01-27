import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class ArcheryChallenge extends FlameGame with DragCallbacks, HasCollisionDetection implements MiniGame {
  late BowComponent _bow;
  ArrowComponent? _activeArrow;
  
  // ignore: prefer_final_fields
  int _score = 0;
  bool _isDragging = false;
  Vector2 _dragStart = Vector2.zero();
  Vector2 _dragCurrent = Vector2.zero();
  
  // Game State
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);

  @override
  Color backgroundColor() => const Color(0xFF2E7D32);

  @override
  Future<void> onLoad() async {
    // Add background parallex or static
    // add(SpriteComponent()..sprite = await loadSprite('archery_bg.png')..size = size); 
    
    _bow = BowComponent(position: Vector2(size.x / 2, size.y - 120));
    add(_bow);
    
    // Spawn initial target
    _spawnTarget();
    
    _reload();
  }
  
  void _spawnTarget() {
    // Top area of screen
    double x = Random().nextDouble() * (size.x - 60) + 30;
    double y = Random().nextDouble() * (size.y * 0.4) + 50; // Top 40%
    add(TargetComponent(position: Vector2(x, y)));
  }

  void _reload() {
    if (_activeArrow != null) {
      _activeArrow!.removeFromParent();
    }
    _activeArrow = ArrowComponent(position: _bow.position.clone());
    add(_activeArrow!);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_activeArrow == null || _activeArrow!.isFlying) return;
    _isDragging = true;
    _dragStart = event.localPosition;
    _dragCurrent = _dragStart;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isDragging) return;
    _dragCurrent += event.localDelta;
    final dragVector = _dragStart - _dragCurrent;
    
    // Cap drag
    if (dragVector.length > 150) {
      dragVector.normalize();
      dragVector.scale(150);
      _dragCurrent = _dragStart - dragVector;
    }

    double angle = atan2(dragVector.x, dragVector.y);
    // Limit angle clamp
    angle = angle.clamp(-pi / 3, pi / 3);
    
    _bow.angle = -angle; 
    if (_activeArrow != null) _activeArrow!.angle = -angle;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isDragging || _activeArrow == null) return;
    _isDragging = false;
    
    final dragVector = _dragStart - _dragCurrent;
    double power = dragVector.length * 12.0; // Scaled power
    
    if (dragVector.length > 20) {
       _activeArrow!.shoot(Vector2(sin(_bow.angle), -cos(_bow.angle)) * power);
       
       // Play sound effect here ideally
       
       // Reload logic is handled after arrow goes off screen or hits
    } else {
        // Cancel shot
        final effect = RotateEffect.to(0, EffectController(duration: 0.3, curve: Curves.easeOut));
        _bow.add(effect);
        if (_activeArrow != null) _activeArrow!.add(effect);
    }
  }
  
  void onArrowHit(Vector2 position, int points) {
    _score += points;
    scoreNotifier.value = _score;
    // Remove target logic is in TargetComponent or collision callback
    // Respawn target
    Future.delayed(const Duration(milliseconds: 500), _spawnTarget);
    
    // Reload quicker on hit
    Future.delayed(const Duration(milliseconds: 600), _reload);
  }
  
  void onArrowMiss() {
    // Reload after a delay
    Future.delayed(const Duration(milliseconds: 500), _reload);
  }

  @override
  int get score => _score;
  @override
  void start() => resumeEngine();
  @override
  void pause() => pauseEngine();
  @override
  void reset() {
    _score = 0;
    scoreNotifier.value = 0;
    children.whereType<TargetComponent>().forEach((t) => t.removeFromParent());
    _spawnTarget();
    resumeEngine();
  }
  @override
  void dispose() {
    scoreNotifier.dispose();
    // FlameGame handles component disposal
  }
}

class BowComponent extends PositionComponent {
  BowComponent({required Vector2 position}) : super(position: position, size: Vector2(80, 20), anchor: Anchor.center);
  
  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFF8D6E63)..style = PaintingStyle.stroke..strokeWidth = 4;
    final stringPaint = Paint()..color = Colors.white..strokeWidth = 1.5;
    
    final path = Path();
    path.moveTo(-40, 10);
    path.quadraticBezierTo(0, -30, 40, 10);
    
    canvas.drawPath(path, paint);
    canvas.drawLine(Offset(-40, 10), Offset(40, 10), stringPaint);
  }
}

class ArrowComponent extends PositionComponent with HasGameReference<ArcheryChallenge> {
  Vector2 velocity = Vector2.zero();
  bool isFlying = false;
  
  ArrowComponent({required Vector2 position}) : super(position: position, size: Vector2(6, 60), anchor: Anchor.bottomCenter);
  
  void shoot(Vector2 vel) {
    velocity = vel;
    isFlying = true;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    if (!isFlying) return;
    
    // Gravity
    velocity.y += 400 * dt;
    // Wind (optional)
    // velocity.x += 20 * dt; 
    
    position += velocity * dt;
    angle = -atan2(velocity.x, velocity.y); 
    
    // Check collisions manually for simplicity or use Hitbox
    // Simple distance check against targets
    bool hit = false;
    for (final target in game.children.whereType<TargetComponent>()) {
      if (target.containsPoint(position)) {
        int points = target.getPoints(position);
        game.onArrowHit(position, points);
        target.removeFromParent();
        removeFromParent(); // Arrow stuck
        hit = true;
        break;
      }
    }
    
    if (!hit) {
      if (position.y > game.size.y || position.x < 0 || position.x > game.size.x || position.y < -200) {
        game.onArrowMiss();
        removeFromParent();
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    final shaftPaint = Paint()..color = Colors.grey.shade300..strokeWidth = 3;
    final tipPaint = Paint()..color = Colors.grey.shade700;
    final featherPaint = Paint()..color = Colors.redAccent;

    // Shaft
    canvas.drawLine(Offset(size.x/2, 0), Offset(size.x/2, size.y), shaftPaint);
    
    // Tip
    final tipPath = Path();
    tipPath.moveTo(size.x/2 - 4, 0);
    tipPath.lineTo(size.x/2 + 4, 0);
    tipPath.lineTo(size.x/2, -10);
    tipPath.close();
    canvas.drawPath(tipPath, tipPaint);
    
    // Feathers
    canvas.drawRect(Rect.fromLTWH(0, size.y - 15, 2, 10), featherPaint);
    canvas.drawRect(Rect.fromLTWH(size.x - 2, size.y - 15, 2, 10), featherPaint);
  }
}

class TargetComponent extends PositionComponent {
  // Movement
  double speed = 80;
  int direction = 1;
  
  TargetComponent({required Vector2 position}) : super(position: position, size: Vector2(60, 60), anchor: Anchor.center) {
    if (Random().nextBool()) direction = -1;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    x += speed * direction * dt;
    // Bounce off walls
    if (x < size.x/2 || x > (parent as FlameGame).size.x - size.x/2) {
      direction *= -1;
    }
  }
  
  @override
  void render(Canvas canvas) {
    final center = Offset(size.x/2, size.y/2);
    double radius = size.x / 2;
    
    final colors = [Colors.red, Colors.white, Colors.red, Colors.white, Colors.red];
    for (int i = 0; i < 5; i++) {
        canvas.drawCircle(center, radius * (5-i)/5, Paint()..color = colors[i]);
    }
  }
  
  @override
  bool containsPoint(Vector2 point) {
    return position.distanceTo(point) < size.x/2;
  }
  
  int getPoints(Vector2 point) {
    double dist = position.distanceTo(point);
    double maxDist = size.x/2;
    
    if (dist < maxDist * 0.2) return 50; // Bullseye
    if (dist < maxDist * 0.5) return 20;
    return 10;
  }
}
