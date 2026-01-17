import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Live Scoring System with animations
class LiveScoreDisplay extends ConsumerWidget {
  final int score;
  final int highScore;
  final String gameName;

  const LiveScoreDisplay({
    super.key,
    required this.score,
    required this.highScore,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: 140,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2), // More subtle background
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.1),
               blurRadius: 10,
               spreadRadius: 2,
             )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             // Current Score
             Column(
               children: [
                 Text('SCORE', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.bold)),
                 AnimatedSwitcher(
                   duration: const Duration(milliseconds: 200),
                   transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                   child: Text(
                     score.toString(),
                     key: ValueKey(score),
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                   ),
                 ),
               ],
             ),
             
             Container(height: 24, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 12)),
             
             // Best Score
             Column(
               children: [
                 Text('BEST', style: TextStyle(fontSize: 10, color: Colors.amber.shade200, fontWeight: FontWeight.bold)),
                 Row(
                   children: [
                     Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                     const SizedBox(width: 4),
                     Text(
                       highScore.toString(),
                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                     ),
                   ],
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }
}

// Chain Reaction Effect Widget
class ChainReactionEffect extends StatefulWidget {
  final VoidCallback onComplete;

  const ChainReactionEffect({super.key, required this.onComplete});

  @override
  State<ChainReactionEffect> createState() => _ChainReactionEffectState();
}

class _ChainReactionEffectState extends State<ChainReactionEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ChainReactionPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class ChainReactionPainter extends CustomPainter {
  final double progress;

  ChainReactionPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withValues(alpha: (1 - progress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = progress * size.width;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.7, paint);
    canvas.drawCircle(center, radius * 0.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
