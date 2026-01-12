import 'package:flutter/material.dart';

class LikeButtonOverlay extends StatefulWidget {
  const LikeButtonOverlay({super.key});

  @override
  State<LikeButtonOverlay> createState() => _LikeButtonOverlayState();
}

class _LikeButtonOverlayState extends State<LikeButtonOverlay> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(milliseconds: 200),
       vsync: this, 
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
    });

    if (_isLiked) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100, // Middle bottom placement
      left: 0,
      right: 0,
      child: Center(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.redAccent : Colors.white,
                      size: 48, // "Bada" (Big)
                      shadows: [
                        BoxShadow(
                          color: _isLiked ? Colors.redAccent.withOpacity(0.5) : Colors.black26,
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isLiked ? "1" : "0", // Placeholder count
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
