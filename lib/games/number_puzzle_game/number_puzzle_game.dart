import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class NumberPuzzleController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  int _moves = 0;
  List<int> _tiles = [];

  List<int> get tiles => _tiles;
  int get moves => _moves;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _score = 0;
    _moves = 0;
    _tiles = List.generate(16, (i) => i);
    _shuffle();
  }

  void _shuffle() {
    final random = Random();
    for (int i = 0; i < 100; i++) {
      final emptyIndex = _tiles.indexOf(0);
      final neighbors = _getNeighbors(emptyIndex);
      if (neighbors.isNotEmpty) {
        final swapIndex = neighbors[random.nextInt(neighbors.length)];
        _swap(emptyIndex, swapIndex);
      }
    }
    notifyListeners();
  }

  List<int> _getNeighbors(int index) {
    final row = index ~/ 4;
    final col = index % 4;
    final neighbors = <int>[];
    
    if (row > 0) neighbors.add(index - 4);
    if (row < 3) neighbors.add(index + 4);
    if (col > 0) neighbors.add(index - 1);
    if (col < 3) neighbors.add(index + 1);
    
    return neighbors;
  }

  void _swap(int i, int j) {
    final temp = _tiles[i];
    _tiles[i] = _tiles[j];
    _tiles[j] = temp;
  }

  void onTileTap(int index) {
    if (!_isPlaying) return;
    
    final emptyIndex = _tiles.indexOf(0);
    if (_getNeighbors(emptyIndex).contains(index)) {
      _swap(index, emptyIndex);
      _moves++;
      
      if (_isSolved()) {
        _score = max(0, 1000 - _moves * 10);
        _isPlaying = false;
      }
      
      notifyListeners();
    }
  }

  bool _isSolved() {
    for (int i = 0; i < 15; i++) {
      if (_tiles[i] != i) return false;
    }
    return _tiles[15] == 0;
  }

  @override
  void pause() {
    _isPlaying = false;
  }

  @override
  void reset() {
    start();
  }

  @override
  int get score => _score;
}

class NumberPuzzleWidget extends StatelessWidget {
  final NumberPuzzleController controller;

  const NumberPuzzleWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade900],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Moves: ${controller.moves}',
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(30),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    final value = controller.tiles[index];
                    return GestureDetector(
                      onTap: () => controller.onTileTap(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: value == 0 ? Colors.transparent : Colors.teal.shade600,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: value == 0 ? null : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: value == 0
                            ? null
                            : Center(
                                child: Text(
                                  '$value',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
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
