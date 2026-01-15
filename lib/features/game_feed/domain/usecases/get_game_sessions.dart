import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/game_session.dart';
import '../repositories/game_repository.dart';

class GetGameSessions implements UseCase<List<GameSession>, NoParams> {
  final GameRepository repository;

  GetGameSessions(this.repository);

  @override
  Future<Either<Failure, List<GameSession>>> call(NoParams params) async {
    return await repository.getSessions();
  }
}
