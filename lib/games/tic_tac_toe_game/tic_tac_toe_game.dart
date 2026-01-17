import 'dart:async';
import 'dart:math';
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
  
  // AI is always 'O'
  final String _player = 'X';
  final String _aiPlayer = 'O';

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

  Future<void> move(int index) async {
    // Player Move
    if (!_isPlaying || _board[index].isNotEmpty || _winner.isNotEmpty || !_isXTurn) return;
    
    _board[index] = _player;
    _isXTurn = false;
    notifyListeners();
    
    if (_checkEndGame()) return;
    
    // AI Turn with small delay for realism
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isPlaying) return; // In case reset happened during delay
    
    _makeAiMove();
    _isXTurn = true;
    notifyListeners();
    
    _checkEndGame();
  }
  
  bool _checkEndGame() {
    String? win = _checkWinnerInternal(_board);
    if (win != null) {
      _winner = win;
      if (_winner == _player) _score++;
      _isPlaying = false;
      notifyListeners();
      return true;
    }
    
    if (!_board.contains('')) {
      _winner = 'Draw';
      _isPlaying = false;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  void _makeAiMove() {
    int bestScore = -1000;
    int bestMove = -1;
    
    for (int i = 0; i < 9; i++) {
      if (_board[i] == '') {
        _board[i] = _aiPlayer;
        int score = _minimax(_board, 0, false);
        _board[i] = '';
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }
    
    if (bestMove != -1) {
      _board[bestMove] = _aiPlayer;
    }
  }
  
  int _minimax(List<String> board, int depth, bool isMaximizing) {
    String? result = _checkWinnerInternal(board);
    if (result == _aiPlayer) return 10 - depth;
    if (result == _player) return depth - 10;
    if (!board.contains('')) return 0;
    
    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == '') {
          board[i] = _aiPlayer;
          int score = _minimax(board, depth + 1, false);
          board[i] = ''; // Undo
          bestScore = max(score, bestScore);
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 9; i++) {
        if (board[i] == '') {
          board[i] = _player;
          int score = _minimax(board, depth + 1, true);
          board[i] = ''; // Undo
          bestScore = min(score, bestScore);
        }
      }
      return bestScore;
    }
  }
  
  String? _checkWinnerInternal(List<String> board) {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];
    
    for (var line in lines) {
      if (board[line[0]].isNotEmpty &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        return board[line[0]];
      }
    }
    return null;
  }

  @override
  void pause() {}

  @override
  void reset() {
    resetBoard();
  }

  @override
  int get score => _score;
  
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
                  color: Colors.white.withValues(alpha: 0.1),
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
                          color: Colors.white.withValues(alpha: 0.05),
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

