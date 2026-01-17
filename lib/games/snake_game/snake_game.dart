import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';
import '../../core/game/game_loop.dart';

enum GameState { idle, playing, paused, gameOver }

class SnakeGameController extends ChangeNotifier implements MiniGame {
  GameState _gameState = GameState.idle;
  int _score = 0;
  List<Point<int>> _snake = [];
  Point<int> _food = const Point(5, 5);
  String _currentDirection = 'right';
  
  // Input queue for smooth controls
  final Queue<String> _inputQueue = Queue<String>();
  
  // Game Loop
  late GameLoop _gameLoop;
  double _accumulatedTime = 0.0;
  final double _moveInterval = 0.15; // 150ms per move

  SnakeGameController() {
    _gameLoop = GameLoop(onUpdate: _update);
    _resetState();
  }

  // Getters
  GameState get gameState => _gameState;
  List<Point<int>> get snake => _snake;
  Point<int> get food => _food;
  @override
  int get score => _score;

  void _resetState() {
    _score = 0;
    _currentDirection = 'right';
    _inputQueue.clear();
    _snake = [
      const Point(10, 10),
      const Point(9, 10),
      const Point(8, 10),
    ];
    _spawnFood();
  }

  @override
  void start() {
    if (_gameState == GameState.playing) return;
    
    if (_gameState == GameState.gameOver) {
      _resetState();
    }
    
    _gameState = GameState.playing;
    _gameLoop.start();
    notifyListeners();
  }

  @override
  void pause() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      _gameLoop.stop();
      notifyListeners();
    }
  }

  @override
  void reset() {
    _gameLoop.stop();
    _gameState = GameState.idle;
    _resetState();
    notifyListeners();
  }
  
  void resume() {
     if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      _gameLoop.start();
      notifyListeners();
     }
  }

  void _update(double dt) {
    if (_gameState != GameState.playing) return;

    _accumulatedTime += dt;

    if (_accumulatedTime >= _moveInterval) {
      _accumulatedTime -= _moveInterval;
      _processInput();
      _moveSnake();
      notifyListeners();
    }
  }

  void _processInput() {
    if (_inputQueue.isNotEmpty) {
      final newDir = _inputQueue.removeFirst();
      
      // Validate turn again (in case queue had conflicting moves)
      if (!_isOppositeDirection(_currentDirection, newDir)) {
        _currentDirection = newDir;
      } else if (_inputQueue.isNotEmpty) {
         // Try next input if this one was invalid (optional, but good for responsiveness)
          _processInput();
      }
    }
  }
  
  bool _isOppositeDirection(String dir1, String dir2) {
    return (dir1 == 'up' && dir2 == 'down') ||
           (dir1 == 'down' && dir2 == 'up') ||
           (dir1 == 'left' && dir2 == 'right') ||
           (dir1 == 'right' && dir2 == 'left');
  }

  void changeDirection(String newDirection) {
    // If game is not playing, we can start it with a direction change? 
    // Or just ignore. Let's ignore if not playing/paused.
    if (_gameState != GameState.playing && _gameState != GameState.paused) return;
    
    // Don't fill queue too much
    if (_inputQueue.length >= 2) return;
    
    String lastPlannedDirection = _inputQueue.isEmpty ? _currentDirection : _inputQueue.last;
    
    if (newDirection != lastPlannedDirection && !_isOppositeDirection(lastPlannedDirection, newDirection)) {
      _inputQueue.add(newDirection);
    }
  }

  void _moveSnake() {
    final head = _snake.first;
    Point<int> newHead;
    
    switch (_currentDirection) {
      case 'up':
        newHead = Point(head.x, head.y - 1);
        break;
      case 'down':
        newHead = Point(head.x, head.y + 1);
        break;
      case 'left':
        newHead = Point(head.x - 1, head.y);
        break;
      case 'right':
        newHead = Point(head.x + 1, head.y);
        break;
      default:
        newHead = head;
    }
    
    // Check boundaries
    if (newHead.x < 0 || newHead.x >= 20 || newHead.y < 0 || newHead.y >= 20) {
      _gameOver();
      return;
    }
    
    // Check self collision
    if (_snake.contains(newHead)) {
      // Small grace: if newHead is the tail, it's fine because tail will move (unless we ate food)
      // proper snake allows chasing tail
       if (newHead != _snake.last) {
          _gameOver();
          return;
       }
    }
    
    _snake.insert(0, newHead);
    
    // Check food
    if (newHead == _food) {
      _score += 10;
      _spawnFood();
      // Don't remove last = grow
    } else {
      _snake.removeLast();
    }
  }
  
  void _gameOver() {
    _gameState = GameState.gameOver;
    _gameLoop.stop();
    notifyListeners();
  }

  void _spawnFood() {
    final random = Random();
    Point<int> newFood;
    do {
      newFood = Point(random.nextInt(20), random.nextInt(20));
    } while (_snake.contains(newFood));
    _food = newFood;
  }

  @override
  void dispose() {
    _gameLoop.dispose();
    super.dispose();
  }
}

class SnakeGameWidget extends StatelessWidget {
  final SnakeGameController controller;

  const SnakeGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
             if (controller.gameState == GameState.idle || controller.gameState == GameState.gameOver) {
               controller.start();
             } else if (controller.gameState == GameState.paused) {
               controller.resume();
             } else {
               controller.pause();
             }
          },
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              controller.changeDirection('down');
            } else if (details.delta.dy < 0) {
              controller.changeDirection('up');
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
              controller.changeDirection('right');
            } else if (details.delta.dx < 0) {
              controller.changeDirection('left');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade900, Colors.green.shade700],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: CustomPaint(
                      painter: SnakePainter(controller),
                      size: const Size(400, 400),
                    ),
                  ),
                ),
                if (controller.gameState == GameState.idle)
                  const Center(child: Text("Tap to Start", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                if (controller.gameState == GameState.gameOver)
                  const Center(child: Text("Game Over\nTap to Restart", textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold))),
                 if (controller.gameState == GameState.paused)
                  const Center(child: Text("Paused", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                 Positioned(
                   top: 20,
                   right: 20,
                   child: Text("Score: ${controller.score}", style: const TextStyle(color: Colors.white, fontSize: 20)),
                 )
              ],
            ),
          ),
        );
      },
    );
  }
}

class SnakePainter extends CustomPainter {
  final SnakeGameController controller;

  SnakePainter(this.controller);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 20;
    
    // Draw grid (optional, low opacity)
    /*
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..style = PaintingStyle.stroke;
    for (int i = 0; i <= 20; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), gridPaint);
    }
    */
    
    // Draw snake
    for (int i = 0; i < controller.snake.length; i++) {
      final segment = controller.snake[i];
      final paint = Paint()
        ..color = i == 0 ? Colors.lightGreen : Colors.green.shade600;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            segment.x * cellSize + 1,
            segment.y * cellSize + 1,
            cellSize - 2,
            cellSize - 2,
          ),
          const Radius.circular(4),
        ),
        paint,
      );
    }
    
    // Draw food
    final foodPaint = Paint()..color = Colors.redAccent;
    canvas.drawCircle(
      Offset(
        controller.food.x * cellSize + cellSize / 2,
        controller.food.y * cellSize + cellSize / 2,
      ),
      cellSize / 2.5,
      foodPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SnakePainter oldDelegate) {
    // Ideally we check if snake or food changed, but controller is a ChangeNotifier.
    // However, repainting every time controller notifies is what we want.
    return true; 
  }
}
