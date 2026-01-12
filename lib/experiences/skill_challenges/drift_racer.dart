import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class DriftRacer extends FlameGame with DragCallbacks implements MiniGame {
  late CarComponent _car;
  bool _isGameOver = false;

  @override
  Color backgroundColor() => const Color(0xFF222222);

  @override
  Future<void> onLoad() async {
    _car = CarComponent(position: Vector2(size.x / 2, size.y - 150));
    add(_car);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_isGameOver) return;
    _car.targetX += event.localDelta.x * 1.5; 
  }

  @override
  int get score => 0;
  @override
  void start() => resumeEngine();
  @override
  void pause() => pauseEngine();
  @override
  void reset() { _car.reset(size.x / 2); resumeEngine(); }
  @override
  void dispose() {}
}

class CarComponent extends PositionComponent with HasGameRef<DriftRacer> {
  double targetX;
  CarComponent({required Vector2 position}) : targetX = position.x, super(position: position, size: Vector2(40, 70), anchor: Anchor.center);
  void reset(double x) { position.x = x; targetX = x; }
  @override
  void update(double dt) {
    targetX = targetX.clamp(30, gameRef.size.x - 30);
    position.x += (targetX - position.x) * 10 * dt;
    angle = (position.x - targetX) * 0.005;
  }
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)), Paint()..color = Colors.blueAccent);
  }
}
