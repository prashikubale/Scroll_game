import 'package:flutter/widgets.dart';
import 'package:flame/game.dart'; // Required for GameWidget
import '../../features/game_feed/domain/entities/game_entity.dart';
// Legacy Games (Keep imports if we want to compile, or comment out if removing)
import '../../games/reaction_game/reaction_game.dart';
// ... other game imports kept for now ...
import '../../games/stack_game/stack_game.dart';
import '../../games/jump_game/jump_game.dart';
import '../../games/memory_game/memory_game.dart';
import '../../games/color_switch_game/color_switch_game.dart';
import '../../games/brick_breaker_game/brick_breaker_game.dart';
import '../../games/simon_says_game/simon_says_game.dart';
import '../../games/whack_mole_game/whack_mole_game.dart';
import '../../games/number_puzzle_game/number_puzzle_game.dart';
import '../../games/catch_game/catch_game.dart';
import '../../games/snake_game/snake_game.dart';
import '../../games/tic_tac_toe_game/tic_tac_toe_game.dart';
import '../../games/pong_game/pong_game.dart';
import '../../games/surface_paradox_game/surface_paradox_game.dart';
import '../../games/untethered_game/untethered_game.dart';
import '../../games/orbital_void_game/orbital_void_game.dart';
import '../../games/drift_protocol_game/drift_protocol_game.dart';
import '../../games/axis_shift_game/axis_shift_game.dart';
import '../../games/relative_observer_game/relative_observer_game.dart';
import '../../games/anchor_point_game/anchor_point_game.dart';
import '../../games/causality_echo_game/causality_echo_game.dart';
import '../../games/void_mirror_game/void_mirror_game.dart';
import '../../games/cognitive_teasers/sympathetic_resonance.dart';
import '../../games/cognitive_teasers/void_stare.dart';
import '../../games/cognitive_teasers/anticipatory_shadow.dart';
import '../../games/cognitive_teasers/inverted_friction.dart';
import '../../games/cognitive_teasers/chromatic_silence.dart';
import '../../games/cognitive_teasers/meta_decay.dart';
import '../../games/cognitive_teasers/observer_effect.dart';

import '../../interactions/interaction_widgets.dart';
import '../../experiences/gravity_orb.dart';
import '../../experiences/neon_fluid.dart';
import '../../experiences/chaos_button.dart';
import '../../experiences/reality_warp.dart';
import '../../experiences/skill_challenges/archery_challenge.dart';
import '../../experiences/skill_challenges/precision_target.dart';
import '../../experiences/skill_challenges/drift_racer.dart';

import 'mini_game.dart';

// --- GENERIC CONTROLLER FOR EXPERIENCES ---
class GenericExperienceController extends ChangeNotifier implements MiniGame {
  final ValueNotifier<bool> isActive = ValueNotifier(false);

  @override
  void start() {
    isActive.value = true;
    notifyListeners();
  }

  @override
  void pause() {
    isActive.value = false;
    notifyListeners();
  }

  @override
  void reset() {
    // For experiences, reset usually doesn't mean much, or could restart animation
    isActive.value = false;
    notifyListeners();
    // Optional: add a 'reset' signal logic if needed
  }

  @override
  int get score => 0; 
  
  @override
  void dispose() {
    isActive.dispose();
    super.dispose();
  }
}

// --- VISIBILITY WRAPPER ---
class ActiveExperienceWrapper extends StatelessWidget {
  final GenericExperienceController controller;
  final Widget Function(bool active) builder;

  const ActiveExperienceWrapper({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isActive,
      builder: (context, active, child) {
        return builder(active);
      },
    );
  }
}

// Adapter to treat Interactions as MiniGames (Existing)
class InteractionAdapter implements MiniGame {
  final InteractionController _controller;
  InteractionAdapter(this._controller);
  @override
  void start() {} 
  @override
  void pause() {}
  @override
  void reset() => _controller.reset();
  @override
  int get score => 0;
  @override
  void dispose() => _controller.dispose();
  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => _controller.removeListener(listener);
  @override
  bool get hasListeners => _controller.hasListeners;
  @override
  void notifyListeners() => _controller.notifyListeners();
}

class GameInstances {
  final Widget gameWidget;
  final MiniGame controller;
  GameInstances(this.gameWidget, this.controller);
}

abstract class GameFactory {
  static GameInstances create(ExperienceEntity game) {
    switch (game.type) {
      // --- NEW EXPERIENCES ---
      case ExperienceType.gravityOrb:
        final ctrl = GenericExperienceController();
        return GameInstances(
          ActiveExperienceWrapper(controller: ctrl, builder: (active) => GravityOrb(active: active)),
          ctrl,
        );
      case ExperienceType.neonFluid:
        final ctrl = GenericExperienceController();
        return GameInstances(
          ActiveExperienceWrapper(controller: ctrl, builder: (active) => NeonFluid(active: active)),
          ctrl,
        );
      case ExperienceType.chaosButton:
        final ctrl = GenericExperienceController();
        return GameInstances(
          ActiveExperienceWrapper(controller: ctrl, builder: (active) => ChaosButton(active: active)),
          ctrl,
        );
      case ExperienceType.realityWarp:
        final ctrl = GenericExperienceController();
        return GameInstances(
          ActiveExperienceWrapper(controller: ctrl, builder: (active) => RealityWarp(active: active)),
          ctrl,
        );
      case ExperienceType.archery:
        final game = ArcheryChallenge();
        return GameInstances(GameWidget(game: game), game);
      case ExperienceType.precisionBall:
        final ctrl = PrecisionTargetController();
        return GameInstances(
          PrecisionTargetWidget(controller: ctrl),
          ctrl,
        );
      case ExperienceType.driftCar:
        final game = DriftRacer();
        return GameInstances(GameWidget(game: game), game);

      // --- NEWLY ACTIVATED GAMES ---
      case ExperienceType.catchGame: return _createCatchGame();
      case ExperienceType.colorSwitch: return _createColorSwitchGame();
      case ExperienceType.reaction: return _createReactionGame();
      case ExperienceType.simonSays: return _createSimonSaysGame();
      case ExperienceType.whackMole: return _createWhackMoleGame();
      case ExperienceType.numberPuzzle: return _createNumberPuzzleGame();
      case ExperienceType.snake: return _createSnakeGame();
      case ExperienceType.pong: return _createPongGame();

      // --- ANTI-GRAVITY GAMES ---
      case ExperienceType.surfaceParadox: return _createSurfaceParadox();
      case ExperienceType.untethered: return _createUntethered();
      case ExperienceType.orbitalVoid: return _createOrbitalVoid();
      
      // --- ADVANCED ANTI-GRAVITY ---
      case ExperienceType.driftProtocol: return _createDriftProtocol();
      case ExperienceType.axisShift: return _createAxisShift();
      case ExperienceType.relativeObserver: return _createRelativeObserver();
      case ExperienceType.anchorPoint: return _createAnchorPoint();
      case ExperienceType.causalityEcho: return _createCausalityEcho();
      case ExperienceType.voidMirror: return _createVoidMirror();

      // --- COGNITIVE TEASERS (20 Micro-Disruptions) ---
      case ExperienceType.kineticSilence: return _createKineticSilence();
      case ExperienceType.anticipatoryShadow: return _createAnticipatoryShadow(); // Reusing existing or need update
      case ExperienceType.voidBlink: return _createPlaceholder('Void Blink');
      case ExperienceType.frictionInversion: return _createInvertedFriction(); // Reusing
      case ExperienceType.chromaticDecay: return _createPlaceholder('Chromatic Decay');
      case ExperienceType.echoCoordinates: return _createPlaceholder('Echo Coordinates');
      case ExperienceType.peripheralClarity: return _createPlaceholder('Peripheral Clarity');
      case ExperienceType.weightlessHeavy: return _createPlaceholder('Weightless Heavy');
      case ExperienceType.observerEffect: return _createObserverEffect(); // Reusing
      case ExperienceType.elasticDistance: return _createPlaceholder('Elastic Distance');
      case ExperienceType.sonicPaint: return _createPlaceholder('Sonic Paint');
      case ExperienceType.momentumTrap: return _createPlaceholder('Momentum Trap');
      case ExperienceType.vanishingPoint: return _createPlaceholder('Vanishing Point');
      case ExperienceType.phaseShift: return _createPlaceholder('Phase Shift');
      case ExperienceType.mirrorLie: return _createPlaceholder('Mirror Lie');
      case ExperienceType.magneticResistance: return _createPlaceholder('Magnetic Resistance');
      case ExperienceType.memoryStain: return _createPlaceholder('Memory Stain');
      case ExperienceType.velocityLock: return _createPlaceholder('Velocity Lock');
      case ExperienceType.binaryNoise: return _createPlaceholder('Binary Noise');
      case ExperienceType.unseenTether: return _createPlaceholder('Unseen Tether');

      // --- INTERACTIONS ---
      case ExperienceType.tapSurprise: return _createTapSurprise();
      case ExperienceType.holdReveal: return _createHoldReveal();
      case ExperienceType.randomOutcome: return _createRandomOutcome();
      case ExperienceType.emotionalMeter: return _createEmotionalMeter();
      case ExperienceType.calmTouch: return _createCalmTouch();
      case ExperienceType.quoteReveal: return _createQuoteReveal();
      
      // --- LEGACY GAMES ---
      case ExperienceType.stack: return _createStackGame();
      case ExperienceType.jump: return _createJumpGame();
      case ExperienceType.ticTacToe: return _createTicTacToeGame();
      case ExperienceType.memory: return _createMemoryGame();
      case ExperienceType.brickBreaker: return _createBrickBreakerGame();
      // ... allow generic fallthrough for others if needed or map them
      default:
        return _createPlaceholder(game.name);
    }
  }

  // ... (Legacy factories kept for now or commented out to save space/time if not used in data source) ...
  // Minimal set for compilation since we removed them from Data Source:
  static GameInstances _createStackGame() {
    final game = StackGame();
    return GameInstances(GameWidget(game: game), game);
  }
   static GameInstances _createJumpGame() {
    final game = JumpGame();
    return GameInstances(GameWidget(game: game), game);
  }
  static GameInstances _createTicTacToeGame() {
    final ctrl = TicTacToeController();
    return GameInstances(TicTacToeWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createMemoryGame() {
    final ctrl = MemoryGameController();
    return GameInstances(MemoryGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createBrickBreakerGame() {
    final ctrl = BrickBreakerController();
    return GameInstances(BrickBreakerWidget(controller: ctrl), ctrl);
  }

  // --- NEW FACTORY METHODS ---
  static GameInstances _createKineticSilence() {
    return _createPlaceholder('Kinetic Silence');
  }

  static GameInstances _createCatchGame() {
    final ctrl = CatchGameController();
    return GameInstances(CatchGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createColorSwitchGame() {
    final ctrl = ColorSwitchController();
    return GameInstances(ColorSwitchWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createReactionGame() {
    final ctrl = ReactionGameController();
    return GameInstances(ReactionGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createSimonSaysGame() {
    final ctrl = SimonSaysController();
    return GameInstances(SimonSaysWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createWhackMoleGame() {
    final ctrl = WhackMoleController();
    return GameInstances(WhackMoleWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createNumberPuzzleGame() {
    final ctrl = NumberPuzzleController();
    return GameInstances(NumberPuzzleWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createSnakeGame() {
    final ctrl = SnakeGameController();
    return GameInstances(SnakeGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createPongGame() {
    final ctrl = PongController();
    return GameInstances(PongWidget(controller: ctrl), ctrl);
  }

  // Anti-Gravity Factories
  static GameInstances _createSurfaceParadox() {
    final ctrl = SurfaceParadoxGameController();
    return GameInstances(SurfaceParadoxGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createUntethered() {
    final ctrl = UntetheredGameController();
    return GameInstances(UntetheredGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createOrbitalVoid() {
    final ctrl = OrbitalVoidGameController();
    return GameInstances(OrbitalVoidGameWidget(controller: ctrl), ctrl);
  }
  
  // Advanced Anti-Gravity Factories
  static GameInstances _createDriftProtocol() {
    final ctrl = DriftProtocolGameController();
    return GameInstances(DriftProtocolGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createAxisShift() {
    final ctrl = AxisShiftGameController();
    return GameInstances(AxisShiftGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createRelativeObserver() {
    final ctrl = RelativeObserverGameController();
    return GameInstances(RelativeObserverGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createAnchorPoint() {
    final ctrl = AnchorPointGameController();
    return GameInstances(AnchorPointGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createCausalityEcho() {
    final ctrl = CausalityEchoGameController();
    return GameInstances(CausalityEchoGameWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createVoidMirror() {
    final ctrl = VoidMirrorGameController();
    return GameInstances(VoidMirrorGameWidget(controller: ctrl), ctrl);
  }
  
  // Cognitive Teasers
  static GameInstances _createSympatheticResonance() {
    final ctrl = SympatheticResonanceController();
    return GameInstances(SympatheticResonanceWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createVoidStare() {
    final ctrl = VoidStareController();
    return GameInstances(VoidStareWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createAnticipatoryShadow() {
    final ctrl = AnticipatoryShadowController();
    return GameInstances(AnticipatoryShadowWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createInvertedFriction() {
    final ctrl = InvertedFrictionController();
    return GameInstances(InvertedFrictionWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createChromaticSilence() {
    final ctrl = ChromaticSilenceController();
    return GameInstances(ChromaticSilenceWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createMetaDecay() {
    final ctrl = MetaDecayController();
    return GameInstances(MetaDecayWidget(controller: ctrl), ctrl);
  }
  static GameInstances _createObserverEffect() {
    final ctrl = ObserverEffectController();
    return GameInstances(ObserverEffectWidget(controller: ctrl), ctrl);
  }

  // Interaction Factories
  static GameInstances _createTapSurprise() {
    final ctrl = TapSurpriseController();
    return GameInstances(TapSurpriseWidget(controller: ctrl), InteractionAdapter(ctrl));
  }
  static GameInstances _createHoldReveal() {
    final ctrl = HoldRevealController();
    return GameInstances(HoldRevealWidget(controller: ctrl), InteractionAdapter(ctrl));
  }
  static GameInstances _createRandomOutcome() {
    final ctrl = RandomOutcomeController();
    return GameInstances(RandomOutcomeWidget(controller: ctrl), InteractionAdapter(ctrl));
  }
  static GameInstances _createEmotionalMeter() {
    final ctrl = EmotionalMeterController();
    return GameInstances(EmotionalMeterWidget(controller: ctrl), InteractionAdapter(ctrl));
  }
  static GameInstances _createCalmTouch() {
    final ctrl = CalmTouchController();
    return GameInstances(CalmTouchWidget(controller: ctrl), InteractionAdapter(ctrl));
  }
  static GameInstances _createQuoteReveal() {
    final ctrl = QuoteRevealController();
    return GameInstances(QuoteRevealWidget(controller: ctrl), InteractionAdapter(ctrl));
  }

  static GameInstances _createPlaceholder(String name) {
    final ctrl = GenericExperienceController();
    return GameInstances(
      Center(child: Text('Experience: $name')),
      ctrl,
    );
  }
}
