
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class ReactionGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  bool _waitingForInput = false;
  DateTime? _startTime;
  int _score = 0;
  String _message = "Get Ready...";
  Color _backgroundColor = Colors.red;

  // Stream/Notifier for UI updates
  bool get isPlaying => _isPlaying;
  String get message => _message;
  Color get backgroundColor => _backgroundColor;

  Timer? _timer;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _resetRound();
  }

  void _resetRound() {
    _waitingForInput = false;
    _message = "Wait for Green...";
    _backgroundColor = Colors.red;
    notifyListeners();

    // Random delay between 2 and 5 seconds
    final delay = Random().nextInt(3000) + 2000;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: delay), () {
      if (!_isPlaying) return;
      _waitingForInput = true;
      _message = "TAP NOW!";
      _backgroundColor = Colors.green;
      _startTime = DateTime.now();
      notifyListeners();
    });
  }

  void handleTap() {
    if (!_isPlaying) return;

    if (_waitingForInput) {
      // Success
      final reactionTime = DateTime.now().difference(_startTime!).inMilliseconds;
      _score = (10000 / reactionTime).round(); // Score based on speed (higher is better)
      if (_score > 1000) _score = 1000; // Cap
      
      _message = "${reactionTime}ms\nScore: $_score\nTap to try again";
      _waitingForInput = false;
      _backgroundColor = Colors.blue;
      notifyListeners();
      // Auto restart round logic could go here, or manual
    } else {
      // Tapped too early
      _timer?.cancel();
      _message = "Too Early!\nTap to try again";
      _score = 0;
      _backgroundColor = Colors.grey;
      notifyListeners();
    }
  }

  @override
  void pause() {
    _isPlaying = false;
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void reset() {
    _isPlaying = false;
    _score = 0;
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

class ReactionGameWidget extends StatelessWidget {
  final ReactionGameController controller;

  const ReactionGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: controller.handleTap,
          child: Container(
            color: controller.backgroundColor,
            alignment: Alignment.center,
            child: Text(
              controller.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
