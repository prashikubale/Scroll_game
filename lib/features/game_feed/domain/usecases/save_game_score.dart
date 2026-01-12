
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/game_repository.dart';

class SaveGameScore implements UseCase<bool, SaveScoreParams> {
  final GameRepository repository;

  SaveGameScore(this.repository);

  @override
  Future<Either<Failure, bool>> call(SaveScoreParams params) async {
    return await repository.saveScore(gameId: params.gameId, score: params.score);
  }
}

class SaveScoreParams extends Equatable {
  final String gameId;
  final int score;

  const SaveScoreParams({required this.gameId, required this.score});

  @override
  List<Object> get props => [gameId, score];
}
