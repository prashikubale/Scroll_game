import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class StackGame extends FlameGame with TapCallbacks implements MiniGame {
  int _score = 0;
  bool _isGameOver = false;
  
  static const double _initialWidth = 100.0;
  static const double _blockHeight = 30.0;
  double _currentWidth = _initialWidth;
  double _moveSpeed = 120.0;
  
  final List<StackBlock3D> _blocks = [];
  late MovingBlock3D _movingBlock;
  
  // Vibrant yellow like reference
  static const Color _blockColor = Color(0xFFE8D21D);
  static const Color _darkSide = Color(0xFF6B6B3D);

  @override
  Color backgroundColor() => const Color(0xFFD4D0B8);

  @override
  void dispose() {
    // Clean up if needed
  }

  @override
  Future<void> onLoad() async {
    _resetGame();
  }

  void _resetGame() {
    removeAll(children);
    _blocks.clear();
    _score = 0;
    _currentWidth = _initialWidth;
    _moveSpeed = 120.0;
    _isGameOver = false;

    // Base platform
    final baseBlock = StackBlock3D(
      position: Vector2(size.x / 2 - _initialWidth / 2, size.y - 200),
      size: Vector2(_initialWidth, _blockHeight),
      color: const Color(0xFF5D4E37),
      darkColor: const Color(0xFF3D2E17),
    );
    add(baseBlock);
    _blocks.add(baseBlock);

    _spawnNextBlock();
  }

  void _spawnNextBlock() {
    final yPos = size.y - 200 - (_blocks.length * _blockHeight);
    
    if (yPos < 150) {
      for (final block in _blocks) {
        block.y += _blockHeight * 4;
      }
      if (_movingBlock.isMounted) _movingBlock.y += _blockHeight * 4;
    }

    _movingBlock = MovingBlock3D(
      width: _currentWidth,
      yPos: size.y - 200 - (_blocks.length * _blockHeight),
      gameWidth: size.x,
      speed: _moveSpeed,
    );
    add(_movingBlock);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isGameOver) {
      reset();
      return;
    }

    final prevBlock = _blocks.last;
    final currentBlock = _movingBlock;
    
    remove(currentBlock);

    final leftEdgePrev = prevBlock.x;
    final rightEdgePrev = prevBlock.x + prevBlock.width;
    final leftEdgeCurrent = currentBlock.x;
    final rightEdgeCurrent = currentBlock.x + currentBlock.width;

    final overlapLeft = max(leftEdgePrev, leftEdgeCurrent);
    final overlapRight = min(rightEdgePrev, rightEdgeCurrent);
    final overlap = overlapRight - overlapLeft;

    if (overlap <= 3) {
      gameOver();
    } else {
      _score++;
      _moveSpeed += 4.0;
      _currentWidth = overlap;
      
      final newBlock = StackBlock3D(
        position: Vector2(overlapLeft, currentBlock.y),
        size: Vector2(_currentWidth, _blockHeight),
        color: _blockColor,
        darkColor: _darkSide,
      );
      add(newBlock);
      _blocks.add(newBlock);
      
      if (overlap >= prevBlock.width - 2) {
        _score += 3;
      }
      
      _spawnNextBlock();
    }
  }

  void gameOver() {
    _isGameOver = true;
    pauseEngine();
  }

  @override
  void pause() => pauseEngine();

  @override
  void reset() {
    resumeEngine();
    _resetGame();
  }

  @override
  int get score => _score;

  @override
  void start() {
    if (_isGameOver) reset();
    else resumeEngine();
  }
}

class StackBlock3D extends PositionComponent {
  final Color color;
  final Color darkColor;
  
  StackBlock3D({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    required this.darkColor,
  }) {
    this.position = position;
    this.size = size;
  }

  @override
  void render(Canvas canvas) {
    // EXACT 3D ISOMETRIC LIKE REFERENCE IMAGE
    
    // Shadow (soft, offset)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final shadowRect = Rect.fromLTWH(6, 6, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(3)),
      shadowPaint,
    );
    
    // MAIN FRONT FACE (bright yellow)
    final frontPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final frontRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(3)),
      frontPaint,
    );
    
    // TOP FACE (isometric, lighter)
    final topPaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.15)!;
    
    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.x, 0)
      ..lineTo(size.x - 12, -10)
      ..lineTo(-12, -10)
      ..close();
    
    canvas.drawPath(topPath, topPaint);
    
    // RIGHT SIDE FACE (dark, for depth - EXACTLY like reference)
    final sidePaint = Paint()
      ..color = darkColor;
    
    final sidePath = Path()
      ..moveTo(size.x, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x + 10, size.y - 10)
      ..lineTo(size.x + 10, -10)
      ..close();
    
    canvas.drawPath(sidePath, sidePaint);
    
    // Subtle highlight on front face
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.15);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 6, size.x - 16, size.y / 3),
        const Radius.circular(2),
      ),
      highlightPaint,
    );
    
    // Edge definition
    final edgePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(3)),
      edgePaint,
    );
  }
}

class MovingBlock3D extends PositionComponent {
  double speed;
  final double gameWidth;
  bool movingRight = true;

  MovingBlock3D({
    required double width,
    required double yPos,
    required this.gameWidth,
    required this.speed,
  }) {
    size = Vector2(width, 30);
    position = Vector2(gameWidth / 2 - width / 2, yPos);
  }

  @override
  void update(double dt) {
    if (movingRight) {
      x += speed * dt;
      if (x + width > gameWidth - 30) {
        x = gameWidth - 30 - width;
        movingRight = false;
      }
    } else {
      x -= speed * dt;
      if (x < 30) {
        x = 30;
        movingRight = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Same 3D rendering as StackBlock3D
    final color = const Color(0xFFE8D21D);
    final darkColor = const Color(0xFF6B6B3D);
    
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 6, size.x, size.y),
        const Radius.circular(3),
      ),
      shadowPaint,
    );
    
    final frontPaint = Paint()..color = color;
    final frontRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(3)),
      frontPaint,
    );
    
    final topPaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.15)!;
    
    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.x, 0)
      ..lineTo(size.x - 12, -10)
      ..lineTo(-12, -10)
      ..close();
    
    canvas.drawPath(topPath, topPaint);
    
    final sidePaint = Paint()..color = darkColor;
    
    final sidePath = Path()
      ..moveTo(size.x, 0)
      ..lineTo(size.x, size.y)
      ..lineTo(size.x + 10, size.y - 10)
      ..lineTo(size.x + 10, -10)
      ..close();
    
    canvas.drawPath(sidePath, sidePaint);
    
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 6, size.x - 16, size.y / 3),
        const Radius.circular(2),
      ),
      highlightPaint,
    );
  }
}
