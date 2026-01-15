import '../../domain/entities/game_session.dart';

class GameSessionModel extends GameSession {
  const GameSessionModel({
    required super.gameId,
    required super.score,
    required super.durationSeconds,
    required super.timestamp,
    super.metrics,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    return GameSessionModel(
      gameId: json['gameId'],
      score: json['score'],
      durationSeconds: json['durationSeconds'],
      timestamp: DateTime.parse(json['timestamp']),
      metrics: json['metrics'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'score': score,
      'durationSeconds': durationSeconds,
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics,
    };
  }

  factory GameSessionModel.fromEntity(GameSession entity) {
    return GameSessionModel(
      gameId: entity.gameId,
      score: entity.score,
      durationSeconds: entity.durationSeconds,
      timestamp: entity.timestamp,
      metrics: entity.metrics,
    );
  }
}
