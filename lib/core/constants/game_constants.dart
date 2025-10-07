/// Constants specific to each game.
class WordleConstants {
  WordleConstants._();

  /// Length of words in Wordle
  static const int wordLength = 5;

  /// Maximum number of attempts allowed
  static const int maxAttempts = 6;

  /// SharedPreferences key for stats
  static const String statsKey = 'wordle_stats';

  /// SharedPreferences key for game state
  static const String gameStateKey = 'wordle_game_state';

  /// Path to word list asset
  static const String wordListPath = 'assets/wordle/words.txt';

  /// Game ID for high scores
  static const String gameId = 'wordle';
}

class HangmanConstants {
  HangmanConstants._();

  /// Maximum incorrect guesses allowed
  static const int maxIncorrectGuesses = 6;

  /// Initial number of hints available
  static const int initialHints = 2;

  /// SharedPreferences key for game state
  static const String gameStateKey = 'hangman_game_state';

  /// Game ID for high scores
  static const String gameId = 'hangman';
}

class SnakeConstants {
  SnakeConstants._();

  /// Grid size for the snake game board
  static const int gridSize = 20;

  /// SharedPreferences key for high score
  static const String highScoreKey = 'snake_high_score';

  /// Game ID for high scores
  static const String gameId = 'snake';

  /// Countdown duration before game starts
  static const int countdownSeconds = 3;
}

/// Common game-related constants
class GameConstants {
  GameConstants._();

  /// Animation duration for confetti
  static const Duration confettiDuration = Duration(seconds: 5);

  /// Duration for game over dialog animations
  static const Duration gameOverAnimationDuration = Duration(milliseconds: 400);
}
