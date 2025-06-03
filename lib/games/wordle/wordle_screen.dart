import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:ngames/widgets/settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngames/games/wordle/wordle_stats_model.dart';
import 'package:ngames/services/high_score_service.dart'; // Import HighScoreService
import 'package:ngames/models/game_high_score_model.dart'; // Import GameHighScore model

// Enum to represent the status of each letter in a guess
enum LetterStatus { initial, notInWord, inWord, correctPosition }

class WordleScreen extends ConsumerStatefulWidget {
  // Changed to ConsumerStatefulWidget
  const WordleScreen({super.key});

  @override
  ConsumerState<WordleScreen> createState() => _WordleScreenState(); // Changed to ConsumerState
}

class _WordleScreenState extends ConsumerState<WordleScreen>
    with TickerProviderStateMixin {
  final int _wordLength = 5;
  final int _maxAttempts = 6;
  List<String> _wordList =
      []; // Initialize as empty, will be loaded from assets
  List<String> _defaultWordList = [
    'FLAME',
    'BRICK',
    'CRANE',
    'SLATE',
    'QUERY',
  ]; // Fallback

  late String _targetWord;
  List<List<Map<String, LetterStatus>>> _guesses = [];
  List<String> _currentGuess = [];
  int _currentAttempt = 0;
  bool _isGameOver = false;
  bool _isGameWon = false;
  Map<String, LetterStatus> _keyboardLetterStatus = {};

  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;
  late AnimationController
  _shakeController; // New controller for shake animation
  late Animation<double> _shakeAnimation;
  bool _isFlipping = false; // To prevent interaction during flip

  // Store the status of the currently revealing row separately for animation
  List<Map<String, LetterStatus>> _revealingGuessResult = [];

  WordleStats _stats = WordleStats(); // Add WordleStats state
  static const String _wordleStatsKey = 'wordle_stats';
  bool _isLoadingWords =
      true; // To show loading indicator while words are loaded

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
    _loadAssetsAndInitializeGame();
  }

  Future<void> _loadAssetsAndInitializeGame() async {
    await _loadWordListFromAssets();
    await _loadStats();
    _initializeGame();
    if (mounted) {
      setState(() {
        _isLoadingWords = false;
      });
    }
  }

  Future<void> _loadWordListFromAssets() async {
    try {
      final String wordsString = await rootBundle.loadString(
        'assets/wordle/words.txt',
      );
      final List<String> loadedWords =
          LineSplitter()
              .convert(wordsString)
              .map((word) => word.trim().toUpperCase())
              .where((word) => word.length == _wordLength && word.isNotEmpty)
              .toSet() // Use Set to remove duplicates, then toList
              .toList();
      if (loadedWords.isNotEmpty) {
        _wordList = loadedWords;
      } else {
        _wordList =
            _defaultWordList; // Fallback if file is empty or parsing fails
      }
    } catch (e) {
      // print('Error loading word list: $e');
      _wordList = _defaultWordList; // Fallback on error
    }
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_wordleStatsKey);
    if (statsJson != null) {
      try {
        setState(() {
          _stats = WordleStats.fromJson(
            jsonDecode(statsJson) as Map<String, dynamic>,
          );
        });
      } catch (e) {
        // Handle potential errors in decoding, or start with fresh stats
        setState(() {
          _stats = WordleStats();
        });
      }
    }
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wordleStatsKey, jsonEncode(_stats.toJson()));
  }

  void _initializeAnimationControllers() {
    _flipControllers = List.generate(
      _wordLength,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    _flipAnimations =
        _flipControllers
            .map(
              (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeInOut),
              ),
            )
            .toList();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn, // Or a custom shake curve
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    _shakeController.dispose(); // Dispose shake controller
    super.dispose();
  }

  void _initializeGame() {
    if (_wordList.isEmpty) {
      // This case should ideally not be reached if _loadWordListFromAssets has a fallback
      // Or, show an error/loading state until words are ready.
      // For now, if somehow empty, use the small default list to prevent crash.
      _wordList = _defaultWordList;
      if (_wordList.isEmpty) {
        // Absolute fallback
        _targetWord = "ERROR"; // Should not happen
        // Potentially disable game or show error message
        if (mounted)
          setState(() {
            _isGameOver = true;
          });
        return;
      }
    }
    final Random random = Random();
    _targetWord = _wordList[random.nextInt(_wordList.length)].toUpperCase();
    _shakeController.reset();
    _guesses = List.generate(
      _maxAttempts,
      (_) => List.generate(_wordLength, (_) => {'': LetterStatus.initial}),
    );
    _currentGuess = [];
    _currentAttempt = 0;
    _isGameOver = false;
    _isGameWon = false;
    _keyboardLetterStatus.clear();
    for (
      var charCode = 'A'.codeUnitAt(0);
      charCode <= 'Z'.codeUnitAt(0);
      charCode++
    ) {
      _keyboardLetterStatus[String.fromCharCode(charCode)] =
          LetterStatus.initial;
    }
    _isFlipping = false;
    for (var controller in _flipControllers) {
      controller.reset();
    }
    _revealingGuessResult = [];
    if (mounted) setState(() {}); // Ensure UI updates after initialization
  }

  void _handleKeyPress(String letter) {
    if (_isGameOver || _isFlipping) return; // Prevent input during flip

    setState(() {
      if (letter == 'ENTER') {
        if (_currentGuess.length == _wordLength) {
          _submitGuess();
        }
      } else if (letter == 'BACKSPACE') {
        if (_currentGuess.isNotEmpty) {
          _currentGuess.removeLast();
        }
      } else if (_currentGuess.length < _wordLength && letter.length == 1) {
        _currentGuess.add(letter.toUpperCase());
      }
    });
  }

  Future<void> _submitGuess() async {
    final String guessedWord = _currentGuess.join('');

    if (!_wordList.contains(guessedWord)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$guessedWord" is not a valid word.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      _shakeController.forward(from: 0.0);
      return;
    }
    setState(() {
      _isFlipping = true;
    });

    List<Map<String, LetterStatus>> guessResult = [];
    Map<String, int> targetWordLetterCounts = {};
    for (int i = 0; i < _targetWord.length; i++) {
      targetWordLetterCounts[_targetWord[i]] =
          (targetWordLetterCounts[_targetWord[i]] ?? 0) + 1;
    }
    for (int i = 0; i < _wordLength; i++) {
      final String char = guessedWord[i];
      LetterStatus status;
      if (char == _targetWord[i]) {
        status = LetterStatus.correctPosition;
        targetWordLetterCounts[char] = (targetWordLetterCounts[char] ?? 0) - 1;
      } else {
        status = LetterStatus.initial;
      }
      guessResult.add({char: status});
    }
    for (int i = 0; i < _wordLength; i++) {
      final String char = guessedWord[i];
      if (guessResult[i][char] == LetterStatus.correctPosition) {
        _updateKeyboardStatus(char, LetterStatus.correctPosition);
        continue;
      }
      if (_targetWord.contains(char) &&
          (targetWordLetterCounts[char] ?? 0) > 0) {
        guessResult[i] = {char: LetterStatus.inWord};
        targetWordLetterCounts[char] = (targetWordLetterCounts[char] ?? 0) - 1;
        _updateKeyboardStatus(char, LetterStatus.inWord);
      } else {
        guessResult[i] = {char: LetterStatus.notInWord};
        _updateKeyboardStatus(char, LetterStatus.notInWord);
      }
    }
    _revealingGuessResult = List.from(guessResult);
    _guesses[_currentAttempt] = List.from(guessResult);

    for (int i = 0; i < _wordLength; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) _flipControllers[i].forward(from: 0.0);
    }
    await Future.delayed(Duration(milliseconds: 400 + (200 * _wordLength)));
    if (!mounted) return;

    bool gameWonThisAttempt = guessedWord == _targetWord;
    // Local stats update
    if (gameWonThisAttempt || (_currentAttempt + 1 == _maxAttempts)) {
      _stats.recordGame(gameWonThisAttempt, _currentAttempt + 1);
      await _saveStats();
    }

    // Global High Score Submission for Wordle (if won)
    if (gameWonThisAttempt) {
      final highScoreService = ref.read(highScoreServiceProvider);
      final userId = highScoreService.getCurrentUserId();
      final userName = highScoreService.getCurrentUserName();
      if (userId != null && userName != null) {
        final wordleHighScore = GameHighScore(
          userId: userId,
          userName: userName,
          gameId: 'wordle',
          score: 0, // Not directly applicable, using attempts
          attempts: _currentAttempt + 1, // Number of attempts to win
          timestamp: DateTime.now(),
          scoreType: 'attempts', // Lower is better
        );
        await highScoreService.addHighScore(wordleHighScore);
      }
    }

    setState(() {
      _currentAttempt++;
      _currentGuess = [];
      _isFlipping = false;
      _revealingGuessResult = [];

      if (gameWonThisAttempt) {
        _isGameWon = true;
        _isGameOver = true;
      } else if (_currentAttempt == _maxAttempts) {
        _isGameOver = true;
        _isGameWon = false;
      }

      if (_isGameOver) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showWordleGameOverDialog();
        });
      }
    });
  }

  void _updateKeyboardStatus(String char, LetterStatus newStatus) {
    // Green is highest priority, then yellow, then grey
    final currentStatus = _keyboardLetterStatus[char];
    if (currentStatus == LetterStatus.correctPosition) return;
    if (newStatus == LetterStatus.correctPosition) {
      _keyboardLetterStatus[char] = newStatus;
    } else if (newStatus == LetterStatus.inWord &&
        currentStatus != LetterStatus.correctPosition) {
      _keyboardLetterStatus[char] = newStatus;
    } else if (newStatus == LetterStatus.notInWord &&
        currentStatus == LetterStatus.initial) {
      _keyboardLetterStatus[char] = newStatus;
    }
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
          backgroundColor: theme.colorScheme.surfaceVariant,
          title: Text(
            'How to Play Wordle',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Guess the hidden word in 6 tries.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'Each guess must be a valid 5-letter word.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'After each guess, the color of the tiles will change to show how close your guess was to the word.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildLetterTile(
                      'W',
                      LetterStatus.correctPosition,
                      false,
                      null,
                      LetterStatus.correctPosition,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Green: Letter is in the word and in the correct spot.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLetterTile(
                      'E',
                      LetterStatus.inWord,
                      false,
                      null,
                      LetterStatus.inWord,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Yellow: Letter is in the word but in the wrong spot.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLetterTile(
                      'A',
                      LetterStatus.notInWord,
                      false,
                      null,
                      LetterStatus.notInWord,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Grey: Letter is not in the word in any spot.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showWordleGameOverDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.colorScheme.surfaceVariant,
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
                _initializeGame();
              },
            ),
          ],
        );
      },
    );
  }

  void _showStatsDialog() {
    final theme = Theme.of(context);
    final winPercentage =
        _stats.gamesPlayed > 0
            ? ((_stats.gamesWon / _stats.gamesPlayed) * 100).toStringAsFixed(1)
            : "0";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: theme.colorScheme.surfaceVariant,
          title: Text(
            'Wordle Statistics',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildStatRow('Played', _stats.gamesPlayed.toString(), theme),
                _buildStatRow('Win %', winPercentage, theme),
                _buildStatRow(
                  'Current Streak',
                  _stats.currentStreak.toString(),
                  theme,
                ),
                _buildStatRow('Max Streak', _stats.maxStreak.toString(), theme),
                const SizedBox(height: 16),
                Text(
                  'GUESS DISTRIBUTION',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_stats.guessDistribution.values.every((v) => v == 0))
                  Text(
                    'No games played yet.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  )
                else
                  ..._stats.guessDistribution.entries.map((entry) {
                    final attempts = entry.key;
                    final count = entry.value;
                    final double barWidthFactor =
                        _stats.gamesPlayed > 0 && count > 0
                            ? (count /
                                _stats.guessDistribution.values
                                    .reduce(max)
                                    .toDouble()
                                    .clamp(1, double.infinity))
                            : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Text(
                            '$attempts: ',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 20,
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: barWidthFactor,
                                child: Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        count.toString(),
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoadingWords) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Wordle'),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordle'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: _showStatsDialog,
            tooltip: 'Statistics',
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeGame,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            // Added SingleChildScrollView to prevent bottom overflow
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.85, // Ensure Column has bounded height for Expanded
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildGuessGrid()),
                  _buildKeyboard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuessGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_maxAttempts, (attemptIndex) {
          Widget rowContent = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_wordLength, (letterIndex) {
              String char = '';
              LetterStatus status = LetterStatus.initial;
              bool isCurrentAttemptRow = attemptIndex == _currentAttempt;
              bool isPastAttempt = attemptIndex < _currentAttempt;

              if (isPastAttempt) {
                final MapEntry<String, LetterStatus> entry =
                    _guesses[attemptIndex][letterIndex].entries.first;
                char = entry.key;
                status =
                    entry.value; // This is the final status for past guesses
              } else if (isCurrentAttemptRow &&
                  letterIndex < _currentGuess.length) {
                char = _currentGuess[letterIndex];
                status =
                    LetterStatus.initial; // Current input, not yet evaluated
              } else if (isCurrentAttemptRow &&
                  _isFlipping &&
                  _revealingGuessResult.isNotEmpty &&
                  letterIndex < _revealingGuessResult.length) {
                final MapEntry<String, LetterStatus> entry =
                    _revealingGuessResult[letterIndex].entries.first;
                char = entry.key;
                // Status for flipping tiles is handled by revealedStatus in _buildLetterTile
              }

              return _buildLetterTile(
                char,
                status, // This is the key for past guesses
                isCurrentAttemptRow &&
                    letterIndex < _currentGuess.length &&
                    !_isFlipping,
                isCurrentAttemptRow && _isFlipping
                    ? _flipAnimations[letterIndex]
                    : null,
                // For past guesses (not flipping), revealedStatus should be the same as status.
                // For flipping row, it's from _revealingGuessResult.
                isCurrentAttemptRow && _isFlipping
                    ? (_revealingGuessResult.isNotEmpty &&
                            letterIndex < _revealingGuessResult.length
                        ? _revealingGuessResult[letterIndex].entries.first.value
                        : LetterStatus.initial)
                    : status,
              );
            }),
          );

          if (attemptIndex == _currentAttempt) {
            return AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                double offset = sin(_shakeAnimation.value * pi * 4) * 8;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: rowContent,
            );
          }
          return rowContent;
        }),
      ),
    );
  }

  Widget _buildLetterTile(
    String char,
    LetterStatus status,
    bool isCurrentInputTile,
    Animation<double>? flipAnimation,
    LetterStatus revealedStatus,
  ) {
    final theme = Theme.of(context);

    final LetterStatus displayStatus =
        (flipAnimation == null && !isCurrentInputTile && char.isNotEmpty)
            ? status
            : revealedStatus;

    Color tileColor;
    Color textColor;
    Border borderToShow = Border.all(
      color: theme.colorScheme.outline.withOpacity(0.5),
    ); // Default border

    // Determine colors and border based on the effective status to display
    switch (displayStatus) {
      case LetterStatus.notInWord:
        tileColor = theme.colorScheme.onSurface.withOpacity(0.4);
        textColor = theme.colorScheme.surface;
        break;
      case LetterStatus.inWord:
        tileColor = theme.colorScheme.tertiaryContainer;
        textColor = theme.colorScheme.onTertiaryContainer;
        break;
      case LetterStatus.correctPosition:
        tileColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case LetterStatus.initial:
        if (isCurrentInputTile && char.isNotEmpty) {
          tileColor = theme.colorScheme.surfaceContainerHighest;
          textColor = theme.colorScheme.onSurfaceVariant;
          borderToShow = Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          ); // Active input border
        } else {
          tileColor = theme.colorScheme.surfaceVariant.withOpacity(0.5);
          textColor = theme.colorScheme.onSurfaceVariant;
          // Keep default border for empty/initial non-active tiles
        }
        break;
    }

    // This is the face that will be shown if not animating, or the back face during animation
    Widget finalFace = Container(
      decoration: BoxDecoration(
        color: tileColor,
        border: borderToShow, // Apply the determined border
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          char.toUpperCase(),
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );

    // Front face for flipping animation (before reveal)
    Widget frontFace = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Text(
          // Show character on front if it's current input, otherwise it's blank before flip
          isCurrentInputTile ? char.toUpperCase() : '',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );

    if (flipAnimation == null) {
      // For static display (past guesses, help dialog examples, or current input not being flipped)
      return Container(
        margin: const EdgeInsets.all(3.0),
        width: 55.0,
        height: 55.0,
        // If it's a current input tile, show frontFace styling, otherwise show finalFace (colored tile)
        child: (isCurrentInputTile && char.isNotEmpty) ? frontFace : finalFace,
      );
    }

    // If animating
    return AnimatedBuilder(
      animation: flipAnimation,
      builder: (context, child) {
        final isFlipped = flipAnimation.value >= 0.5;
        final transformAngle = flipAnimation.value * pi;
        return Container(
          margin: const EdgeInsets.all(3.0),
          width: 55.0,
          height: 55.0,
          child: Transform(
            transform: Matrix4.rotationY(transformAngle)..setEntry(3, 2, 0.001),
            alignment: Alignment.center,
            child:
                isFlipped
                    ? Transform(
                      transform: Matrix4.rotationY(pi),
                      alignment: Alignment.center,
                      child: finalFace,
                    ) // Show finalFace as the back
                    : frontFace,
          ),
        );
      },
    );
  }

  Widget _buildKeyboard() {
    final List<String> row1 = [
      'Q',
      'W',
      'E',
      'R',
      'T',
      'Y',
      'U',
      'I',
      'O',
      'P',
    ];
    final List<String> row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
    final List<String> row3 = [
      'ENTER',
      'Z',
      'X',
      'C',
      'V',
      'B',
      'N',
      'M',
      'BACKSPACE',
    ];

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          _buildKeyboardRow(row1),
          _buildKeyboardRow(row2),
          _buildKeyboardRow(row3),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> letters) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          letters.map((letter) {
            bool isSpecialKey = letter == 'ENTER' || letter == 'BACKSPACE';
            LetterStatus status =
                _keyboardLetterStatus[letter] ?? LetterStatus.initial;
            Color keyColor;
            Color keyTextColor = theme.colorScheme.onSurface;

            if (isSpecialKey) {
              keyColor = theme.colorScheme.surfaceVariant.withOpacity(0.7);
            } else {
              switch (status) {
                case LetterStatus.notInWord:
                  keyColor = theme.colorScheme.onSurface.withOpacity(0.3);
                  keyTextColor = theme.colorScheme.surface;
                  break;
                case LetterStatus.inWord:
                  keyColor = theme.colorScheme.tertiaryContainer;
                  keyTextColor = theme.colorScheme.onTertiaryContainer;
                  break;
                case LetterStatus.correctPosition:
                  keyColor = theme.colorScheme.primaryContainer;
                  keyTextColor = theme.colorScheme.onPrimaryContainer;
                  break;
                default: // Initial
                  keyColor = theme.colorScheme.surfaceVariant;
              }
            }

            return Expanded(
              flex: isSpecialKey ? 3 : 2, // Give more space to special keys
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: keyColor,
                    foregroundColor: keyTextColor,
                    padding: EdgeInsets.symmetric(
                      vertical: isSpecialKey ? 14 : 16,
                    ),
                    textStyle: TextStyle(
                      fontSize: isSpecialKey ? 12 : 15,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed:
                      _isGameOver && !isSpecialKey
                          ? null
                          : () => _handleKeyPress(letter),
                  child:
                      isSpecialKey && letter == 'BACKSPACE'
                          ? const Icon(Icons.backspace_outlined, size: 18)
                          : Text(letter),
                ),
              ),
            );
          }).toList(),
    );
  }
}
