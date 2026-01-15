import 'package:equatable/equatable.dart';

class GameSession extends Equatable {
  final String gameId;
  final int score;
  final int durationSeconds;
  final DateTime timestamp;
  final Map<String, dynamic> metrics; // e.g., 'reactionTime': 200, 'accuracy': 0.95

  const GameSession({
    required this.gameId,
    required this.score,
    required this.durationSeconds,
    required this.timestamp,
    this.metrics = const {},
  });

  @override
  List<Object?> get props => [gameId, score, durationSeconds, timestamp, metrics];
}
