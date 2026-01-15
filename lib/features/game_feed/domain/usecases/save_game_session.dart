import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/game_session.dart';
import '../repositories/game_repository.dart';

class SaveGameSession implements UseCase<void, GameSession> {
  final GameRepository repository;

  SaveGameSession(this.repository);

  @override
  Future<Either<Failure, void>> call(GameSession session) async {
    return await repository.saveSession(session);
  }
}
