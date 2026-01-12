import 'package:equatable/equatable.dart';

enum ExperienceType {
  // Classic Interactions (retained as toys)
  tapSurprise,
  holdReveal,
  randomOutcome,
  emotionalMeter,
  quoteReveal,
  calmTouch,
  
  // New Physics/Shader Experiences
  gravityOrb,
  neonFluid,
  realityWarp,
  chaosButton,

  // Skill Challenges
  archery,
  precisionBall,
  driftCar,
  
  // Legacy Toy Conversion (Optional, keeps compilation safe for now)
  stack,
  jump,
  reaction,
  memory,
  colorSwitch,
  brickBreaker,
  simonSays,
  whackMole,
  numberPuzzle,
  catchGame,
  snake,
  ticTacToe,
  pong, 
}

class ExperienceEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final ExperienceType type;
  final String assetPath;
  
  // Removed highScore as per "No scores" rule

  const ExperienceEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.assetPath,
  });

  @override
  List<Object> get props => [id, name, description, type, assetPath];
}

// Type aliases for backward compatibility during refactor
typedef GameEntity = ExperienceEntity;
typedef GameType = ExperienceType;
