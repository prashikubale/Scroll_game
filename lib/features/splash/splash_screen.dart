import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A0A),
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(20, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final offset = math.sin(_controller.value * 2 * math.pi + index) * 50;
                  return Positioned(
                    left: (index % 5) * (MediaQuery.of(context).size.width / 5) + offset,
                    top: (index ~/ 5) * (MediaQuery.of(context).size.height / 4) + offset,
                    child: Opacity(
                      opacity: 0.1 + (_controller.value * 0.2),
                      child: Icon(
                        Icons.games_rounded,
                        size: 40 + (index % 3) * 20,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              );
            }),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.games_rounded,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'ARCADE',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 8,
                            shadows: [
                              Shadow(
                                blurRadius: 20,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'MINI GAMES',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
