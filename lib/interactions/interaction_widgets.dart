import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // For blur
import 'package:google_fonts/google_fonts.dart';

// Common interface/controller for interactions
abstract class InteractionController extends ChangeNotifier {
  void reset();
}

// ============================================================================
// 1. TURIOSITY TAP (Tap Until Surprise)
// ============================================================================
class TapSurpriseController extends InteractionController {
  int _taps = 0;
  bool _surprised = false;
  double _scale = 1.0;
  
  int get taps => _taps;
  bool get surprised => _surprised;
  double get scale => _scale;

  void tap() {
    if (_surprised) return;
    _taps++;
    // Add some randomness to the required taps for true surprise
    final requiredTaps = 8 + Random().nextInt(12); // Between 8 and 20
    
    _scale = 1.0 + (_taps * 0.08).clamp(0.0, 0.8); // Grow slightly
    
    if (_taps >= requiredTaps) {
      _surprised = true;
    }
    notifyListeners();
  }

  @override
  void reset() {
    _taps = 0;
    _surprised = false;
    _scale = 1.0;
    notifyListeners();
  }
}

class TapSurpriseWidget extends StatelessWidget {
  final TapSurpriseController controller;
  const TapSurpriseWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: controller.tap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade900, Colors.deepPurple.shade600],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background hints
                if (!controller.surprised)
                   Positioned(
                    bottom: 150,
                    child: Text(
                      "Keep tapping...",
                      style: GoogleFonts.poppins(
                        color: Colors.white30,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                // Main Content
                controller.surprised
                    ? _buildSurpriseContent()
                    : _buildTapTarget(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTapTarget() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 100),
      tween: Tween<double>(begin: controller.scale, end: controller.scale),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Center(
              child: Icon(
                Icons.touch_app,
                size: 50,
                color: Colors.purple.shade900,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSurpriseContent() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 100),
              const SizedBox(height: 20),
              Text(
                "Curiosity Rewarded!",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You found the secret.",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// 2. BREATH OF VISUALS (Hold to Reveal)
// ============================================================================
class HoldRevealController extends InteractionController {
  double _progress = 0.0;
  bool _revealed = false;
  
  double get progress => _progress;
  bool get revealed => _revealed;

  void setProgress(double val) {
    if (_revealed) return;
    _progress = val.clamp(0.0, 1.0);
    if (_progress >= 1.0) {
      _revealed = true;
    }
    notifyListeners();
  }

  @override
  void reset() {
    _progress = 0.0;
    _revealed = false;
    notifyListeners();
  }
}

class HoldRevealWidget extends StatefulWidget {
  final HoldRevealController controller;
  const HoldRevealWidget({super.key, required this.controller});

  @override
  State<HoldRevealWidget> createState() => _HoldRevealWidgetState();
}

class _HoldRevealWidgetState extends State<HoldRevealWidget> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4)); // Slower for calmness
    _anim.addListener(() {
      widget.controller.setProgress(_anim.value);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (widget.controller.revealed) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.tealAccent.shade100, Colors.teal.shade900],
                radius: 1.2,
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: const AlwaysStoppedAnimation(1.0), // Could animate this
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.spa, size: 80, color: Colors.teal),
                    const SizedBox(height: 20),
                    Text(
                      "Peace is within.",
                      style: GoogleFonts.lato(
                        fontSize: 32,
                        color: Colors.teal.shade900,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return GestureDetector(
          onLongPressStart: (_) => _anim.forward(),
          onLongPressEnd: (_) {
             if (!widget.controller.revealed) _anim.reverse();
          },
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Orb effect
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.tealAccent.withOpacity(0.2 + (widget.controller.progress * 0.5)),
                        blurRadius: 20 + (widget.controller.progress * 50),
                        spreadRadius: widget.controller.progress * 30,
                      )
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: widget.controller.progress,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  backgroundColor: Colors.white10,
                ),
                Text(
                  widget.controller.progress > 0.1 ? "Breate In..." : "Hold",
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 3. THE ORACLE (One Button Random Outcome)
// ============================================================================
class RandomOutcomeController extends InteractionController {
  String _outcome = "?";
  bool _spinning = false;
  
  String get outcome => _outcome;
  bool get spinning => _spinning;
  
  final List<String> _answers = [
    "Yes", "No", "Maybe", "Ask Again", "Definitely", 
    "Unlikely", "Trust Your Instincts", "Wait and See"
  ];

  void spin() async {
    if (_spinning) return;
    _spinning = true;
    notifyListeners();
    
    // Simulate spin visually
    for(int i=0; i<15; i++) {
        await Future.delayed(Duration(milliseconds: 50 + (i*i*2))); // Decelerate
        _outcome = _answers[Random().nextInt(_answers.length)];
        notifyListeners();
    }
    _spinning = false;
    notifyListeners();
  }

  @override
  void reset() {
    _outcome = "?";
    _spinning = false;
    notifyListeners();
  }
}

class RandomOutcomeWidget extends StatelessWidget {
  final RandomOutcomeController controller;
  const RandomOutcomeWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.indigo.shade900, Colors.black],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.indigoAccent.withOpacity(0.2), Colors.transparent],
                  ),
                  border: Border.all(color: Colors.indigoAccent.withOpacity(0.5), width: 1),
                ),
                child: Center(
                  child: Text(
                    controller.outcome,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: controller.spinning ? 30 : 40,
                      fontWeight: FontWeight.bold,
                      color: controller.spinning ? Colors.white54 : Colors.cyanAccent,
                      shadows: [
                         BoxShadow(color: Colors.cyan, blurRadius: 20)
                      ]
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: controller.spinning ? null : controller.spin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    color: controller.spinning ? Colors.grey.withOpacity(0.2) : Colors.indigoAccent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      if (!controller.spinning)
                        BoxShadow(color: Colors.indigoAccent.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
                    ]
                  ),
                  child: Text(
                    "ASK THE ORACLE",
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// 4. MOOD SWIPE (Swipe-based emotional meter)
// ============================================================================
class EmotionalMeterController extends InteractionController {
  double _value = 0.5;
  double get value => _value;

  void update(double v) {
    _value = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  @override
  void reset() => update(0.5);
}

class EmotionalMeterWidget extends StatelessWidget {
  final EmotionalMeterController controller;
  const EmotionalMeterWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Interpolate colors based on mood
        final bgGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(Colors.blueGrey.shade900, const Color(0xFFFF9A9E), controller.value)!,
            Color.lerp(Colors.black, const Color(0xFFFECFEF), controller.value)!,
          ],
        );
        
        final iconColor = Color.lerp(Colors.blueGrey, Colors.white, controller.value)!;

        // Determine emoji
        IconData icon;
        if (controller.value > 0.8) icon = Icons.sentiment_very_satisfied;
        else if (controller.value > 0.6) icon = Icons.sentiment_satisfied;
        else if (controller.value > 0.4) icon = Icons.sentiment_neutral;
        else if (controller.value > 0.2) icon = Icons.sentiment_dissatisfied;
        else icon = Icons.sentiment_very_dissatisfied;

        return Container(
          decoration: BoxDecoration(gradient: bgGradient),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Transform.scale(
                scale: 1.0 + (controller.value * 0.5),
                child: Icon(
                  icon,
                  size: 100,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                       // Border radius here is redundant for clipping but good for color/border if needed, 
                       // but ClipRRect handles the shape.
                    ),
                child: Column(
                  children: [
                    Text(
                      "How are you feeling?",
                      style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 10,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.white,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
                        overlayColor: Colors.white.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: controller.value,
                        onChanged: controller.update,
                      ),
                    ),
                  ],
                ),
              )))
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// 5. FLUID FLOW (Calm Touch)
// ============================================================================
class CalmTouchController extends InteractionController {
  List<Offset> _points = [];
  List<Offset> get points => _points;

  void addPoint(Offset p) {
    _points.add(p);
    if (_points.length > 50) _points.removeAt(0); // Longer trail
    notifyListeners();
  }

  @override
  void reset() {
    _points.clear();
    notifyListeners();
  }
}

class CalmTouchWidget extends StatelessWidget {
  final CalmTouchController controller;
  const CalmTouchWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onPanUpdate: (d) => controller.addPoint(d.localPosition),
          child: Container(
            color: const Color(0xFF000510), // Deep space blue
            child: CustomPaint(
              painter: LiquidPainter(controller.points),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class LiquidPainter extends CustomPainter {
  final List<Offset> points;
  LiquidPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw connecting line with glow
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for(int i=0; i<points.length-1; i++) {
        path.quadraticBezierTo(
            points[i].dx, points[i].dy, 
            (points[i].dx + points[i+1].dx)/2, (points[i].dy + points[i+1].dy)/2
        );
    }

    // Outer Glow
    paint.color = Colors.cyanAccent.withOpacity(0.2);
    paint.strokeWidth = 25;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawPath(path, paint);

    // Inner Core
    paint.color = Colors.white;
    paint.strokeWidth = 5;
    paint.maskFilter = null;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// 6. DAILY WISDOM (Tap to Reveal Quote)
// ============================================================================
class QuoteRevealController extends InteractionController {
  bool _revealed = false;
  bool get revealed => _revealed;
  
  final List<String> _quotes = [
    "The only way to do great work is to love what you do.",
    "Believe you can and you're halfway there.",
    "Peace begins with a smile.",
    "Happiness depends upon ourselves.",
    "Turn your wounds into wisdom.",
    "Simplicity is the ultimate sophistication."
  ];
  
  String _currentQuote = "Tap for wisdom";

  String get currentQuote => _currentQuote;

  void reveal() {
    if (_revealed) return;
    _revealed = true;
    _currentQuote = _quotes[Random().nextInt(_quotes.length)];
    notifyListeners();
  }

  @override
  void reset() {
    _revealed = false;
    notifyListeners();
  }
}

class QuoteRevealWidget extends StatelessWidget {
  final QuoteRevealController controller;
  const QuoteRevealWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: controller.reveal,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5DC), // Beige/Cream
              image: DecorationImage(
                image: const NetworkImage('https://www.transparenttextures.com/patterns/paper.png'), // Subtle texture if available, or just fallback
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.05), BlendMode.dstATop),
                fit: BoxFit.cover,
                onError: (_, __) {} // Fail gracefully
              )
            ),
            child: Center(
              child: controller.revealed
                  ? TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, val, child) {
                        return Opacity(
                          opacity: val,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - val)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.format_quote, color: Colors.black12, size: 60),
                                const SizedBox(height: 20),
                                Text(
                                  controller.currentQuote,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 32, 
                                    color: Colors.black87, 
                                    fontStyle: FontStyle.italic,
                                    height: 1.2
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(width: 50, height: 2, color: Colors.amber),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Text(
                          "TAP",
                          style: GoogleFonts.oswald(fontSize: 40, color: Colors.black12, letterSpacing: 5),
                        ),
                        const SizedBox(height: 10),
                         Text(
                          "TO RECEIVE WISDOM",
                          style: GoogleFonts.lato(color: Colors.black26, letterSpacing: 3),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
