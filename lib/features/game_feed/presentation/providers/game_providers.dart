
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/usecases/get_games_feed.dart';
import '../../domain/usecases/save_game_score.dart';
import '../../domain/usecases/get_game_sessions.dart';
import '../../domain/usecases/save_game_session.dart';
import '../../domain/entities/game_session.dart';
import '../../../../core/usecases/usecase.dart';

// State for the list of games
final gamesFeedProvider = FutureProvider<List<GameEntity>>((ref) async {
  final getGamesFeed = sl<GetGamesFeed>();
  final result = await getGamesFeed(NoParams());
  return result.fold(
    (failure) => throw _mapFailureToMessage(failure),
    (games) => games,
  );
});

// UseCase provider for saving scores (can be used directly or via a notifier)
final saveScoreUseCaseProvider = Provider<SaveGameScore>((ref) => sl<SaveGameScore>());
final saveSessionUseCaseProvider = Provider<SaveGameSession>((ref) => sl<SaveGameSession>());

final gameSessionsProvider = FutureProvider<List<GameSession>>((ref) async {
  final getSessions = sl<GetGameSessions>();
  final result = await getSessions(NoParams());
  return result.fold(
    (failure) => throw _mapFailureToMessage(failure),
    (sessions) => sessions,
  );
});

String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case const (ServerFailure):
      return 'Server Failure';
    case const (CacheFailure):
      return 'Cache Failure';
    default:
      return 'Unexpected Error';
  }
}

// Current Game Index Provider (managed by PageView)
// Using a simple state notifier for the current game index
class CurrentGameIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void setIndex(int index) => state = index;
}


final currentGameIndexProvider = NotifierProvider<CurrentGameIndexNotifier, int>(
  () => CurrentGameIndexNotifier(),
);

// Lock Provider to prevent scrolling while playing
class ScrollLockNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLocked(bool value) {
    state = value;
  }
}

final scrollLockProvider = NotifierProvider<ScrollLockNotifier, bool>(
  () => ScrollLockNotifier(),
);

