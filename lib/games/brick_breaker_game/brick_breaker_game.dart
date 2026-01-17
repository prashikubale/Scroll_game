import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/game/mini_game.dart';

class BrickBreakerController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  double _paddleX = 0.5;
  double _ballX = 0.5;
  double _ballY = 0.7;
  double _ballVelX = 0.02;
  double _ballVelY = -0.02;
  
  // Dynamic Grid
  int _cols = 6;
  int _rows = 5;
  List<bool> _bricks = [];
  Timer? _timer;

  double get paddleX => _paddleX;
  double get ballX => _ballX;
  double get ballY => _ballY;
  List<bool> get bricks => _bricks;
  int get cols => _cols;
  int get rows => _rows;

  void movePaddle(double delta) {
    if (!_isPlaying) return;
    _paddleX = (_paddleX + delta).clamp(0.1, 0.9);
    notifyListeners();
  }

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) => _update());
  }

  void _update() {
    if (!_isPlaying) return;

    _ballX += _ballVelX;
    _ballY += _ballVelY;

    // Wall collision
    if (_ballX <= 0.02 || _ballX >= 0.98) _ballVelX *= -1;
    if (_ballY <= 0.02) _ballVelY *= -1;

    // Paddle collision
    if (_ballY >= 0.88 && _ballY <= 0.9 && (_ballX - _paddleX).abs() < 0.1) {
      _ballVelY *= -1;
      _ballVelX += (_ballX - _paddleX) * 0.1;
    }

    // Brick collision
    // Calculate dynamic brick size
    final brickWidth = 0.96 / _cols; // 0.96 to leave small margin
    final brickHeight = 0.05; // Fixed height ratio or could be dynamic
    
    for (int i = 0; i < _bricks.length; i++) {
      if (!_bricks[i]) continue;
      final row = i ~/ _cols;
      final col = i % _cols;
      
      final brickX = col * brickWidth + 0.02; 
      final brickY = row * (brickHeight + 0.01) + 0.1;
      
      if ((_ballX - (brickX + brickWidth/2)).abs() < brickWidth/2 + 0.01 && 
          (_ballY - (brickY + brickHeight/2)).abs() < brickHeight/2 + 0.01) {
        _bricks[i] = false;
        _ballVelY *= -1;
        _score += 10;
      }
    }

    // Game over
    if (_ballY > 1.0) {
      _isPlaying = false;
      _timer?.cancel();
    }

    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _timer?.cancel();
  }

  @override
  void reset() {
    _score = 0;
    _paddleX = 0.5;
    _ballX = 0.5;
    _ballY = 0.7;
    _ballVelX = 0.02;
    _ballVelY = -0.02;
    
    // RANDOMIZE GRID DENSITY (Number of Bricks)
    final random = Random();
    // Randomize columns between 5 and 10
    _cols = 5 + random.nextInt(6); 
    // Randomize rows between 5 and 20 to get high brick counts (up to 200)
    _rows = 5 + random.nextInt(16);
    
    _bricks = List.filled(_cols * _rows, true);
    start();
  }

  @override
  int get score => _score;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class BrickBreakerWidget extends StatelessWidget {
  final BrickBreakerController controller;

  const BrickBreakerWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: (details) {
            controller.movePaddle(details.delta.dx / MediaQuery.of(context).size.width);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.indigo.shade900, Colors.black],
              ),
            ),
            child: CustomPaint(
              painter: BrickBreakerPainter(controller),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class BrickBreakerPainter extends CustomPainter {
  final BrickBreakerController controller;

  BrickBreakerPainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final cols = controller.cols;
    final brickWidth = (size.width * 0.96) / cols;
    final brickHeight = size.height * 0.05;
    final margin = size.width * 0.02;

    // Draw bricks
    for (int i = 0; i < controller.bricks.length; i++) {
      if (!controller.bricks[i]) continue;
      final row = i ~/ cols;
      final col = i % cols;
      
      final x = margin + col * brickWidth;
      final y = size.height * 0.1 + row * (brickHeight + size.height * 0.01);
      
      final paint = Paint()
        ..color = Colors.primaries[i % Colors.primaries.length]
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, y, brickWidth - 4, brickHeight),
          const Radius.circular(4),
        ),
        paint,
      );
    }

    // Draw paddle
    final paddlePaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(controller.paddleX * size.width, size.height * 0.9),
          width: size.width * 0.2,
          height: 15,
        ),
        const Radius.circular(8),
      ),
      paddlePaint,
    );

    // Draw ball
    final ballPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(controller.ballX * size.width, controller.ballY * size.height),
      10,
      ballPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
