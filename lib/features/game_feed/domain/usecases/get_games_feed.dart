
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/game_entity.dart';
import '../repositories/game_repository.dart';

class GetGamesFeed implements UseCase<List<GameEntity>, NoParams> {
  final GameRepository repository;

  GetGamesFeed(this.repository);

  @override
  Future<Either<Failure, List<GameEntity>>> call(NoParams params) async {
    return await repository.getGames();
  }
}
