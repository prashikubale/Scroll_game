import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game/game_factory.dart';
import '../../../../core/game/mini_game.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/entities/game_session.dart'; 
import '../../../../games/whack_mole_game/whack_mole_game.dart'; // Corrected Path
import '../providers/game_providers.dart';
import '../widgets/bottom_action_bar.dart'; // New Import
import 'profile_page.dart'; // Fixed: Import Profile Page

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
  bool _isLiked = false; // Local state for like demo

  @override
  void initState() {
    super.initState();
    _gameInstance = GameFactory.create(widget.game);
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
    }
  }
  
  @override
  void dispose() {
    _removeGameListener();
    _gameInstance.controller.dispose();
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

  // Track previous state to detect transitions
  bool _wasPlaying = false;

  void _onGameUpdate() {
    final controller = _gameInstance.controller;
    
    // SPECIFIC GAME ADAPTERS
    // 1. Whack A Mole
    if (widget.game.id == 'game_whack' && controller is WhackMoleController) {
       // Detect transition from playing to not playing (Game Over)
       // We can check timeLeft <= 0 to distinguish "Game Over" from "Pause"
       bool isPlaying = controller.timeLeft > 0; // Rough approximation or access private? 
       // WhackMoleController has no veřejné getter for isPlaying.
       // But it has timeLeft. If timeLeft == 0, it's game over.
       
       if (_wasPlaying && controller.timeLeft <= 0) {
         _saveSession(controller.score);
       }
       _wasPlaying = controller.timeLeft > 0;
    }
  }

  void _saveSession(int score) {
    if (score <= 0) return; // Don't save empty games
    
    final session = GameSession(
      gameId: widget.game.id,
      score: score,
      durationSeconds: 0, // Calculate if possible
      timestamp: DateTime.now(),
      metrics: {}, // Add reaction time if available
    );
    
    ref.read(saveSessionUseCaseProvider).call(session);
    
    // Optional: Show Snack
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
    // Lifecycle management (Start/Pause based on visibility)
    final currentIndex = ref.watch(currentGameIndexProvider);
    // isActive just means "Page is visible". _isGameActive means "User tapped to play".
    final isPageVisible = currentIndex == widget.index;

    ref.listen(currentGameIndexProvider, (previous, next) {
        // Always pause and reset active state when scrolling
        if (next != widget.index) {
          _gameInstance.controller.pause();
        } else {
           // Arrived at page. Auto-start.
           _gameInstance.controller.start();
        }
    });

    // Initial start if visible
    if (isPageVisible) {
       // Micro-delay to ensure build completion
       WidgetsBinding.instance.addPostFrameCallback((_) {
          _gameInstance.controller.start();
       });
    }
    
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              children: [
                // Game Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      // Minimal Dark Gradient (Neutral)
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2C2C2C), // Soft Dark Grey
                          const Color(0xFF1A1A1A), // Darker Grey
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      // Clean Minimal Border
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1), 
                        width: 1
                      ),
                      // Soft Natural Shadow (No Glow)
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
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
                             child: _gameInstance.gameWidget,
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
                                       Colors.black.withOpacity(0.8),
                                       Colors.transparent,
                                     ],
                                   ),
                                 ),
                                 child: Center(
                                   child: Text(
                                      widget.game.name.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2.0,
                                        fontFamily: 'monospace', // Tech/Arcade feel
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
                
                const SizedBox(height: 25),

                // Action Bar (Simulating the wireframe's bottom layout)
                BottomActionBar(
                  isLiked: _isLiked,
                  onLike: () {
                    setState(() => _isLiked = !_isLiked);
                  },
                  onReplay: () {
                    _gameInstance.controller.reset();
                  },
                  onProfile: () {
                     Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  onShare: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                        ),
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_stories_rounded, color: Colors.cyanAccent.withOpacity(0.8)),
                                const SizedBox(width: 15),
                                Text(
                                  "HOW TO PLAY",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
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
                                  backgroundColor: Colors.white.withOpacity(0.1),
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
