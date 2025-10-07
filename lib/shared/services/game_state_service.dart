import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngames/core/errors/exceptions.dart';
import 'package:ngames/core/utils/logger.dart';

/// Service for managing game state persistence across all games.
///
/// Provides a unified interface for saving and loading game progress,
/// allowing players to resume games after closing the app.
class GameStateService {
  final SharedPreferences _prefs;

  GameStateService(this._prefs);

  /// Saves game state to persistent storage.
  ///
  /// [gameId]: Unique identifier for the game (e.g., 'wordle', 'hangman')
  /// [state]: Game state data to persist as a Map
  ///
  /// Throws [GameStateException] if save fails.
  Future<void> saveState(String gameId, Map<String, dynamic> state) async {
    try {
      final key = _getKey(gameId);
      final jsonString = jsonEncode(state);
      final success = await _prefs.setString(key, jsonString);

      if (!success) {
        throw GameStateException('Failed to save state', gameId);
      }

      AppLogger.debug('Game state saved for $gameId', 'GameState');
    } catch (e) {
      AppLogger.error('Failed to save game state', e, null, 'GameState');
      throw GameStateException(
        'Failed to save game state: $e',
        gameId,
        originalError: e,
      );
    }
  }

  /// Loads game state from persistent storage.
  ///
  /// [gameId]: Unique identifier for the game
  ///
  /// Returns the saved state as a Map, or null if no state exists.
  /// Throws [GameStateException] if load fails due to corrupted data.
  Future<Map<String, dynamic>?> loadState(String gameId) async {
    try {
      final key = _getKey(gameId);
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        AppLogger.debug('No saved state found for $gameId', 'GameState');
        return null;
      }

      final state = jsonDecode(jsonString) as Map<String, dynamic>;
      AppLogger.debug('Game state loaded for $gameId', 'GameState');
      return state;
    } catch (e) {
      AppLogger.error('Failed to load game state', e, null, 'GameState');
      // Clear corrupted state
      await clearState(gameId);
      throw GameStateException(
        'Failed to load game state: $e',
        gameId,
        originalError: e,
      );
    }
  }

  /// Clears saved game state.
  ///
  /// [gameId]: Unique identifier for the game
  ///
  /// Returns true if state was cleared successfully.
  Future<bool> clearState(String gameId) async {
    try {
      final key = _getKey(gameId);
      final success = await _prefs.remove(key);
      AppLogger.debug('Game state cleared for $gameId', 'GameState');
      return success;
    } catch (e) {
      AppLogger.error('Failed to clear game state', e, null, 'GameState');
      return false;
    }
  }

  /// Checks if a saved state exists for a game.
  bool hasState(String gameId) {
    final key = _getKey(gameId);
    return _prefs.containsKey(key);
  }

  /// Generates the storage key for a game's state.
  String _getKey(String gameId) => '${gameId}_game_state';
}
