
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/game_entity.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_local_data_source.dart';

class GameRepositoryImpl implements GameRepository {
  final GameLocalDataSource localDataSource;

  GameRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<GameEntity>>> getGames() async {
    try {
      final games = await localDataSource.getGames();
      return Right(games);
    } catch (e) {
      return const Left(CacheFailure('Failed to load games'));
    }
  }

  @override
  Future<Either<Failure, int>> getHighScore(String gameId) async {
    try {
      final score = await localDataSource.getHighScore(gameId);
      return Right(score);
    } catch (e) {
      return const Left(CacheFailure('Failed to load score'));
    }
  }

  @override
  Future<Either<Failure, bool>> saveScore({required String gameId, required int score}) async {
    try {
      final currentHigh = await localDataSource.getHighScore(gameId);
      if (score > currentHigh) {
        await localDataSource.saveScore(gameId, score);
        return const Right(true); // New high score!
      }
      return const Right(false);
    } catch (e) {
      return const Left(CacheFailure('Failed to save score'));
    }
  }
}
