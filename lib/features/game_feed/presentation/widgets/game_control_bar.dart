
import 'dart:ui';
import 'package:flutter/material.dart';

class GameControlBar extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onSave;
  final VoidCallback onCommand;
  final int currentScore;
  final int highScore;

  const GameControlBar({
    super.key,
    required this.onRetry,
    required this.onSave,
    required this.onCommand,
    required this.currentScore,
    required this.highScore,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $currentScore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Best: $highScore',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: onRetry,
                      tooltip: 'Retry',
                    ),
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.white),
                      onPressed: onSave,
                      tooltip: 'Save Score',
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: onCommand,
                      tooltip: 'Settings',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
