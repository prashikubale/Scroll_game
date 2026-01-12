import 'package:flutter/material.dart';

class GamePageIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalGames;

  const GamePageIndicator({
    super.key,
    required this.currentIndex,
    required this.totalGames,
  });

  @override
  Widget build(BuildContext context) {
    if (totalGames == 0) return const SizedBox.shrink();
    
    return Positioned(
      right: 20,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalGames, (index) {
            final isActive = index == currentIndex;

            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 4),
              width: isActive ? 8 : 6,
              height: isActive ? 24 : 16,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(4),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ),
    );
  }
}
