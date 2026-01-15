import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session_model.dart';
import '../../domain/entities/game_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class GameLocalDataSource {
  Future<List<ExperienceEntity>> getGames();
  // Deprecated methods kept for interface compliance if needed somewhere else temporarily
  Future<void> saveScore(String gameId, int score);
  Future<int> getHighScore(String gameId);
  
  // New Session Methods
  Future<void> saveGameSession(GameSessionModel session);
  Future<List<GameSessionModel>> getGameSessions();
}

const String kGameScoresKey = 'GAME_SCORES';

class GameLocalDataSourceImpl implements GameLocalDataSource {
  final SharedPreferences sharedPreferences;

  GameLocalDataSourceImpl({required this.sharedPreferences});

  static const String kGameSessionsKey = 'GAME_SESSIONS_HISTORY';

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
        description: 'Goal: Catch falling items.\nControls: Drag basket.\nTip: Avoid red items.',
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
       const ExperienceEntity(
        id: 'game_surface_paradox',
        name: 'The Surface Paradox',
        description: 'Goal: Navigate the ball.\nControls: Touch ANYWHERE to pull gravity to that point.\nTip: Think of your finger as a magnet.',
        type: ExperienceType.surfaceParadox,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_untethered',
        name: 'The Untethered',
        description: 'Goal: Collect orbs.\nControls: Tilt phone (if supported) or drag to apply thrust.\nTip: Inertia is your enemy.',
        type: ExperienceType.untethered,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_orbital_void',
        name: 'Orbital Void',
        description: 'Goal: Orbit the center without crashing.\nControls: Tap to boost orbit radius.\nTip: Balance gravity vs velocity.',
        type: ExperienceType.orbitalVoid,
        assetPath: '',
      ),
      // Advanced Anti-Gravity
       const ExperienceEntity(
        id: 'game_drift_protocol',
        name: 'The Drift Protocol',
        description: 'Goal: Guide the key particle to the exit.\nControls: Tap to place gravity wells. Drag to move them.\nTip: Use wells to curve the path.',
        type: ExperienceType.driftProtocol,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_axis_shift',
        name: 'Axis Shift',
        description: 'Goal: Escape the maze.\nControls: Double Tap to rotate gravity 90°.\nTip: You fall in the direction of the new "Down".',
        type: ExperienceType.axisShift,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_relative_observer',
        name: 'The Relative Observer',
        description: 'Goal: Dock with the station.\nControls: Swipe to move the UNIVERSE, not the ship.\nTip: High friction means you stop instantly.',
        type: ExperienceType.relativeObserver,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_anchor_point',
        name: 'Anchor Point',
        description: 'Goal: Swing to the target.\nControls: Long press on nodes to tether. Release to launch.\nTip: Use momentum to swing further.',
        type: ExperienceType.anchorPoint,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_causality_echo',
        name: 'Causality Echo',
        description: 'Goal: Hit the target.\nControls: Tap to move... but 1.5 seconds later.\nTip: Plan your moves ahead.',
        type: ExperienceType.causalityEcho,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'game_void_mirror',
        name: 'The Void Mirror',
        description: 'Goal: Survive both worlds.\nControls: Tap to jump. Controls BOTH characters.\nTip: Watch the gaps in both timelines.',
        type: ExperienceType.voidMirror,
        assetPath: '',
      ),
      // Cognitive Teasers
       const ExperienceEntity(
        id: 'teaser_sympathetic',
        name: 'Sympathetic Resonance',
        description: 'Experiment: Calm the chaos.\nAction: Hold the static line to soothe the vibrating one.',
        type: ExperienceType.sympatheticResonance,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'teaser_void_stare',
        name: 'The Void Stare',
        description: 'Experiment: Do NOT observe.\nAction: Stop touching the screen. Let it open.',
        type: ExperienceType.voidStare,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'teaser_shadow',
        name: 'Anticipatory Shadow',
        description: 'Experiment: Catch the loom.\nAction: Tap exactly when the shadow fills the circle.',
        type: ExperienceType.anticipatoryShadow,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'teaser_friction',
        name: 'Inverted Friction',
        description: 'Experiment: Generate Heat.\nAction: Swipe rapidly to create "drag" and suspend the orb.',
        type: ExperienceType.invertedFriction,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'teaser_silence',
        name: 'Chromatic Silence',
        description: 'Experiment: Find Stability.\nAction: Hold screen when the "Silent Color" appears.',
        type: ExperienceType.chromaticSilence,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'teaser_decay',
        name: 'Meta-Decay',
        description: 'Experiment: System Clean.\nAction: Scrub/Swipe furiously to clean the interface.',
        type: ExperienceType.metaDecay,
        assetPath: '',
      ),
       const ExperienceEntity(
        id: 'teaser_observer',
        name: 'Observer Effect',
        description: 'Experiment: Collapse the Wave.\nAction: Touch to observe (Solid). Release to wave.',
        type: ExperienceType.observerEffect,
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
    final sessions = await getGameSessions();
    final gameSessions = sessions.where((s) => s.gameId == gameId).toList();
    if (gameSessions.isEmpty) return 0;
    
    // Assuming higher is better. If some games are timed (lower better), logic might need adjustment.
    // For now we just return max 'score'.
    return gameSessions.map((s) => s.score).reduce(max);
  }

  @override
  Future<void> saveScore(String gameId, int score) async {
    final session = GameSessionModel(
      gameId: gameId,
      score: score,
      durationSeconds: 0, // Legacy support
      timestamp: DateTime.now(),
    );
    await saveGameSession(session);
  }

  Future<void> saveGameSession(GameSessionModel session) async {
    final List<GameSessionModel> currentSessions = await _getStoredSessions();
    currentSessions.add(session);
    
    final List<Map<String, dynamic>> jsonList = currentSessions.map((s) => s.toJson()).toList();
    await sharedPreferences.setString(kGameSessionsKey, json.encode(jsonList));
  }

  Future<List<GameSessionModel>> getGameSessions() async {
    return _getStoredSessions();
  }

  Future<List<GameSessionModel>> _getStoredSessions() async {
    final jsonString = sharedPreferences.getString(kGameSessionsKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => GameSessionModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
