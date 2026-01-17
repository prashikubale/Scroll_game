import 'dart:ui';
import 'package:flutter/material.dart';

class BottomActionBar extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onReplay;
  final VoidCallback onShare; // Used for "How to Play"
  final VoidCallback onProfile; // New Profile Callback
  final bool isLiked;

  const BottomActionBar({
    super.key,
    required this.onLike,
    required this.onReplay,
    required this.onShare,
    required this.onProfile,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
               _buildActionButton(
                icon: Icons.person_outline_rounded,
                color: Colors.white,
                onTap: onProfile,
                label: 'Profile',
              ),
              _buildVerticalDivider(),
              _buildActionButton(
                icon: Icons.auto_stories_outlined,
                color: Colors.white,
                onTap: onShare,
                label: 'Guide',
              ),
               _buildVerticalDivider(),
              _buildActionButton(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? const Color(0xFFFF5252) : Colors.white,
                onTap: onLike,
                size: 28, // Slightly larger
                label: 'Like',
              ),
               _buildVerticalDivider(),
              _buildActionButton(
                icon: Icons.refresh_rounded,
                color: Colors.white,
                onTap: onReplay,
                label: 'Reset',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVerticalDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 24,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: size),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }
}
