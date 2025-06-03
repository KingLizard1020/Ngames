import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SelectGameForHighScoreScreen extends StatelessWidget {
  const SelectGameForHighScoreScreen({super.key});

  final List<Map<String, String>> games = const [
    {
      'id': 'wordle',
      'name': 'Wordle',
      'icon': '📝',
    }, // Using emojis as simple icons
    {'id': 'snake', 'name': 'Snake', 'icon': '🐍'},
    {'id': 'hangman', 'name': 'Hangman', 'icon': '🤔'},
    // Add other games here if they have high scores
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Game for High Scores'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              leading: Text(
                game['icon']!,
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(
                game['name']!,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Icon(
                Icons.leaderboard_rounded,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              onTap: () {
                context.go('/high-scores/${game['id']}');
              },
            ),
          );
        },
      ),
    );
  }
}
