
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class JumpGame extends FlameGame with TapCallbacks implements MiniGame {
  late PlayerComponent _player;
  late ObstacleManager _obstacleManager;
  int _score = 0;
  bool _isGameOver = false;

  @override
  Color backgroundColor() => const Color(0xFF1A1A2E);

  @override
  void dispose() {
    // Clean up if needed
  }

  @override
  Future<void> onLoad() async {
    _player = PlayerComponent();
    _obstacleManager = ObstacleManager();
    add(_player);
    add(_obstacleManager);
    add(ScreenHitbox());
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isGameOver) return;
    _player.jump();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;

    _score = _obstacleManager.score;
    
    if (_player.y > size.y || _player.y < 0) {
      gameOver();
    }

    // Collision check
    for (final obstacle in _obstacleManager.children.whereType<Obstacle>()) {
      if (_player.toRect().overlaps(obstacle.toRect())) {
        gameOver();
      }
    }
  }

  void gameOver() {
    _isGameOver = true;
    pauseEngine();
  }

  @override
  void pause() {
    pauseEngine();
  }

  @override
  void reset() {
    _isGameOver = false;
    _score = 0;
    _player.reset();
    _obstacleManager.reset();
    resumeEngine();
  }

  @override
  int get score => _score;

  @override
  void start() {
     if (_isGameOver) {
       reset();
     } else {
       resumeEngine();
     }
  }
}

class PlayerComponent extends PositionComponent {
  double velocityY = 0;
  final double gravity = 800;
  final double jumpStrength = -300;

  PlayerComponent() {
    size = Vector2(30, 30);
    anchor = Anchor.center;
    position = Vector2(50, 200);
  }

  void jump() {
    velocityY = jumpStrength;
  }

  void reset() {
    position = Vector2(50, 200);
    velocityY = 0;
  }

  @override
  void update(double dt) {
    velocityY += gravity * dt;
    y += velocityY * dt;
  }

  @override
  void render(Canvas canvas) {
    // Glow effect
    final glowPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 + 10, glowPaint);
    
    // Main player
    final gradient = RadialGradient(
      colors: [Colors.yellow.shade300, Colors.orange.shade600],
    );
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(
        center: Offset(size.x / 2, size.y / 2),
        radius: size.x / 2,
      ));
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    
    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(Offset(size.x / 3, size.y / 3), size.x / 4, highlightPaint);
  }
}

class ObstacleManager extends Component with HasGameRef<JumpGame> {
  double _timer = 0;
  int score = 0;

  @override
  void update(double dt) {
    _timer += dt;
    if (_timer > 2) {
      _timer = 0;
      _spawnObstacle();
    }
    
    // Cleanup
    final toRemove = <Component>[];
    for (final child in children) {
       if (child is Obstacle && child.x + child.width < 0) {
         toRemove.add(child);
         score++;
       }
    }
    removeAll(toRemove);
  }

  void _spawnObstacle() {
    final gapHeight = 150.0;
    final gameHeight = gameRef.size.y;
    final gapY = Random().nextDouble() * (gameHeight - 200) + 100;

    add(Obstacle(Vector2(gameRef.size.x, 0), Vector2(50, gapY - gapHeight / 2)));
    add(Obstacle(Vector2(gameRef.size.x, gapY + gapHeight / 2), Vector2(50, gameHeight - (gapY + gapHeight / 2))));
  }

  void reset() {
    removeAll(children);
    score = 0;
    _timer = 0;
  }
}

class Obstacle extends PositionComponent {
  Obstacle(Vector2 position, Vector2 size) {
    this.position = position;
    this.size = size;
  }

  @override
  void update(double dt) {
    x -= 150 * dt;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.fill;
    
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(size.toRect().translate(2, 2), shadowPaint);
    
    // Main obstacle
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
      paint,
    );
    
    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.x - 8, size.y / 3),
        const Radius.circular(4),
      ),
      highlightPaint,
    );
  }
}
