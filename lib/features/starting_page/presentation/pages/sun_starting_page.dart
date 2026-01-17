import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../game_feed/presentation/pages/game_feed_page.dart';

class SunStartingPage extends StatefulWidget {
  const SunStartingPage({super.key});

  @override
  State<SunStartingPage> createState() => _SunStartingPageState();
}

class _SunStartingPageState extends State<SunStartingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const GameFeedPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0C29), // Midnight Blue
              Color(0xFF302B63), // Deep Purple
              Color(0xFF24243E), // Dark Slate
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient Glow
            Positioned(
              top: -100,
              right: -100,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: const BoxDecoration(
                    color: Colors.purpleAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Warm Sun/Moon Icon
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wb_twilight_rounded, // Changed to Twilight/Cozy
                        size: 100,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),

                  // "Chillax" Header
                  Text(
                    'CHILLAX',
                    style: GoogleFonts.poppins(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          color: Colors.purpleAccent.withValues(alpha: 0.5),
                          offset: const Offset(0, 0),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      'scroll without being braindead',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Start Button
                  GestureDetector(
                    onTap: _navigateToHome,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 5 * (1 - _pulseAnimation.value)), // Subtle float
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'LET\'S VIBE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF302B63),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF302B63),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
