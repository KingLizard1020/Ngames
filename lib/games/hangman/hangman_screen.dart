import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:go_router/go_router.dart';
import 'package:ngames/widgets/settings_dialog.dart';
import 'package:ngames/services/high_score_service.dart'; // Import HighScoreService
import 'package:ngames/models/game_high_score_model.dart'; // Import GameHighScore model

class HangmanScreen extends ConsumerStatefulWidget {
  // Changed to ConsumerStatefulWidget
  final String? selectedCategory;

  const HangmanScreen({super.key, this.selectedCategory});

  @override
  ConsumerState<HangmanScreen> createState() => _HangmanScreenState(); // Changed to ConsumerState
}

class _HangmanScreenState extends ConsumerState<HangmanScreen> {
  // Change to ConsumerState
  final Map<String, List<String>> _wordCategories = {
    'Animals': ['TIGER', 'LION', 'BEAR', 'ZEBRA', 'MONKEY', 'ELEPHANT'],
    'Fruits': ['APPLE', 'BANANA', 'ORANGE', 'GRAPE', 'MANGO', 'PEACH'],
    'Programming': [
      'FLUTTER',
      'DART',
      'WIDGET',
      'MOBILE',
      'NGAMES',
      'PYTHON',
      'JAVA',
    ],
    'Countries': [
      'INDIA',
      'NEPAL',
      'CHINA',
      'JAPAN',
      'BRAZIL',
      'CANADA',
      'FRANCE',
    ],
    'General': ['HOUSE', 'WATER', 'LIGHT', 'MUSIC', 'DREAM', 'WORLD'],
  };
  late String _targetWord;
  late String _currentCategory;
  Set<String> _guessedLetters = {};
  int _incorrectGuesses = 0;
  final int _maxIncorrectGuesses = 6;
  bool _isGameOver = false;
  bool _isGameWon = false;
  int _hintsRemaining = 2;
  final int _initialHints = 2;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final Random random = Random();
    List<String> wordsInChosenCategory;

    if (widget.selectedCategory != null &&
        _wordCategories.containsKey(widget.selectedCategory)) {
      _currentCategory = widget.selectedCategory!;
      wordsInChosenCategory = _wordCategories[_currentCategory]!;
    } else {
      List<String> categories = _wordCategories.keys.toList();
      _currentCategory = categories[random.nextInt(categories.length)];
      wordsInChosenCategory = _wordCategories[_currentCategory]!;
    }

    _targetWord =
        wordsInChosenCategory[random.nextInt(wordsInChosenCategory.length)]
            .toUpperCase();

    _guessedLetters = {};
    _incorrectGuesses = 0;
    _isGameOver = false;
    _isGameWon = false;
    _hintsRemaining = _initialHints;
    setState(() {});
  }

  String _getDisplayedWord() {
    String displayed = '';
    for (String letter in _targetWord.split('')) {
      if (_guessedLetters.contains(letter)) {
        displayed += '$letter ';
      } else {
        displayed += '_ ';
      }
    }
    return displayed.trim();
  }

  void _guessLetter(String letter) async {
    // Make async for high score submission
    if (_isGameOver || _guessedLetters.contains(letter)) return;

    bool gameJustEnded = false;
    bool wonThisTurn = false;

    setState(() {
      _guessedLetters.add(letter);
      if (_targetWord.contains(letter)) {
        bool won = true;
        for (String char in _targetWord.split('')) {
          if (!_guessedLetters.contains(char)) {
            won = false;
            break;
          }
        }
        if (won) {
          _isGameWon = true;
          _isGameOver = true;
          gameJustEnded = true;
          wonThisTurn = true;
        }
      } else {
        _incorrectGuesses++;
        if (_incorrectGuesses >= _maxIncorrectGuesses) {
          _isGameOver = true;
          _isGameWon = false;
          gameJustEnded = true;
        }
      }
    });

    if (gameJustEnded && _isGameWon) {
      final highScoreService = ref.read(highScoreServiceProvider);
      final userId = highScoreService.getCurrentUserId();
      final userName = highScoreService.getCurrentUserName();

      if (userId != null && userName != null) {
        final hangmanHighScore = GameHighScore(
          userId: userId,
          userName: userName,
          gameId: 'hangman',
          score: _maxIncorrectGuesses - _incorrectGuesses,
          attempts: _incorrectGuesses,
          timestamp: DateTime.now(),
          scoreType: 'attempts_inverse',
        );
        await highScoreService.addHighScore(hangmanHighScore);
      }
    }

    if (gameJustEnded) {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
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
            _isGameWon ? 'Congratulations!' : 'Game Over',
            style: TextStyle(
              color:
                  _isGameWon
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              _isGameWon
                  ? 'You guessed the word: $_targetWord'
                  : 'The word was: $_targetWord',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
              ),
              child: const Text('Main Menu'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close this dialog
                GoRouter.of(
                  context,
                ).go('/'); // Use screen's context to navigate
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _initializeGame();
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
            'How to Play Hangman',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Guess the hidden word one letter at a time.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'You have $_maxIncorrectGuesses incorrect guesses before the hangman is complete.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use the alphabet keyboard to pick letters.',
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

  void _useHint() {
    if (_hintsRemaining > 0 && !_isGameOver) {
      final Random random = Random();
      List<String> unguessedTargetLetters =
          _targetWord
              .split('')
              .where((letter) => !_guessedLetters.contains(letter))
              .toList();

      if (unguessedTargetLetters.isNotEmpty) {
        String hintLetter =
            unguessedTargetLetters[random.nextInt(
              unguessedTargetLetters.length,
            )];
        setState(() {
          _hintsRemaining--;
        });
        _guessLetter(hintLetter); // This will call setState internally
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hangman - $_currentCategory'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded),
            onPressed: (_hintsRemaining > 0 && !_isGameOver) ? _useHint : null,
            tooltip: 'Use Hint ($_hintsRemaining left)',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeGame,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex:
                  3, // Adjusted flex for better visual balance with CustomPaint
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height:
                        180, // Provide a fixed height for the CustomPaint area
                    width: 150, // Provide a fixed width
                    child: CustomPaint(
                      painter: HangmanPainter(
                        incorrectGuesses: _incorrectGuesses,
                        color:
                            theme
                                .colorScheme
                                .error, // Use theme error color for hangman
                        strokeWidth: 4.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced space a bit
                  Text(
                    'Category: $_currentCategory', // Display category below hangman
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getDisplayedWord(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      letterSpacing: 3,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hints Remaining: $_hintsRemaining',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Incorrect Guesses: $_incorrectGuesses/$_maxIncorrectGuesses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          _incorrectGuesses > _maxIncorrectGuesses / 2
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2, // Adjusted flex
              child: _buildAlphabetKeyboard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlphabetKeyboard() {
    final theme = Theme.of(context);
    List<String> alphabet = List.generate(
      26,
      (index) => String.fromCharCode('A'.codeUnitAt(0) + index),
    );
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, // Adjust for better layout
        childAspectRatio: 1.2,
        crossAxisSpacing: 6.0,
        mainAxisSpacing: 6.0,
      ),
      itemCount: alphabet.length,
      itemBuilder: (context, index) {
        final letter = alphabet[index];
        final bool alreadyGuessed = _guessedLetters.contains(letter);
        bool isCorrectGuess = alreadyGuessed && _targetWord.contains(letter);
        bool isIncorrectGuess = alreadyGuessed && !_targetWord.contains(letter);

        Color keyColor;
        Color keyTextColor = theme.colorScheme.onPrimaryContainer; // Default

        if (isCorrectGuess) {
          keyColor = theme.colorScheme.primaryContainer;
        } else if (isIncorrectGuess) {
          keyColor = theme.colorScheme.errorContainer.withOpacity(0.7);
          keyTextColor = theme.colorScheme.onErrorContainer;
        } else {
          keyColor = theme.colorScheme.secondaryContainer;
          keyTextColor = theme.colorScheme.onSecondaryContainer;
        }

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: keyColor,
            foregroundColor: keyTextColor,
            padding: const EdgeInsets.all(0), // Adjust padding as needed
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2.0,
          ),
          onPressed:
              alreadyGuessed || _isGameOver ? null : () => _guessLetter(letter),
          child: Text(letter),
        );
      },
    );
  }
}

class HangmanPainter extends CustomPainter {
  final int incorrectGuesses;
  final Color color;
  final double strokeWidth;

  HangmanPainter({
    required this.incorrectGuesses,
    this.color = Colors.black,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Gallow base
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.9),
      Offset(size.width * 0.9, size.height * 0.9),
      paint,
    );

    // Gallow upright post
    if (incorrectGuesses > 0) {
      canvas.drawLine(
        Offset(size.width * 0.3, size.height * 0.9),
        Offset(size.width * 0.3, size.height * 0.1),
        paint,
      );
    }
    // Gallow top beam
    if (incorrectGuesses > 0) {
      // Also draw with the post
      canvas.drawLine(
        Offset(size.width * 0.3, size.height * 0.1),
        Offset(size.width * 0.7, size.height * 0.1),
        paint,
      );
    }
    // Rope
    if (incorrectGuesses > 0) {
      // Also draw with the post/beam
      canvas.drawLine(
        Offset(size.width * 0.7, size.height * 0.1),
        Offset(size.width * 0.7, size.height * 0.25),
        paint,
      );
    }

    // Head
    if (incorrectGuesses > 1) {
      canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.25 + size.height * 0.08),
        size.height * 0.08,
        paint,
      );
    }
    // Body
    if (incorrectGuesses > 2) {
      canvas.drawLine(
        Offset(size.width * 0.7, size.height * 0.33 + size.height * 0.08),
        Offset(size.width * 0.7, size.height * 0.6),
        paint,
      );
    }
    // Left Arm
    if (incorrectGuesses > 3) {
      canvas.drawLine(
        Offset(size.width * 0.7, size.height * 0.4),
        Offset(size.width * 0.55, size.height * 0.5),
        paint,
      );
    }
    // Right Arm
    if (incorrectGuesses > 4) {
      canvas.drawLine(
        Offset(size.width * 0.7, size.height * 0.4),
        Offset(size.width * 0.85, size.height * 0.5),
        paint,
      );
    }
    // Left Leg
    if (incorrectGuesses > 5) {
      canvas.drawLine(
        Offset(size.width * 0.7, size.height * 0.6),
        Offset(size.width * 0.55, size.height * 0.75),
        paint,
      );
    }
    // Right Leg (final stage, game over)
    if (incorrectGuesses > 6) {
      // Or typically >= _maxIncorrectGuesses which is 6
      canvas.drawLine(
        Offset(size.width * 0.7, size.height * 0.6),
        Offset(size.width * 0.85, size.height * 0.75),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HangmanPainter oldDelegate) {
    return oldDelegate.incorrectGuesses != incorrectGuesses ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
