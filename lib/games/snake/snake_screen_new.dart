import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ngames/core/game/base_game_state.dart';
import 'package:ngames/core/constants/game_constants.dart';
import 'package:ngames/core/utils/logger.dart';
import 'package:ngames/shared/widgets/game_over_dialog.dart';
import 'package:ngames/services/high_score_service.dart';
import 'package:ngames/services/game_settings_service.dart';
import 'package:ngames/widgets/settings_dialog.dart';

enum Direction { up, down, left, right }

class SnakeScreen extends ConsumerStatefulWidget {
  const SnakeScreen({super.key});

  @override
  ConsumerState<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends BaseHighScoreGameState<SnakeScreen> {
  // Game state
  List<Offset> _snake = [];
  Offset _food = const Offset(0, 0);
  Direction _direction = Direction.right;
  Direction? _nextDirection; // Buffered direction to prevent quick turns
  Timer? _gameTimer;
  int _score = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  int _countdown = 0;
  bool _hasShownGameOver = false; // Prevent multiple game over dialogs

  // Audio
  final AudioPlayer _crunchPlayer = AudioPlayer();
  final AudioPlayer _deathPlayer = AudioPlayer();

  // BaseGame implementation
  @override
  String get gameId => 'snake';

  @override
  String get gameName => 'Snake';

  @override
  bool get isGameOver => !_isPlaying && _snake.isNotEmpty;

  @override
  bool get isGameWon => false; // Snake doesn't have a "win" condition

  @override
  int get currentScore => _score;

  @override
  void initState() {
    super.initState();
    highScoreService = ref.read(highScoreServiceProvider);
    initializeGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _crunchPlayer.dispose();
    _deathPlayer.dispose();
    super.dispose();
  }

  @override
  Future<void> initializeGame() async {
    AppLogger.debug('Initializing Snake game', 'SNAKE');
    setState(() {
      _hasShownGameOver = false;
    });
    _startCountdown();
  }

  @override
  void resetGame() {
    AppLogger.debug('Resetting Snake game', 'SNAKE');
    _gameTimer?.cancel();
    setState(() {
      _snake.clear();
      _score = 0;
      _isPlaying = false;
      _isPaused = false;
      _direction = Direction.right;
      _nextDirection = null;
      _hasShownGameOver = false;
    });
    clearGameState();
    _startCountdown();
  }

  @override
  Map<String, dynamic> getGameStateData() {
    return {
      'snake': _snake.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'food': {'x': _food.dx, 'y': _food.dy},
      'direction': _direction.index,
      'score': _score,
    };
  }

  @override
  void restoreGameStateData(Map<String, dynamic> state) {
    setState(() {
      _snake =
          (state['snake'] as List)
              .map((p) => Offset(p['x'] as double, p['y'] as double))
              .toList();
      _food = Offset(
        state['food']['x'] as double,
        state['food']['y'] as double,
      );
      _direction = Direction.values[state['direction'] as int];
      _score = state['score'] as int;
    });
  }

  void _startCountdown() {
    setState(() {
      _countdown = 3;
      _isPlaying = false;
      _isPaused = false;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

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
    if (!mounted) return;

    final snakeDifficulty = ref.read(snakeDifficultyNotifierProvider.notifier);
    final gameSpeed = snakeDifficulty.currentSpeed;

    AppLogger.info(
      'Starting Snake game with speed: ${gameSpeed.inMilliseconds}ms',
      'SNAKE',
    );

    setState(() {
      // Initialize snake in center
      final center = SnakeConstants.gridSize / 2;
      _snake = [
        Offset(center, center),
        Offset(center - 1, center),
        Offset(center - 2, center),
      ];
      _direction = Direction.right;
      _nextDirection = null;
      _score = 0;
      _isPlaying = true;
      _isPaused = false;
      _hasShownGameOver = false;
      _generateFood();
    });

    // Start game loop
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(gameSpeed, (_) {
      if (_isPlaying && !_isPaused && mounted) {
        _moveSnake();
      }
    });
  }

  void _generateFood() {
    final random = Random();
    Offset newFood;

    // Keep generating until we find a spot not occupied by snake
    int attempts = 0;
    do {
      newFood = Offset(
        random.nextInt(SnakeConstants.gridSize).toDouble(),
        random.nextInt(SnakeConstants.gridSize).toDouble(),
      );
      attempts++;

      // Failsafe: if we can't find a spot in 100 attempts, game is probably won
      if (attempts > 100) {
        AppLogger.warning(
          'Could not find spot for food after 100 attempts',
          'SNAKE',
        );
        return;
      }
    } while (_snake.contains(newFood));

    setState(() {
      _food = newFood;
    });
  }

  void _moveSnake() {
    if (!_isPlaying || _isPaused || !mounted) return;

    // Use buffered direction if available
    if (_nextDirection != null) {
      _direction = _nextDirection!;
      _nextDirection = null;
    }

    final head = _snake.first;
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

    // Check wall collision
    if (newHead.dx < 0 ||
        newHead.dx >= SnakeConstants.gridSize ||
        newHead.dy < 0 ||
        newHead.dy >= SnakeConstants.gridSize) {
      _handleGameOver();
      return;
    }

    // Check self-collision (don't check the tail since it will move)
    for (int i = 0; i < _snake.length - 1; i++) {
      if (_snake[i] == newHead) {
        _handleGameOver();
        return;
      }
    }

    setState(() {
      _snake.insert(0, newHead);

      // Check if food eaten
      if (newHead == _food) {
        _score++;
        _generateFood();
        _crunchPlayer.play(AssetSource('audio/crunch.mp3'));

        // Save state after eating food
        saveGameState();
      } else {
        // Remove tail if no food eaten
        _snake.removeLast();
      }
    });
  }

  void _handleGameOver() {
    if (_hasShownGameOver || !mounted) return;

    _hasShownGameOver = true;
    _gameTimer?.cancel();

    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });

    _deathPlayer.play(AssetSource('audio/death.mp3'));

    // Call base class game over handler
    onGameLost();

    // Show game over dialog after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      _showGameOverDialog();
    });
  }

  void _showGameOverDialog() {
    if (!mounted) return;

    final gameOverDialog = GameOverDialog(
      isWon: false,
      message: 'Score: $_score',
      subtitle: 'Try to beat your high score!',
      showConfetti: false,
      onPlayAgain: () {
        Navigator.of(context).pop();
        resetGame();
      },
      onMainMenu: () {
        Navigator.of(context).pop();
        context.go('/');
      },
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => gameOverDialog,
    );
  }

  void _changeDirection(Direction newDirection) {
    // Prevent reversing into itself
    if (_isPlaying && !_isPaused) {
      if ((newDirection == Direction.up && _direction != Direction.down) ||
          (newDirection == Direction.down && _direction != Direction.up) ||
          (newDirection == Direction.left && _direction != Direction.right) ||
          (newDirection == Direction.right && _direction != Direction.left)) {
        // Buffer the direction change to prevent multiple changes in one tick
        _nextDirection = newDirection;
      }
    }
  }

  void _togglePause() {
    if (!_isPlaying) return;

    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _showPauseDialog();
    }
  }

  void _showPauseDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Game Paused'),
            content: const Text('What would you like to do?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                child: const Text('Main Menu'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isPaused = false;
                  });
                },
                child: const Text('Resume'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snakeDifficulty = ref.watch(snakeDifficultyNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(gameName),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        actions: [
          if (_isPlaying)
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: _togglePause,
              tooltip: _isPaused ? 'Resume' : 'Pause',
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final shouldRestart = await showDialog<bool>(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
              if (shouldRestart == true && mounted) {
                resetGame();
              }
            },
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _changeDirection(Direction.up);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _changeDirection(Direction.down);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _changeDirection(Direction.left);
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _changeDirection(Direction.right);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            // Score and info bar
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Score', style: theme.textTheme.labelSmall),
                      Text(
                        '$_score',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Difficulty', style: theme.textTheme.labelSmall),
                      Text(
                        snakeDifficulty.toString().split('.').last,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Game board
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child:
                        _countdown > 0
                            ? _buildCountdown(theme)
                            : _buildGameGrid(theme),
                  ),
                ),
              ),
            ),

            // Control buttons
            if (_isPlaying && !_isPaused)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Up button
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        Icons.arrow_drop_up,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () => _changeDirection(Direction.up),
                    ),
                    // Left, Down, Right buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 48,
                          icon: Icon(
                            Icons.arrow_left,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => _changeDirection(Direction.left),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 48,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => _changeDirection(Direction.down),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 48,
                          icon: Icon(
                            Icons.arrow_right,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => _changeDirection(Direction.right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown(ThemeData theme) {
    return Center(
      child: Text(
        _countdown.toString(),
        style: theme.textTheme.displayLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 120,
        ),
      ),
    );
  }

  Widget _buildGameGrid(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth / SnakeConstants.gridSize;

        return Stack(
          children: [
            // Snake
            ..._snake.map((segment) {
              final isHead = segment == _snake.first;
              return Positioned(
                left: segment.dx * cellSize,
                top: segment.dy * cellSize,
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color:
                        isHead
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      isHead ? cellSize / 4 : 2,
                    ),
                  ),
                  child:
                      isHead
                          ? Center(
                            child: Icon(
                              Icons.circle,
                              size: cellSize / 3,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                          : null,
                ),
              );
            }),

            // Food
            Positioned(
              left: _food.dx * cellSize,
              top: _food.dy * cellSize,
              child: Container(
                width: cellSize,
                height: cellSize,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.apple,
                    size: cellSize * 0.7,
                    color: theme.colorScheme.onError,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
