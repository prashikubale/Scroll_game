import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics if needed safely
import '../../core/game/mini_game.dart';

class ChromaticSilenceController extends ChangeNotifier implements MiniGame {
  bool _isPlaying = false;
  int _score = 0;

  // Game State
  double _chaosLevel =
      1.0; // 1.0 = Max Chaos (Random Colors), 0.0 = Silence (Pure Color)
  Color _targetColor = Colors.cyan;
  Color _currentColor = Colors.black;

  Timer? _gameTimer;
  final Random _rnd = Random();

  // Getters
  double get chaosLevel => _chaosLevel;
  Color get currentColor => _currentColor;
  @override
  int get score => _score;
  bool get isPlaying => _isPlaying;

  @override
  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _chaosLevel = 1.0;
    _score = 0;
    _targetColor = HSVColor.fromAHSV(
      1.0,
      _rnd.nextDouble() * 360,
      1.0,
      1.0,
    ).toColor();

    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      _update();
    });
    notifyListeners();
  }

  void _update() {
    // If Chaos is high, color fluctuates wildly
    if (_chaosLevel > 0.1) {
      // Random drift
      double hue =
          (HSVColor.fromColor(_targetColor).hue +
              (_rnd.nextDouble() - 0.5) * 360 * _chaosLevel) %
          360;
      _currentColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

      // Passive Chaos Increase (Entropy)
      _chaosLevel = min(1.0, _chaosLevel + 0.01);
    } else {
      // Stabilized
      _currentColor = _targetColor;
      _score = 1; // Win state approach
      _chaosLevel = max(0.0, _chaosLevel - 0.05); // Snap to zero
    }
    notifyListeners();
  }

  // User Action: "Scroll Backwards" or "Drag Down" or "Hold" to reverse entropy
  void applyOrder(double amount) {
    if (!_isPlaying) return;
    _chaosLevel = max(0.0, _chaosLevel - amount);
    if (_chaosLevel < 0.1) {
      // Trigger visual "Lock"
    }
    notifyListeners();
  }

  @override
  void pause() {
    _isPlaying = false;
    _gameTimer?.cancel();
    notifyListeners();
  }

  @override
  void reset() => start();

  @override
  void dispose() {
    _gameTimer?.cancel();
    // Safety check just in case
    super.dispose();
  }
}

class ChromaticSilenceWidget extends StatefulWidget {
  final ChromaticSilenceController controller;
  const ChromaticSilenceWidget({super.key, required this.controller});

  @override
  State<ChromaticSilenceWidget> createState() => _ChromaticSilenceWidgetState();
}

class _ChromaticSilenceWidgetState extends State<ChromaticSilenceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _animController]),
      builder: (context, child) {
        final chaos = widget.controller.chaosLevel;
        final isSilent = chaos < 0.1;

        return GestureDetector(
          // Allow multiple gestures to "Restore Order"
          onVerticalDragUpdate: (details) {
            // Dragging DOWN (Positive Delta) reduces chaos? Or just motion reduces chaos?
            // "Entropy Reversal" -> Doing work creates order
            widget.controller.applyOrder(0.05); // Faster
          },
          onPanUpdate: (details) {
            widget.controller.applyOrder(0.05);
          },
          onLongPress: () {
            widget.controller.applyOrder(0.02); // Slow order
          },
          // Build visuals
          child: Container(
            decoration: BoxDecoration(
              color: widget.controller.currentColor,
              // Add noise pattern?
              gradient: chaos > 0.5
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.controller.currentColor,
                        Colors.white.withOpacity(chaos * 0.5),
                        widget.controller.currentColor,
                      ],
                      stops: [
                        0.2,
                        0.5 + sin(_animController.value * 2 * pi) * 0.2,
                        0.8,
                      ],
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Visual Glitch overlay
                if (chaos > 0.1)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GlitchPainter(
                        chaos: chaos,
                        time: _animController.value,
                      ),
                    ),
                  ),

                // Central Text
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSilent)
                        const Text(
                          "SILENCE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 10,
                          ),
                        )
                      else
                        Text(
                          "RESTORE ORDER",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                            letterSpacing: 2.0 * chaos,
                          ),
                        ),

                      if (!isSilent)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: SizedBox(
                            width: 100,
                            height: 4,
                            child: LinearProgressIndicator(
                              value: 1.0 - chaos,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
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

class _GlitchPainter extends CustomPainter {
  final double chaos;
  final double time;
  _GlitchPainter({required this.chaos, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (chaos < 0.1) return;

    final paint = Paint()
      ..color = Colors.black.withOpacity(chaos * 0.3)
      ..style = PaintingStyle.fill;

    final rnd = Random(time.toInt() * 1000);

    // Draw some random horizontal stripes (glitch lines)
    for (int i = 0; i < 10; i++) {
      if (rnd.nextDouble() > 0.5) continue;
      double y = rnd.nextDouble() * size.height;
      double h = rnd.nextDouble() * 20 * chaos;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlitchPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.chaos != chaos;
}
