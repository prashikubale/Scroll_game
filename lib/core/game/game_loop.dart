import 'package:flutter/scheduler.dart';

/// A reusable game loop that uses Flutter's [Ticker] for efficient animation.
class GameLoop {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final void Function(double dt) onUpdate;

  GameLoop({required this.onUpdate}) {
    _ticker = Ticker(_onTick);
  }

  void _onTick(Duration elapsed) {
    // Calculate delta time in seconds
    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Cap dt to prevent huge jumps if the app was paused effectively
    if (dt > 0.1) {
      // 100ms cap (10fps min)
      onUpdate(0.1);
    } else {
      onUpdate(dt);
    }
  }

  void start() {
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void stop() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }
  
  void pause() {
    stop();
  }
  
  void resume() {
    // Ticker doesn't inherently support resume from same duration without custom logic,
    // but start() generally resets or continues depending on cached ticker provider.
    // For standard Ticker, start() resets duration unless muted.
    // However, our _lastElapsed logic handles the delta.
    // To be safe, we just start if not active.
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero; // Reset so next tick doesn't have huge delta based on old elapsed
      _ticker.start();
    }
  }

  void dispose() {
    _ticker.dispose();
  }
}
