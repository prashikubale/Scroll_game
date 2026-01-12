import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game/game_factory.dart';
import '../../../../core/game/mini_game.dart';
import '../../domain/entities/game_entity.dart';
import '../providers/game_providers.dart';
import '../widgets/game_title_overlay.dart';
import '../widgets/like_button_overlay.dart';
import '../../../../core/widgets/app_branding_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    _gameInstance = GameFactory.create(widget.game);
  }

  @override
  void didUpdateWidget(covariant GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      _gameInstance.controller.dispose(); // Dispose old controller
      _gameInstance = GameFactory.create(widget.game);
    }
  }
  
  @override
  void dispose() {
    // The GameFactory creates a new instance for us, so we own it.
    // We MUST dispose it to stop timers/tickers.
    _gameInstance.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    // Listen to the current index to determine if we are active
    // We use a simplified logic: ONE experience active at a time.
    final currentIndex = ref.watch(currentGameIndexProvider);
    final isActive = currentIndex == widget.index;

    // React to active state changes
    ref.listen(currentGameIndexProvider, (previous, next) {
      if (next == widget.index) {
        _gameInstance.controller.start();
      } else {
        _gameInstance.controller.pause();
      }
    });

    // Initial check (post-frame to ensure widget is built)
    if (isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gameInstance.controller.start();
      });
    } else {
      // Ensure paused if not active (e.g. rapid scroll)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gameInstance.controller.pause();
      });
    }

    return Stack(
      children: [
        // The Experience Widget (Full Screen)
        Positioned.fill(
          child: _gameInstance.gameWidget,
        ),
        
        // Minimal Title Overlay (Context)
        GameTitleOverlay(
          gameName: widget.game.name,
          gameDescription: widget.game.description,
        ),
        
        // App Branding (Subtle)
        const AppBrandingOverlay(),
        
        // Like Button (Interaction)
        const LikeButtonOverlay(),
      ],
    );
  }
}
