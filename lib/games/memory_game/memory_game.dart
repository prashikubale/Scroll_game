import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class MemoryGameController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;
  List<int> _cards = [];
  List<bool> _revealed = [];
  List<bool> _matched = [];
  int? _firstIndex;
  int? _secondIndex;
  int _moves = 0;

  List<int> get cards => _cards;
  List<bool> get revealed => _revealed;
  List<bool> get matched => _matched;
  int get moves => _moves;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _initializeGame();
  }

  void _initializeGame() {
    // Create 8 pairs (16 cards total)
    _cards = List.generate(8, (i) => i)..addAll(List.generate(8, (i) => i));
    _cards.shuffle(Random());
    _revealed = List.filled(16, false);
    _matched = List.filled(16, false);
    _firstIndex = null;
    _secondIndex = null;
    _moves = 0;
    _score = 0;
    notifyListeners();
  }

  void flipCard(int index) {
    if (!_isPlaying || _revealed[index] || _matched[index]) return;
    if (_firstIndex != null && _secondIndex != null) return;

    _revealed[index] = true;
    notifyListeners();

    if (_firstIndex == null) {
      _firstIndex = index;
    } else if (_secondIndex == null) {
      _secondIndex = index;
      _moves++;
      
      // Check for match after a delay
      Timer(const Duration(milliseconds: 500), () {
        if (_cards[_firstIndex!] == _cards[_secondIndex!]) {
          // Match!
          _matched[_firstIndex!] = true;
          _matched[_secondIndex!] = true;
          _score += 10;
          
          // Check if game is complete
          if (_matched.every((m) => m)) {
            _score += (100 - _moves * 2).clamp(0, 100); // Bonus for fewer moves
          }
        } else {
          // No match
          _revealed[_firstIndex!] = false;
          _revealed[_secondIndex!] = false;
        }
        _firstIndex = null;
        _secondIndex = null;
        notifyListeners();
      });
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
    _initializeGame();
    start();
  }

  @override
  int get score => _score;
  
}

class MemoryGameWidget extends StatelessWidget {
  final MemoryGameController controller;

  const MemoryGameWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade900, Colors.blue.shade900],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Memory Match',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Moves: ${controller.moves} | Score: ${controller.score}',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 16,
                  itemBuilder: (context, index) {
                    final isRevealed = controller.revealed[index];
                    final isMatched = controller.matched[index];
                    
                    return GestureDetector(
                      onTap: () => controller.flipCard(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isMatched
                              ? Colors.green.shade400
                              : isRevealed
                                  ? Colors.white
                                  : Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isRevealed || isMatched
                              ? Icon(
                                  _getIconForCard(controller.cards[index]),
                                  size: 40,
                                  color: isMatched ? Colors.white : Colors.purple,
                                )
                              : const Icon(Icons.question_mark, size: 40, color: Colors.white54),
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

  IconData _getIconForCard(int value) {
    const icons = [
      Icons.star,
      Icons.favorite,
      Icons.flash_on,
      Icons.cloud,
      Icons.music_note,
      Icons.sports_soccer,
      Icons.cake,
      Icons.pets,
    ];
    return icons[value % icons.length];
  }
}
