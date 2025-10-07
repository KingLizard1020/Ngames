# Game Architecture Guide

This document explains the game architecture and how to create new games using the base classes.

## Overview

The NGames app uses a modular architecture with shared services and base classes to reduce code duplication and provide consistent functionality across all games.

## Core Components

### 1. Base Game Interface (`lib/core/game/base_game.dart`)

The `BaseGame` abstract class defines the contract that all games must implement:

```dart
abstract class BaseGame {
  String get gameId;              // Unique identifier (e.g., 'wordle')
  String get gameName;            // Display name (e.g., 'Wordle')
  bool get isGameOver;            // Is the game finished?
  bool get isGameWon;             // Did the player win?
  int get currentScore;           // Current game score
  
  Future<void> initializeGame();  // Setup game state
  Future<void> saveGameState();   // Persist current state
  Future<bool> loadGameState();   // Restore saved state
  Future<void> clearGameState();  // Clear saved state
  Future<void> onGameWon();       // Handle win event
  Future<void> onGameLost();      // Handle loss event
  void resetGame();               // Reset to initial state
}
```

### 2. Game Mixins

The architecture provides several mixins for common game features:

#### `HighScoreGame`
For games that track high scores:
```dart
mixin HighScoreGame on BaseGame {
  Future<int?> getHighScore();
  Future<void> updateHighScore(int score);
}
```

#### `DifficultyLevelGame`
For games with difficulty settings:
```dart
mixin DifficultyLevelGame on BaseGame {
  List<String> get difficultyLevels;
  String get currentDifficulty;
  set currentDifficulty(String level);
}
```

#### `TimedGame`
For games with timers:
```dart
mixin TimedGame on BaseGame {
  void startTimer();
  void stopTimer();
  void pauseTimer();
  void resumeTimer();
  int get remainingTime;
  bool get isTimerRunning;
}
```

#### `LivesGame`
For games with lives/attempts:
```dart
mixin LivesGame on BaseGame {
  int get maxLives;
  int get currentLives;
  void loseLife();
  bool get isOutOfLives;
}
```

### 3. Base Game State (`lib/core/game/base_game_state.dart`)

The `BaseGameState` class provides default implementations for common game functionality:

- **Automatic state persistence** using `GameStateService`
- **High score tracking** via `HighScoreService`
- **Centralized logging** with `AppLogger`
- **Firebase user integration** for multiplayer features

#### Usage Example:

```dart
class MyGameState extends BaseHighScoreGameState<MyGame> {
  @override
  String get gameId => 'my-game';
  
  @override
  String get gameName => 'My Awesome Game';
  
  @override
  bool get isGameOver => _isGameOver;
  
  @override
  bool get isGameWon => _isGameWon;
  
  @override
  int get currentScore => _score;
  
  @override
  Future<void> initializeGame() async {
    // Initialize game-specific state
    _score = 0;
    _isGameOver = false;
    // Try to load saved state
    await loadGameState();
  }
  
  @override
  Map<String, dynamic> getGameStateData() {
    return {
      'score': _score,
      'level': _currentLevel,
      'timeRemaining': _timeRemaining,
    };
  }
  
  @override
  void restoreGameStateData(Map<String, dynamic> state) {
    setState(() {
      _score = state['score'] ?? 0;
      _currentLevel = state['level'] ?? 1;
      _timeRemaining = state['timeRemaining'] ?? 60;
    });
  }
  
  @override
  void resetGame() {
    setState(() {
      _score = 0;
      _currentLevel = 1;
      _isGameOver = false;
      _isGameWon = false;
    });
  }
}
```

## Shared Services

### GameStateService (`lib/shared/services/game_state_service.dart`)

Handles saving and loading game state to/from SharedPreferences:

```dart
final gameStateService = GameStateService(prefs);

// Save state
await gameStateService.saveState('wordle', {
  'targetWord': 'CRANE',
  'attempts': 3,
});

// Load state
final state = await gameStateService.loadState('wordle');

// Check if state exists
final hasState = await gameStateService.hasState('wordle');

// Clear state
await gameStateService.clearState('wordle');
```

### HighScoreService (`lib/services/high_score_service.dart`)

Manages high scores in Firebase Firestore:

```dart
// Add a high score
await highScoreService.addHighScore(GameHighScore(
  gameId: 'snake',
  userId: currentUser.uid,
  userName: currentUser.email!,
  score: 1500,
  timestamp: DateTime.now(),
));

// Get high scores for a game
final scoresStream = highScoreService.getHighScores(
  'snake',
  limit: 10,
  lowerIsBetter: false,
);
```

## Shared Widgets

### GameOverDialog (`lib/shared/widgets/game_over_dialog.dart`)

Reusable dialog for game over states with confetti support:

```dart
await GameOverDialog.show(
  context: context,
  isWon: true,
  score: 1500,
  gameId: 'snake',
  gameName: 'Snake',
  showConfetti: true,
  customContent: Text('New high score!'),
);
```

### ConfettiOverlay (`lib/widgets/confetti_overlay.dart`)

Wraps any widget with confetti celebration:

```dart
ConfettiOverlay(
  showConfetti: _showConfetti,
  child: MyGameContent(),
)
```

## Creating a New Game

### Step 1: Create the Game Screen

```dart
class MyNewGame extends ConsumerStatefulWidget {
  const MyNewGame({super.key});

  @override
  ConsumerState<MyNewGame> createState() => _MyNewGameState();
}
```

### Step 2: Extend BaseGameState

```dart
class _MyNewGameState extends BaseHighScoreGameState<MyNewGame>
    with TimedGame, LivesGame {
  
  // Game-specific state
  int _score = 0;
  int _currentLives = 3;
  bool _isGameOver = false;
  bool _isGameWon = false;
  
  // Implement required BaseGame properties
  @override
  String get gameId => 'my-new-game';
  
  @override
  String get gameName => 'My New Game';
  
  @override
  bool get isGameOver => _isGameOver;
  
  @override
  bool get isGameWon => _isGameWon;
  
  @override
  int get currentScore => _score;
  
  // Implement LivesGame mixin
  @override
  int get maxLives => 3;
  
  @override
  int get currentLives => _currentLives;
  
  @override
  void loseLife() {
    setState(() {
      _currentLives--;
      if (_currentLives <= 0) {
        _isGameOver = true;
        onGameLost();
      }
    });
  }
  
  @override
  bool get isOutOfLives => _currentLives <= 0;
  
  // Implement game lifecycle
  @override
  Future<void> initializeGame() async {
    _score = 0;
    _currentLives = 3;
    _isGameOver = false;
    _isGameWon = false;
    
    // Try to load saved state
    final loaded = await loadGameState();
    if (!loaded) {
      // Start new game
      startTimer();
    }
  }
  
  @override
  void resetGame() {
    clearGameState();
    initializeGame();
  }
  
  // State persistence
  @override
  Map<String, dynamic> getGameStateData() {
    return {
      'score': _score,
      'lives': _currentLives,
      'isGameOver': _isGameOver,
      'isGameWon': _isGameWon,
    };
  }
  
  @override
  void restoreGameStateData(Map<String, dynamic> state) {
    if (mounted) {
      setState(() {
        _score = state['score'] ?? 0;
        _currentLives = state['lives'] ?? 3;
        _isGameOver = state['isGameOver'] ?? false;
        _isGameWon = state['isGameWon'] ?? false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Use ConfettiOverlay for win celebration
    return ConfettiOverlay(
      showConfetti: _isGameWon,
      child: Scaffold(
        appBar: AppBar(title: Text(gameName)),
        body: Column(
          children: [
            Text('Score: $_score'),
            Text('Lives: $_currentLives'),
            // Game content here
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Add to Router

Add the game route in `lib/routing/app_router.dart`:

```dart
GoRoute(
  path: '/game/my-new-game',
  pageBuilder: (context, state) => 
      const MaterialPage(child: MyNewGame()),
),
```

### Step 4: Add to Home Screen

Add a button or card to navigate to your game in `lib/screens/home/home_screen.dart`.

## Best Practices

1. **Always call `initializeGame()` in `initState()`**
2. **Save state frequently** (after each move/action)
3. **Clear state on game over** to prevent stale data
4. **Use `AppLogger` for debugging** instead of print statements
5. **Handle errors gracefully** with try-catch blocks
6. **Test state persistence** by closing and reopening the app
7. **Use mixins for common features** instead of duplicating code
8. **Follow existing game structure** for consistency

## Constants

Game-specific constants should be defined in `lib/core/constants/game_constants.dart`:

```dart
class MyNewGameConstants {
  static const int maxLives = 3;
  static const int timeLimit = 60;
  static const int pointsPerLevel = 100;
}
```

## Testing

Create tests for your game in `test/games/my_new_game/`:

```dart
void main() {
  group('MyNewGame', () {
    testWidgets('initializes correctly', (tester) async {
      await tester.pumpWidget(createTestableWidget(
        child: const MyNewGame(),
      ));
      
      expect(find.text('Score: 0'), findsOneWidget);
      expect(find.text('Lives: 3'), findsOneWidget);
    });
  });
}
```

## Debugging

Use `AppLogger` for debugging:

```dart
AppLogger.debug('Player moved to position $x, $y', 'MY_GAME');
AppLogger.info('Level completed with score: $_score', 'MY_GAME');
AppLogger.warning('Low lives remaining: $_currentLives', 'MY_GAME');
AppLogger.error('Failed to save state', e, st, 'MY_GAME');
```

## Performance Tips

1. **Minimize setState() calls** - batch updates when possible
2. **Use const constructors** for widgets that don't change
3. **Dispose controllers** in dispose() method
4. **Avoid expensive operations** in build() method
5. **Use RepaintBoundary** for complex animations

## Summary

The base game architecture provides:
- ✅ Automatic state persistence
- ✅ High score tracking
- ✅ Centralized logging
- ✅ Reusable UI components
- ✅ Consistent game structure
- ✅ Easy testing setup
- ✅ Firebase integration

Follow this guide to create new games quickly while maintaining code quality and consistency!
