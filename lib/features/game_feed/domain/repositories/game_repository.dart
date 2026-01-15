
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/game_entity.dart';
import '../entities/game_session.dart';

abstract class GameRepository {
  /// Fetch the list of available games.
  Future<Either<Failure, List<GameEntity>>> getGames();

  /// Save a new score for a specific game. Returns true if it's a new high score.
  Future<Either<Failure, bool>> saveScore({required String gameId, required int score});
  
  /// Get the current high score for a game.
  Future<Either<Failure, int>> getHighScore(String gameId);
  /// Get all recorded game sessions.
  Future<Either<Failure, List<GameSession>>> getSessions();

  /// Save a completed game session.
  Future<Either<Failure, void>> saveSession(GameSession session);
}
