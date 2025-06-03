import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngames/models/game_high_score_model.dart';
import 'package:ngames/services/high_score_service.dart';

// Provider for fetching high scores for a specific game
final gameHighScoresProvider = StreamProvider.family<
  List<GameHighScore>,
  String
>((ref, gameId) {
  final highScoreService = ref.watch(highScoreServiceProvider);
  // Determine if lower score is better based on gameId (e.g., Wordle attempts)
  bool lowerIsBetter =
      gameId ==
      'wordle'; // Add other games if they also have lower-is-better scores
  return highScoreService.getHighScores(
    gameId,
    limit: 10,
    lowerIsBetter: lowerIsBetter,
  );
});

class HighScoreScreen extends ConsumerWidget {
  final String gameId;
  final String gameName;

  const HighScoreScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final highScoresAsyncValue = ref.watch(gameHighScoresProvider(gameId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$gameName - High Scores'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: highScoresAsyncValue.when(
        data: (scores) {
          if (scores.isEmpty) {
            return const Center(
              child: Text('No high scores yet for this game!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final scoreEntry = scores[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 8.0,
                ),
                color: theme.colorScheme.surfaceVariant,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    scoreEntry.userName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Score: ${scoreEntry.score}${scoreEntry.attempts != null && gameId == 'wordle' ? ' attempts' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.8,
                      ),
                    ),
                  ),
                  trailing: Text(
                    '${scoreEntry.timestamp.day}/${scoreEntry.timestamp.month}/${scoreEntry.timestamp.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) => Center(child: Text('Error loading scores: $err')),
      ),
    );
  }
}
