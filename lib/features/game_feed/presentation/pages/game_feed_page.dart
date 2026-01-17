
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import 'game_page.dart';

class GameFeedPage extends ConsumerWidget {
  const GameFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: gamesAsync.when(
        data: (games) {
          final currentIndex = ref.watch(currentGameIndexProvider);
          
          // Safety check: specific fix for RangeError if index persists from a longer list
          // This ensures we never access games[index] with an invalid index
          if (currentIndex >= games.length && games.isNotEmpty) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
               ref.read(currentGameIndexProvider.notifier).setIndex(0);
             });
          }

          final isScrollLocked = ref.watch(scrollLockProvider);

          return Stack(
            children: [
              PageView.builder(
                controller: PageController(
                  // Use a safe initial page. If current is invalid, default to 0. 
                  // The controller will be recreated if the tree rebuilds, which is fine here 
                  // as we want to sync with the (potentially corrected) currentIndex.
                  initialPage: currentIndex >= games.length ? 0 : currentIndex,
                ),
                physics: isScrollLocked ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: games.length,
                onPageChanged: (index) {
                  ref.read(currentGameIndexProvider.notifier).setIndex(index);
                },
                itemBuilder: (context, index) {
                  // Double safety check
                  if (index >= games.length) return const SizedBox.shrink();
                  final game = games[index];
                  return GamePage(game: game, index: index);
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Something went wrong:\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
