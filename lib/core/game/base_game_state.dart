import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngames/core/game/base_game.dart';
import 'package:ngames/core/utils/logger.dart';
import 'package:ngames/shared/services/game_state_service.dart';
import 'package:ngames/services/high_score_service.dart';
import 'package:ngames/services/auth_service.dart';
import 'package:ngames/models/game_high_score_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract base class for game state management.
/// Extends this class to create stateful widgets for games.
/// Note: Your widget should extend ConsumerStatefulWidget, not StatefulWidget
abstract class BaseGameState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T>
    implements BaseGame {
  GameStateService? _gameStateService;
  HighScoreService? _highScoreService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _gameStateService = GameStateService(prefs);
  }

  /// Set the high score service (injected from widget)
  set highScoreService(HighScoreService? service) {
    _highScoreService = service;
  }

  @override
  Future<void> saveGameState() async {
    if (_gameStateService == null) {
      AppLogger.warning('GameStateService not initialized', 'GAME');
      return;
    }

    try {
      final state = getGameStateData();
      await _gameStateService!.saveState(gameId, state);
      AppLogger.debug('Game state saved for $gameId', 'GAME');
    } catch (e, st) {
      AppLogger.error('Failed to save game state for $gameId', e, st, 'GAME');
    }
  }

  @override
  Future<bool> loadGameState() async {
    if (_gameStateService == null) {
      AppLogger.warning('GameStateService not initialized', 'GAME');
      return false;
    }

    try {
      final hasState = await _gameStateService!.hasState(gameId);
      if (!hasState) {
        AppLogger.debug('No saved state found for $gameId', 'GAME');
        return false;
      }

      final state = await _gameStateService!.loadState(gameId);
      if (state != null) {
        restoreGameStateData(state);
        AppLogger.debug('Game state loaded for $gameId', 'GAME');
        return true;
      }
      return false;
    } catch (e, st) {
      AppLogger.error('Failed to load game state for $gameId', e, st, 'GAME');
      return false;
    }
  }

  @override
  Future<void> clearGameState() async {
    if (_gameStateService == null) {
      AppLogger.warning('GameStateService not initialized', 'GAME');
      return;
    }

    try {
      await _gameStateService!.clearState(gameId);
      AppLogger.debug('Game state cleared for $gameId', 'GAME');
    } catch (e, st) {
      AppLogger.error('Failed to clear game state for $gameId', e, st, 'GAME');
    }
  }

  @override
  Future<void> onGameWon() async {
    AppLogger.info('Game won: $gameId with score: $currentScore', 'GAME');
    await clearGameState();
    await saveHighScore();
  }

  @override
  Future<void> onGameLost() async {
    AppLogger.info('Game lost: $gameId', 'GAME');
    await clearGameState();
  }

  /// Save high score if applicable
  Future<void> saveHighScore() async {
    if (_highScoreService == null || currentScore <= 0) return;

    try {
      // Get current user info
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) {
        AppLogger.warning('No user logged in to save high score', 'GAME');
        return;
      }

      final highScore = GameHighScore(
        gameId: gameId,
        userId: user.uid,
        userName: user.email ?? 'Anonymous',
        score: currentScore,
        timestamp: DateTime.now(),
      );
      await _highScoreService!.addHighScore(highScore);
      AppLogger.info('High score saved: $currentScore for $gameId', 'GAME');
    } catch (e, st) {
      AppLogger.error('Failed to save high score for $gameId', e, st, 'GAME');
    }
  }

  /// Get the current game state as a Map for serialization
  /// Subclasses must implement this to provide their specific state data
  Map<String, dynamic> getGameStateData();

  /// Restore game state from a Map
  /// Subclasses must implement this to restore their specific state data
  void restoreGameStateData(Map<String, dynamic> state);
}

/// Base class for games with high score tracking
/// Note: Your widget should extend ConsumerStatefulWidget
abstract class BaseHighScoreGameState<T extends ConsumerStatefulWidget>
    extends BaseGameState<T>
    with HighScoreGame {
  @override
  Future<int?> getHighScore() async {
    if (_highScoreService == null) return null;

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return null;

      // Get user's personal best by streaming scores and taking first
      final scoresStream = _highScoreService!.getHighScores(gameId, limit: 1);
      final scores = await scoresStream.first;
      if (scores.isEmpty) return null;
      return scores.first.score;
    } catch (e, st) {
      AppLogger.error('Failed to get high score for $gameId', e, st, 'GAME');
      return null;
    }
  }

  @override
  Future<void> updateHighScore(int score) async {
    if (_highScoreService == null) return;

    try {
      final currentHigh = await getHighScore();
      if (currentHigh == null || score > currentHigh) {
        final user = ref.read(firebaseAuthProvider).currentUser;
        if (user == null) {
          AppLogger.warning('No user logged in to update high score', 'GAME');
          return;
        }

        final highScore = GameHighScore(
          gameId: gameId,
          userId: user.uid,
          userName: user.email ?? 'Anonymous',
          score: score,
          timestamp: DateTime.now(),
        );
        await _highScoreService!.addHighScore(highScore);
        AppLogger.info('New high score: $score for $gameId', 'GAME');
      }
    } catch (e, st) {
      AppLogger.error('Failed to update high score for $gameId', e, st, 'GAME');
    }
  }
}
