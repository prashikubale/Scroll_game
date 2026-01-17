import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:confetti/confetti.dart'; // Import Confetti
import '../../../../core/game/game_factory.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/entities/game_session.dart'; 
import '../../../../games/whack_mole_game/whack_mole_game.dart'; 
import '../providers/game_providers.dart';
import '../widgets/bottom_action_bar.dart';
import 'profile_page.dart';
import '../../../../core/services/sound_manager.dart'; // Import SoundManager
import '../../../../core/widgets/particle_overlay.dart'; // Import ParticleOverlay

class GamePage extends ConsumerStatefulWidget {
  final GameEntity game;
  final int index;

  const GamePage({
    super.key,
    required this.game,
    required this.index,
  });

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  late GameInstances _gameInstance;
  bool _isLiked = false; 
  late ConfettiController _confettiController; // Controller for particles
  Color _bgTopColor = const Color(0xFF2C2C2C); // Dynamic BG state

  @override
  void initState() {
    super.initState();
    _gameInstance = GameFactory.create(widget.game);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    // Initialize last score to avoid false positives
    _lastScore = _gameInstance.controller.score;
    _setupGameListener();
  }

  @override
  void didUpdateWidget(covariant GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      _removeGameListener();
      _gameInstance.controller.dispose();
      _gameInstance = GameFactory.create(widget.game);
      _setupGameListener();
      // Reset score tracking for new game
      _lastScore = _gameInstance.controller.score;
    }
  }
  
  @override
  void dispose() {
    _removeGameListener();
    _gameInstance.controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _setupGameListener() {
    final controller = _gameInstance.controller;
    if (controller is ChangeNotifier) {
      (controller as ChangeNotifier).addListener(_onGameUpdate);
    }
  }

  void _removeGameListener() {
    final controller = _gameInstance.controller;
    if (controller is ChangeNotifier) {
      (controller as ChangeNotifier).removeListener(_onGameUpdate);
    }
  }

  bool _wasPlaying = false;
  int _lastScore = 0;

  void _onGameUpdate() {
    final controller = _gameInstance.controller;
    
    // Check for score increase to trigger effects
    if (controller.score > _lastScore) {
       SoundManager().playScore();
       _pulseBackground();
    }
    // Always sync lastScore to handle resets/decreases correctly
    _lastScore = controller.score;

    // SPECIFIC GAME ADAPTERS
    if (widget.game.id == 'game_whack' && controller is WhackMoleController) {
       // Check for Game Over logic
       if (_wasPlaying && controller.timeLeft <= 0) {
         _confettiController.play(); // Play confetti on Game Over
         SoundManager().playGameOver();
         _saveSession(controller.score);
       }
       _wasPlaying = controller.timeLeft > 0;
    }
  }

  void _pulseBackground() {
    if (!mounted) return;
    setState(() {
      _bgTopColor = const Color(0xFF4A4A4A); // Lighter
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _bgTopColor = const Color(0xFF2C2C2C); // Back to dark
        });
      }
    });
  }

  void _saveSession(int score) {
    if (score <= 0) return; 
    
    final session = GameSession(
      gameId: widget.game.id,
      score: score,
      durationSeconds: 0, 
      timestamp: DateTime.now(),
      metrics: {}, 
    );
    
    ref.read(saveSessionUseCaseProvider).call(session);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Score Saved: $score'), 
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 1),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentGameIndexProvider);
    final isPageVisible = currentIndex == widget.index;

    ref.listen(currentGameIndexProvider, (previous, next) {
        if (next != widget.index) {
          _gameInstance.controller.pause();
        } else {
           _gameInstance.controller.start();
        }
    });

    if (isPageVisible) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          _gameInstance.controller.start();
       });
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: Padding(
          // REDUCED PADDING to fix overflow
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Column(
              children: [
                // Game Container
                Expanded(
                  child: ParticleOverlay( // Wrapped in Particle Overlay
                    controller: _confettiController,
                    child: AnimatedContainer( // Animated Container for breathing effect
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _bgTopColor, // Dynamic Color
                            const Color(0xFF1A1A1A), 
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1), 
                          width: 1
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          children: [
                             // Game Widget
                             Positioned.fill(
                               child: Listener(
                                 onPointerDown: (_) {
                                   ref.read(scrollLockProvider.notifier).setLocked(true);
                                   // Optional: play tap sound on interaction? 
                                   // Might be too frequent, depends on game.
                                   // SoundManager().playTap(); 
                                 },
                                 onPointerUp: (_) {
                                   ref.read(scrollLockProvider.notifier).setLocked(false);
                                 },
                                 onPointerCancel: (_) {
                                   ref.read(scrollLockProvider.notifier).setLocked(false);
                                 },
                                 child: _gameInstance.gameWidget,
                               ),
                             ),
                             
                             // Professional Title Header
                             Positioned(
                               top: 0,
                               left: 0,
                               right: 0,
                               child: IgnorePointer(
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(vertical: 12),
                                   decoration: BoxDecoration(
                                     gradient: LinearGradient(
                                       begin: Alignment.topCenter,
                                       end: Alignment.bottomCenter,
                                       colors: [
                                         Colors.black.withValues(alpha: 0.8),
                                         Colors.transparent,
                                       ],
                                     ),
                                   ),
                                   child: Center(
                                     child: Text(
                                        widget.game.name.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 2.0,
                                          fontFamily: 'monospace', 
                                        ),
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // REDUCED SPACING to fix overflow
                const SizedBox(height: 12),

                // Action Bar
                BottomActionBar(
                  isLiked: _isLiked,
                  onLike: () {
                    SoundManager().playTap(); // Sound on Action
                    HapticFeedback.lightImpact();
                    setState(() => _isLiked = !_isLiked);
                  },
                  onReplay: () {
                    SoundManager().playTap();
                    _gameInstance.controller.reset();
                  },
                  onProfile: () {
                     SoundManager().playTap();
                     Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  onShare: () {
                    SoundManager().playTap();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                        ),
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_stories_rounded, color: Colors.cyanAccent.withValues(alpha: 0.8)),
                                const SizedBox(width: 15),
                                Text(
                                  "HOW TO PLAY",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.game.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text("GOT IT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 10),
              ],
            ),
        ),
      ),
    );
  }
}
