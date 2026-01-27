import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class SimonSaysController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  List<int> _sequence = [];
  List<int> _userSequence = [];
  bool _showingSequence = false;
  int _currentShowIndex = 0;

  List<int> get sequence => _sequence;
  bool get showingSequence => _showingSequence;
  int get currentShowIndex => _currentShowIndex;

  static const List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];

  Color getColor(int index) => _colors[index];

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _sequence = [];
    _nextRound();
  }

  void _nextRound() {
    _sequence.add(Random().nextInt(4));
    _userSequence = [];
    _showSequence();
  }

  bool _isDisposed = false;

  Future<void> _showSequence() async {
    _showingSequence = true;
    if (!_isDisposed) notifyListeners();
    
    for (int i = 0; i < _sequence.length; i++) {
      if (_isDisposed) return;
      await Future.delayed(const Duration(milliseconds: 600));
      if (_isDisposed) return;
      _currentShowIndex = _sequence[i];
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));
      if (_isDisposed) return;
      _currentShowIndex = -1;
      notifyListeners();
    }
    
    _showingSequence = false;
    if (!_isDisposed) notifyListeners();
  }

  void onColorTap(int index) {
    if (!_isPlaying || _showingSequence) return;

    _userSequence.add(index);

    if (_userSequence.last != _sequence[_userSequence.length - 1]) {
      // Wrong!
      _isPlaying = false;
      notifyListeners();
      return;
    }

    if (_userSequence.length == _sequence.length) {
      // Correct sequence!
      _score++;
      Future.delayed(const Duration(milliseconds: 500), _nextRound);
    }
  }

  @override
  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void reset() {
    _isPlaying = false;
    start();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isPlaying = false; // Stop any logic
    super.dispose();
  }

  @override
  int get score => _score;
}

class SimonSaysWidget extends StatelessWidget {
  final SimonSaysController controller;

  const SimonSaysWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade900, Colors.black],
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 400, // Constraint width to ensure layout consistency
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Round: ${controller.score + 1}',
                    style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20), // Reduced padding
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final isActive = controller.currentShowIndex == index;
                      return GestureDetector(
                        onTap: () => controller.onColorTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 150, // Explicit height
                          decoration: BoxDecoration(
                            color: isActive 
                                ? controller.getColor(index)
                                : controller.getColor(index).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: controller.getColor(index).withValues(alpha: 0.6),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
