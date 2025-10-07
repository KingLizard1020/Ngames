/// Base exception class for game-specific errors.
class GameException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  GameException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) {
      return 'GameException [$code]: $message';
    }
    return 'GameException: $message';
  }
}

/// Exception thrown when Firebase operations fail.
class FirebaseException extends GameException {
  FirebaseException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'FirebaseException: $message';
}

/// Exception thrown when authentication fails.
class AuthException extends GameException {
  AuthException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when game state loading/saving fails.
class GameStateException extends GameException {
  final String gameId;

  GameStateException(
    super.message,
    this.gameId, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'GameStateException [$gameId]: $message';
}

/// Exception thrown when network operations fail.
class NetworkException extends GameException {
  NetworkException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'NetworkException: $message';
}
