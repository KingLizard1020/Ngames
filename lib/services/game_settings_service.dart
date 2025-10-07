import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngames/services/theme_service.dart'; // To reuse sharedPreferencesProvider

const String _snakeDifficultyKey = 'snake_difficulty';

enum SnakeDifficulty { easy, medium, hard }

class SnakeDifficultyNotifier extends StateNotifier<SnakeDifficulty> {
  SnakeDifficultyNotifier(this._prefs) : super(SnakeDifficulty.medium) {
    _loadDifficulty();
  }

  final SharedPreferences _prefs;

  Future<void> _loadDifficulty() async {
    final difficultyString = _prefs.getString(_snakeDifficultyKey);
    state = _stringToDifficulty(difficultyString);
  }

  Future<void> setDifficulty(SnakeDifficulty difficulty) async {
    state = difficulty;
    await _prefs.setString(
      _snakeDifficultyKey,
      _difficultyToString(difficulty),
    );
  }

  String _difficultyToString(SnakeDifficulty difficulty) {
    return difficulty.toString().split('.').last;
  }

  SnakeDifficulty _stringToDifficulty(String? difficultyString) {
    switch (difficultyString) {
      case 'easy':
        return SnakeDifficulty.easy;
      case 'hard':
        return SnakeDifficulty.hard;
      case 'medium':
      default:
        return SnakeDifficulty.medium;
    }
  }

  Duration get currentSpeed {
    switch (state) {
      case SnakeDifficulty.easy:
        return const Duration(milliseconds: 300);
      case SnakeDifficulty.medium:
        return const Duration(milliseconds: 200);
      case SnakeDifficulty.hard:
        return const Duration(milliseconds: 100);
    }
  }

  String get currentDifficultyName => _difficultyToString(state);
}

// Provider for SnakeDifficultyNotifier
final snakeDifficultyNotifierProvider = StateNotifierProvider<
  SnakeDifficultyNotifier,
  SnakeDifficulty
>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  // The sharedPreferencesProvider in theme_service.dart is a Provider<SharedPreferences>,
  // not a FutureProvider, so this direct watch should work if main.dart overrides it correctly.
  return SnakeDifficultyNotifier(prefs);
});
