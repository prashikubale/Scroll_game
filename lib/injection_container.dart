
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/game_feed/data/datasources/game_local_data_source.dart';
import 'features/game_feed/data/repositories/game_repository_impl.dart';
import 'features/game_feed/domain/repositories/game_repository.dart';
import 'features/game_feed/domain/usecases/get_games_feed.dart';
import 'features/game_feed/domain/usecases/save_game_score.dart';
import 'features/game_feed/domain/usecases/get_game_sessions.dart';
import 'features/game_feed/domain/usecases/save_game_session.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Game Feed
  // UseCases
  sl.registerLazySingleton(() => GetGamesFeed(sl()));
  sl.registerLazySingleton(() => SaveGameScore(sl()));
  sl.registerLazySingleton(() => GetGameSessions(sl()));
  sl.registerLazySingleton(() => SaveGameSession(sl()));

  // Repository
  sl.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<GameLocalDataSource>(
    () => GameLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
