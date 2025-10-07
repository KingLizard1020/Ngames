# NGames 🎮

A collection of fun and engaging mobile games built with Flutter for iOS and Android.

## About

NGames is a personal project created by Kailash for Neely, featuring classic games with modern UI and social features like high scores and messaging.

## Features

### Games
- **Wordle** - Guess the 5-letter word in 6 attempts
- **Hangman** - Classic word-guessing game with categories
- **Snake** - Navigate the snake to eat food and grow

### Features
- Confetti celebrations when you win
- Global high scores leaderboard
- Auto-save game progress (resume anytime!)
- Material Design 3 UI
- Dark/Light theme support
- Firebase authentication
- Cross-platform (iOS & Android)

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.7.2)
- Dart SDK (>= 3.7.2)
- iOS: Xcode 15+, CocoaPods, iOS 16.0+
- Android: Android Studio, Android SDK

### Installation

1. Clone and install dependencies:
   ```bash
   git clone https://github.com/KingLizard1020/Ngames.git
   cd Ngames
   flutter pub get
   cd ios && pod install && cd ..
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/                    # Core utilities and architecture
│   ├── constants/          # App-wide constants
│   ├── errors/             # Custom exceptions
│   ├── game/               # Base game classes and interfaces
│   └── utils/              # Utilities (logger, etc.)
├── games/                  # Game implementations
│   ├── wordle/
│   ├── hangman/
│   └── snake/
├── models/                 # Data models
├── routing/                # Navigation (GoRouter)
├── screens/                # UI screens
├── services/               # Business logic services
├── shared/                 # Shared resources
│   ├── services/           # Shared services (GameStateService)
│   └── widgets/            # Shared widgets (GameOverDialog)
└── widgets/                # Reusable widgets
```

## Architecture

NGames uses a modular architecture with base classes and shared services to ensure consistency and reduce code duplication across games.

### Key Components:

- **BaseGame**: Abstract interface that all games implement
- **BaseGameState**: Base class providing automatic state persistence and high score tracking
- **GameStateService**: Unified game state management using SharedPreferences
- **Mixins**: HighScoreGame, TimedGame, LivesGame, DifficultyLevelGame

For detailed architecture documentation, see [GAME_ARCHITECTURE.md](GAME_ARCHITECTURE.md).

## Development

```bash
# Run tests
flutter test

# Generate mocks
dart run build_runner build --delete-conflicting-outputs

# Deploy Firebase rules
firebase deploy --only firestore:rules

# Run in release mode
flutter run --release

# Build for iOS
flutter build ios --release

# Build for Android
flutter build apk --release
```

## Adding a New Game

1. Create game screen extending `BaseHighScoreGameState`
2. Implement required methods (getGameStateData, restoreGameStateData)
3. Add game route in `app_router.dart`
4. Add navigation button in home screen
5. Add game constants in `game_constants.dart`

See [GAME_ARCHITECTURE.md](GAME_ARCHITECTURE.md) for detailed guide.

## Recent Updates

### October 7, 2025
- Refactored code for better maintainability

See [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) for complete details.

## Credits

Created with ❤️ by Kailash for Neely
