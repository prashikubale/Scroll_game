
/// The shared interface that all mini-games must implement.
/// This allows the feed to control the game lifecycle and retrieve scores.
abstract class MiniGame {
  /// Starts or resumes the game.
  void start();

  /// Pauses the game (e.g., when scrolled away).
  void pause();

  /// Resets the game to its initial state.
  void reset();

  /// Gets the current score of the game.
  int get score;
  /// Disposes resources used by the game.
  void dispose();
}
