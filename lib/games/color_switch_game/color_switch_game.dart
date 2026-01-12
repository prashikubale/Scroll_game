import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class ColorSwitchController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  Color _targetColor = Colors.red;
  Color _currentColor = Colors.blue;
  Timer? _timer;
  int _timeLeft = 30; // 30 second game

  Color get targetColor => _targetColor;
  Color get currentColor => _currentColor;
  int get timeLeft => _timeLeft;

  static final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _timeLeft = 30;
    _generateNewColors();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _timeLeft--;
      if (_timeLeft <= 0) {
        timer.cancel();
        _isPlaying = false;
      }
      notifyListeners();
    });
  }

  void _generateNewColors() {
    final random = Random();
    _targetColor = _colors[random.nextInt(_colors.length)];
    _currentColor = _colors[random.nextInt(_colors.length)];
    notifyListeners();
  }

  void handleTap() {
    if (!_isPlaying) return;

    if (_currentColor == _targetColor) {
      // Correct!
      _score += 10;
      _generateNewColors();
    } else {
      // Wrong
      _score = max(0, _score - 5);
    }
    notifyListeners();
  }

  void switchColor() {
    if (!_isPlaying) return;
    final random = Random();
    _currentColor = _colors[random.nextInt(_colors.length)];
    notifyListeners();
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
    _timer?.cancel();
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

class ColorSwitchWidget extends StatelessWidget {
  final ColorSwitchController controller;

  const ColorSwitchWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey.shade900, Colors.black],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Color Switch',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black87)],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Time: ${controller.timeLeft}s | Score: ${controller.score}',
                style: const TextStyle(fontSize: 20, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              Text(
                'Match this color:',
                style: const TextStyle(fontSize: 18, color: Colors.white60),
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: controller.targetColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: controller.targetColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: controller.handleTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: controller.currentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: controller.currentColor.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'TAP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: controller.switchColor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'SWITCH COLOR',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
