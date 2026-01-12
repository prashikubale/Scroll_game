import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/game_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class GameLocalDataSource {
  Future<List<ExperienceEntity>> getGames();
  // Deprecated methods kept for interface compliance if needed somewhere else temporarily
  Future<void> saveScore(String gameId, int score);
  Future<int> getHighScore(String gameId);
}

const String kGameScoresKey = 'GAME_SCORES';

class GameLocalDataSourceImpl implements GameLocalDataSource {
  final SharedPreferences sharedPreferences;

  GameLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<ExperienceEntity>> getGames() async {
    // 1. POOL A: VISUAL EXPERIENCES & TOYS
    List<ExperienceEntity> experiencePool = [
      // NEW PHYSICS/SHADER
      const ExperienceEntity(
        id: 'exp_gravity_orb',
        name: 'Gravity Orb',
        description: 'Tilt to roll the light.',
        type: ExperienceType.gravityOrb,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'exp_neon_fluid',
        name: 'Neon Fluid',
        description: 'Touch to paint light.',
        type: ExperienceType.neonFluid,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'exp_reality_warp',
        name: 'Reality Warp',
        description: 'Touch to distort space.',
        type: ExperienceType.realityWarp,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'exp_chaos_button',
        name: 'Chaos Engine',
        description: 'Press for entropy.',
        type: ExperienceType.chaosButton,
        assetPath: '',
      ),
      // TOYS
       const ExperienceEntity(
        id: 'int_calm_touch',
        name: 'Liquid Flow',
        description: 'Disturb the peace.',
        type: ExperienceType.calmTouch,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'int_tap_surprise',
        name: 'Curiosity Tap',
        description: 'Keep tapping...',
        type: ExperienceType.tapSurprise,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'int_hold_reveal',
        name: 'Deep Breath',
        description: 'Hold and breathe...',
        type: ExperienceType.holdReveal,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'int_emotional_meter',
        name: 'Mood Swipe',
        description: 'How are you feeling?',
        type: ExperienceType.emotionalMeter,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'int_random_outcome',
        name: 'The Oracle',
        description: 'Ask the oracle.',
        type: ExperienceType.randomOutcome,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'int_quote_reveal',
        name: 'Daily Wisdom',
        description: 'Tap for wisdom.',
        type: ExperienceType.quoteReveal,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'skill_archery',
        name: 'Archery Master',
        description: 'Pull back and release!',
        type: ExperienceType.archery,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'skill_precision',
        name: 'Precision Shooter',
        description: 'Tap to hit moving targets.',
        type: ExperienceType.precisionBall,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'skill_drift',
        name: 'Drift Racer',
        description: 'Steer to dodge obstacles.',
        type: ExperienceType.driftCar,
        assetPath: '',
      ),
    ];

    // 2. POOL B: ACTUAL GAMES
    List<ExperienceEntity> gamePool = [
      const ExperienceEntity(
        id: 'game_stack',
        name: 'Stack Tower',
        description: 'Build it high!',
        type: ExperienceType.stack,
        assetPath: 'assets/images/stack_preview.png',
      ),
      const ExperienceEntity(
        id: 'game_jump',
        name: 'Doodle Jump',
        description: 'Bounce up!',
        type: ExperienceType.jump,
        assetPath: 'assets/images/jump_preview.png',
      ),
      const ExperienceEntity(
        id: 'game_tictactoe',
        name: 'Tic-Tac-Toe',
        description: 'Classic X and O!',
        type: ExperienceType.ticTacToe,
        assetPath: 'assets/images/tictactoe_preview.png',
      ),
      const ExperienceEntity(
        id: 'game_memory',
        name: 'Memory Match',
        description: 'Find the pairs!',
        type: ExperienceType.memory,
        assetPath: 'assets/images/memory_preview.png',
      ),
      const ExperienceEntity(
        id: 'game_brickbreaker',
        name: 'Brick Breaker',
        description: 'Break all blocks!',
        type: ExperienceType.brickBreaker,
        assetPath: 'assets/images/brick_preview.png',
      ),
      const ExperienceEntity(
        id: 'game_snake',
        name: 'Snake',
        description: 'Grow the snake!',
        type: ExperienceType.snake,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'game_pong',
        name: 'Pong',
        description: 'Classic Paddle Ball',
        type: ExperienceType.pong,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'game_whack',
        name: 'Whack A Mole',
        description: 'Hit them quick!',
        type: ExperienceType.whackMole,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_simon',
        name: 'Simon Says',
        description: 'Follow the pattern.',
        type: ExperienceType.simonSays,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'game_color_switch',
        name: 'Color Switch',
        description: 'Match the colors.',
        type: ExperienceType.colorSwitch,
        assetPath: '',
      ),
      const ExperienceEntity(
        id: 'game_catch',
        name: 'Catch It',
        description: 'Catch falling items.',
        type: ExperienceType.catchGame,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_reaction',
        name: 'Reaction Time',
        description: 'Test your reflexes.',
        type: ExperienceType.reaction,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_number_puzzle',
        name: '15 Puzzle',
        description: 'Order the numbers.',
        type: ExperienceType.numberPuzzle,
        assetPath: '',
      ),
    ];

    // GENERATE FEED: NO DUPLICATES, JUST RANDOMIZED (12 Unique Items)
    List<ExperienceEntity> allContent = [
      ...gamePool, 
      ...experiencePool
    ];

    allContent.shuffle(); // "Randomize kar bhay"

    return allContent;
  }

  @override
  Future<int> getHighScore(String gameId) async {
    return 0; // Scores removed
  }

  @override
  Future<void> saveScore(String gameId, int score) async {
    // No-op
  }
}
