import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class WhackMoleController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  int _timeLeft = 30;
  List<bool> _moles = List.filled(9, false);
  Timer? _gameTimer;
  Timer? _moleTimer;

  List<bool> get moles => _moles;
  int get timeLeft => _timeLeft;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _timeLeft = 30;
    _moles = List.filled(9, false);
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeLeft--;
      if (_timeLeft <= 0) {
        _isPlaying = false;
        timer.cancel();
        _moleTimer?.cancel();
      }
      notifyListeners();
    });

    _moleTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _spawnMole();
    });
  }

  void _spawnMole() {
    _moles = List.filled(9, false);
    final index = Random().nextInt(9);
    _moles[index] = true;
    notifyListeners();
  }

  void whackMole(int index) {
    if (!_isPlaying || !_moles[index]) return;
    _moles[index] = false;
    _score += 10;
    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _moleTimer?.cancel();
  }

  @override
  void reset() {
    _gameTimer?.cancel();
    _moleTimer?.cancel();
    start();
  }

  @override
  int get score => _score;

  @override
  void dispose() {
    _gameTimer?.cancel();
    _moleTimer?.cancel();
    super.dispose();
  }
}

class WhackMoleWidget extends StatelessWidget {
  final WhackMoleController controller;

  const WhackMoleWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.brown.shade700, Colors.brown.shade900],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Time: ${controller.timeLeft}s',
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(40),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => controller.whackMole(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.brown.shade400,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.brown.shade800, width: 4),
                        ),
                        child: controller.moles[index]
                            ? const Icon(Icons.pets, size: 50, color: Colors.brown)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
