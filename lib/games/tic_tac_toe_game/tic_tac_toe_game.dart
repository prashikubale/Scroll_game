import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/game/mini_game.dart';

class TicTacToeController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0; // Wins
  List<String> _board = List.filled(9, '');
  bool _isXTurn = true;
  String _winner = '';
  
  List<String> get board => _board;
  bool get isXTurn => _isXTurn;
  String get winner => _winner;

  @override
  void start() {
    if (_isPlaying) return;
    resetBoard();
  }
  
  void resetBoard() {
    _isPlaying = true;
    _board = List.filled(9, '');
    _isXTurn = true;
    _winner = '';
    notifyListeners();
  }

  void move(int index) {
    if (!_isPlaying || _board[index].isNotEmpty || _winner.isNotEmpty) return;
    
    _board[index] = _isXTurn ? 'X' : 'O';
    _isXTurn = !_isXTurn;
    
    checkWinner();
    
    if (_winner.isEmpty && !_board.contains('')) {
      // Draw
      _winner = 'Draw';
      _isPlaying = false;
    }
    
    notifyListeners();
  }
  
  void checkWinner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];
    
    for (var line in lines) {
      if (_board[line[0]].isNotEmpty &&
          _board[line[0]] == _board[line[1]] &&
          _board[line[0]] == _board[line[2]]) {
        _winner = _board[line[0]];
        if (_winner == 'X') _score++; // Assuming Player is X
        _isPlaying = false;
        return;
      }
    }
  }

  @override
  void pause() {
    // No-op for turn based
  }

  @override
  void reset() {
    resetBoard();
  }

  @override
  int get score => _score;
  
  @override
  void dispose() {
    super.dispose();
  }
}

class TicTacToeWidget extends StatelessWidget {
  final TicTacToeController controller;

  const TicTacToeWidget({super.key, required this.controller});

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
              colors: [Colors.purple.shade900, Colors.black],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.winner.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    controller.winner == 'Draw' ? 'Draw!' : '${controller.winner} Wins!',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 10, color: Colors.purple.shade500),
                      ],
                    ),
                  ),
                ),
              
              Container(
                width: 300,
                height: 300,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    final value = controller.board[index];
                    return GestureDetector(
                      onTap: () => controller.move(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: value == 'X' ? Colors.cyan : Colors.pink,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              if (controller.winner.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: ElevatedButton(
                    onPressed: controller.reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Play Again', style: TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
