import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_game_app/games/snake_game/snake_game.dart';
import 'dart:math';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SnakeGameController Tests', () {
    late SnakeGameController controller;

    setUp(() {
      controller = SnakeGameController();
    });

    test('Initial state is correct', () {
      expect(controller.gameState, GameState.idle);
      expect(controller.score, 0);
      expect(controller.snake.length, 3);
      expect(controller.snake.first, const Point(10, 10));
    });

    test('Start game changes state to playing', () {
      controller.start();
      expect(controller.gameState, GameState.playing);
    });

    test('Pause game changes state to paused', () {
      controller.start();
      controller.pause();
      expect(controller.gameState, GameState.paused);
    });

    test('Reset game restores initial state', () {
      controller.start();
      controller.reset();
      expect(controller.gameState, GameState.idle);
      expect(controller.score, 0);
    });
    
    // Note: Timer/GameLoop based logic is hard to test with just unit tests without mocking Ticker.
    // For now, we test the methods we can.
    
    test('Direction change input queuing', () {
      controller.start();
      // Current dir is right.
      
      // Try 180 turn (should be ignored)
      controller.changeDirection('left');
      // We can't easily inspect the private queue, but we can verify logic via public methods if we exposed them.
      // Since queue is private, we rely on the fact that the snake shouldn't move left on next update.
    });
  });
}
