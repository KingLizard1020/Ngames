import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ngames/widgets/settings_dialog.dart';
import 'package:ngames/widgets/confetti_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngames/services/game_settings_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ngames/services/high_score_service.dart'; // Import HighScoreService
import 'package:ngames/models/game_high_score_model.dart'; // Import GameHighScore model

enum Direction { up, down, left, right }

class SnakeScreen extends ConsumerStatefulWidget {
  // Change to ConsumerStatefulWidget
  const SnakeScreen({super.key});

  @override
  ConsumerState<SnakeScreen> createState() => _SnakeScreenState(); // Change to ConsumerState
}

class _SnakeScreenState extends ConsumerState<SnakeScreen>
    with SingleTickerProviderStateMixin {
  // Change to ConsumerState
  static const int _gridSize = 20;
  static const String _highScoreKey =
      'snake_high_score'; // Key for SharedPreferences

  List<Offset> _snake = [];
  Offset _food = const Offset(0, 0);
  Direction _direction = Direction.right;
  bool _isPlaying = false;
  bool _isPaused = false; // New state for pause
  Ticker? _ticker;
  Duration _lastUpdate = Duration.zero; // Track last update time
  int _score = 0;
  int _highScore = 0; // New state for high score
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _eatPlayer = AudioPlayer();

  int _countdown = 3;
  bool _showGameOverEffect = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _audioPlayer.dispose();
    _eatPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
    });
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, _highScore);
  }

  void _startCountdown() {
    setState(() {
      _countdown = 3;
      _isPlaying = false;
      _isPaused = false;
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    final snakeDifficulty = ref.read(snakeDifficultyNotifierProvider.notifier);
    final gameSpeed = snakeDifficulty.currentSpeed;

    setState(() {
      _snake = [const Offset(_gridSize / 2, _gridSize / 2)];
      _direction = Direction.right;
      _generateFood();
      _score = 0;
      _isPlaying = true;
      _isPaused = false;
      _showGameOverEffect = false;
      _lastUpdate = Duration.zero; // Reset the timer
    });
    _ticker?.dispose();
    _ticker = createTicker((elapsed) {
      if (_isPlaying && !_isPaused) {
        // Move snake at intervals based on gameSpeed
        if (elapsed - _lastUpdate >= gameSpeed) {
          _lastUpdate = elapsed;
          _moveSnake();
        }
      }
    });
    _ticker?.start();
  }

  void _generateFood() {
    final random = Random();
    Offset newFood;
    do {
      newFood = Offset(
        random.nextInt(_gridSize).toDouble(),
        random.nextInt(_gridSize).toDouble(),
      );
    } while (_snake.contains(newFood)); // Ensure food is not on the snake
    _food = newFood;
  }

  void _moveSnake() {
    if (!_isPlaying) return;

    setState(() {
      Offset head = _snake.first;
      Offset newHead;

      switch (_direction) {
        case Direction.up:
          newHead = Offset(head.dx, head.dy - 1);
          break;
        case Direction.down:
          newHead = Offset(head.dx, head.dy + 1);
          break;
        case Direction.left:
          newHead = Offset(head.dx - 1, head.dy);
          break;
        case Direction.right:
          newHead = Offset(head.dx + 1, head.dy);
          break;
      }

      // Wall collision
      if (newHead.dx < 0 ||
          newHead.dx >= _gridSize ||
          newHead.dy < 0 ||
          newHead.dy >= _gridSize) {
        _gameOver();
        return;
      }

      // Self-collision (excluding the tail that will move away)
      for (int i = 0; i < _snake.length - 1; i++) {
        if (_snake[i] == newHead) {
          _gameOver();
          return;
        }
      }

      _snake.insert(0, newHead); // Add new head

      if (newHead == _food) {
        _score++;
        _generateFood();
        _eatPlayer.play(AssetSource('audio/crunch.mp3'));
      } else {
        _snake.removeLast();
      }
    });
  }

  void _gameOver() async {
    // Make async for high score submission
    final currentScore = _score; // Capture score before potential reset
    bool newHighScoreAchieved = false;

    if (currentScore > _highScore) {
      newHighScoreAchieved = true;
      _highScore = currentScore;
      await _saveHighScore(); // Save local high score
    }

    // Submit to global high scores regardless of whether it beat local high score
    // (Global leaderboard might have different criteria or just track all game completions)
    // However, typically you'd submit if it's a "good" score or meets some criteria.
    // For now, let's submit every score, or only if it's a new local high score.
    // Let's choose to submit if it's a new local high score for simplicity here.
    if (newHighScoreAchieved || currentScore > 0) {
      // Or some other condition like currentScore > 0
      final highScoreService = ref.read(highScoreServiceProvider);
      final userId = highScoreService.getCurrentUserId();
      final userName = highScoreService.getCurrentUserName();

      if (userId != null && userName != null) {
        final snakeHighScore = GameHighScore(
          userId: userId,
          userName: userName,
          gameId: 'snake',
          score: currentScore,
          timestamp: DateTime.now(),
          scoreType: 'points', // Higher is better
        );
        await highScoreService.addHighScore(snakeHighScore);
      }
    }

    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _ticker?.stop();
      _showGameOverEffect = true;
    });
    _audioPlayer.play(AssetSource('audio/death.mp3'));
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _showGameOverEffect = false;
      });
    });

    final theme = Theme.of(context);
    final bool beatHighScore = newHighScoreAchieved;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ConfettiOverlay(
          showConfetti: beatHighScore,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            title: Text(
              beatHighScore ? 'New High Score!' : 'Game Over',
              style: TextStyle(
                color:
                    beatHighScore
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your score: $currentScore',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'High Score: $_highScore',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                if (_showGameOverEffect)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: Icon(
                        Icons.flash_on,
                        color: theme.colorScheme.error,
                        size: 48,
                      ),
                    ),
                  ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                ),
                child: const Text('Main Menu'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  GoRouter.of(context).go('/');
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Play Again'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _startCountdown();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _togglePause() {
    setState(() {
      if (!_isPlaying) return;
      _isPaused = !_isPaused;
      if (_isPaused) {
        _showPauseMenu();
      }
    });
  }

  void _showPauseMenu() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          title: Text(
            'Game Paused',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'What would you like to do?',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
              ),
              child: const Text('Quit to Menu'),
              onPressed: () {
                _ticker?.stop();
                _isPlaying = false;
                _isPaused = false;
                Navigator.of(dialogContext).pop();
                GoRouter.of(context).go('/');
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Resume'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _isPaused = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showHowToPlayDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          title: Text(
            'How to Play Snake',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Use the arrow buttons or swipe to control the snake.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'Eat the red food to grow longer and increase your score.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'Avoid hitting the walls or the snake\'s own body.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Got it!'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentDifficultyName =
        ref
            .read(snakeDifficultyNotifierProvider.notifier)
            .currentDifficultyName;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double gameBoardSize = screenWidth * 0.9;
    final double cellSize = gameBoardSize / _gridSize;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                'Score: $_score | High: $_highScore | Difficulty: ${currentDifficultyName.toUpperCase()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHowToPlayDialog,
            tooltip: 'How to Play',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => const SettingsDialog(),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: GestureDetector(
                        onVerticalDragEnd: (details) {
                          if (!_isPlaying || _isPaused) return;
                          if (details.primaryVelocity == null) return;
                          if (details.primaryVelocity! < -200) {
                            if (_direction != Direction.down) {
                              _direction = Direction.up;
                            }
                          } else if (details.primaryVelocity! > 200) {
                            if (_direction != Direction.up) {
                              _direction = Direction.down;
                            }
                          }
                        },
                        onHorizontalDragEnd: (details) {
                          if (!_isPlaying || _isPaused) return;
                          if (details.primaryVelocity == null) return;
                          if (details.primaryVelocity! < -200) {
                            if (_direction != Direction.right) {
                              _direction = Direction.left;
                            }
                          } else if (details.primaryVelocity! > 200) {
                            if (_direction != Direction.left) {
                              _direction = Direction.right;
                            }
                          }
                        },
                        child: Container(
                          width: gameBoardSize,
                          height: gameBoardSize,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.5),
                              width: 2,
                            ),
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomPaint(
                            painter: SnakePainter(
                              _snake,
                              _food,
                              cellSize,
                              theme.colorScheme,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildControls(theme),
            ],
          ),
          if (_countdown > 0 && !_isPlaying)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 96,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionButton(
                theme,
                Icons.keyboard_arrow_up,
                Direction.up,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDirectionButton(
                theme,
                Icons.keyboard_arrow_left,
                Direction.left,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.all(16),
                  shape: const CircleBorder(),
                ),
                onPressed: _togglePause, // Changed to toggle pause
                child: Icon(
                  _isPaused || !_isPlaying ? Icons.play_arrow : Icons.pause,
                  size: 30,
                ),
              ),
              _buildDirectionButton(
                theme,
                Icons.keyboard_arrow_right,
                Direction.right,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionButton(
                theme,
                Icons.keyboard_arrow_down,
                Direction.down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(
    ThemeData theme,
    IconData icon,
    Direction buttonDirection,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed:
            !_isPlaying
                ? null
                : () {
                  // Prevent reversing direction directly
                  if (buttonDirection == Direction.up &&
                      _direction == Direction.down) {
                    return;
                  }
                  if (buttonDirection == Direction.down &&
                      _direction == Direction.up) {
                    return;
                  }
                  if (buttonDirection == Direction.left &&
                      _direction == Direction.right) {
                    return;
                  }
                  if (buttonDirection == Direction.right &&
                      _direction == Direction.left) {
                    return;
                  }
                  _direction = buttonDirection;
                },
        child: Icon(icon, size: 28),
      ),
    );
  }
}

class SnakePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final double cellSize;
  final ColorScheme colorScheme;

  SnakePainter(this.snake, this.food, this.cellSize, this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final snakePaint =
        Paint()..color = colorScheme.primary; // Use theme primary for snake
    final foodPaint =
        Paint()..color = colorScheme.error; // Use theme error for food

    // Draw snake
    for (Offset part in snake) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            part.dx * cellSize + 2, // Small padding
            part.dy * cellSize + 2, // Small padding
            cellSize - 4, // Adjust for padding
            cellSize - 4, // Adjust for padding
          ),
          const Radius.circular(4), // Rounded corners for snake segments
        ),
        snakePaint,
      );
    }

    // Draw food
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          food.dx * cellSize + cellSize * 0.15, // Center food a bit
          food.dy * cellSize + cellSize * 0.15,
          cellSize * 0.7, // Make food slightly smaller
          cellSize * 0.7,
        ),
        const Radius.circular(6), // Rounded food
      ),
      foodPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SnakePainter oldDelegate) =>
      snake != oldDelegate.snake ||
      food != oldDelegate.food ||
      colorScheme != oldDelegate.colorScheme;
}
