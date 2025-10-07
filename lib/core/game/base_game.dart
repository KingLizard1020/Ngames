/// Abstract base class for all games in the app.
/// Provides common functionality and structure that all games should implement.
abstract class BaseGame {
  /// Unique identifier for the game (e.g., 'wordle', 'snake', 'hangman')
  String get gameId;

  /// Display name of the game
  String get gameName;

  /// Initialize the game state
  Future<void> initializeGame();

  /// Save the current game state
  Future<void> saveGameState();

  /// Load a saved game state
  Future<bool> loadGameState();

  /// Clear/reset the game state
  Future<void> clearGameState();

  /// Check if game is over (won or lost)
  bool get isGameOver;

  /// Check if game was won
  bool get isGameWon;

  /// Get current score
  int get currentScore;

  /// Handle game win
  Future<void> onGameWon();

  /// Handle game loss
  Future<void> onGameLost();

  /// Reset the game to initial state
  void resetGame();
}

/// Mixin for games that need high score tracking
mixin HighScoreGame on BaseGame {
  /// Get the high score for this game
  Future<int?> getHighScore();

  /// Update high score if current score is higher
  Future<void> updateHighScore(int score);
}

/// Mixin for games with difficulty levels
mixin DifficultyLevelGame on BaseGame {
  /// Available difficulty levels
  List<String> get difficultyLevels;

  /// Current difficulty level
  String get currentDifficulty;

  /// Set difficulty level
  set currentDifficulty(String level);
}

/// Mixin for games with timer/countdown
mixin TimedGame on BaseGame {
  /// Start the game timer
  void startTimer();

  /// Stop the game timer
  void stopTimer();

  /// Pause the game timer
  void pauseTimer();

  /// Resume the game timer
  void resumeTimer();

  /// Get remaining time in seconds
  int get remainingTime;

  /// Check if timer is running
  bool get isTimerRunning;
}

/// Mixin for games with lives/attempts
mixin LivesGame on BaseGame {
  /// Maximum number of lives/attempts
  int get maxLives;

  /// Current number of lives/attempts remaining
  int get currentLives;

  /// Decrement lives by one
  void loseLife();

  /// Check if out of lives
  bool get isOutOfLives;
}
