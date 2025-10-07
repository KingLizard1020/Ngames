import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ngames/services/auth_service.dart';

enum _HomeMenuAction { logout, backToLogin }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final theme = Theme.of(context);
    final authState = ref.watch(authStateChangesProvider);

    if (authState.isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (authState.hasError) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'An error occurred: \\n${authState.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(authStateChangesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.sentiment_very_satisfied_outlined),
          tooltip: 'For Neely',
          onPressed: () {
            context.go('/easter-egg');
          },
        ),
        title: const Text('NGames Home'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => context.go('/high-scores'),
            tooltip: 'View High Scores',
          ),
          PopupMenuButton<_HomeMenuAction>(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: "Account Options",
            onSelected: (_HomeMenuAction action) async {
              try {
                switch (action) {
                  case _HomeMenuAction.logout:
                    await authService.signOut();
                    break;
                  case _HomeMenuAction.backToLogin:
                    context.go('/auth');
                    break;
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: \\n${e.toString()}')),
                );
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<_HomeMenuAction>>[
                  const PopupMenuItem<_HomeMenuAction>(
                    value: _HomeMenuAction.logout,
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                    ),
                  ),
                  const PopupMenuItem<_HomeMenuAction>(
                    value: _HomeMenuAction.backToLogin,
                    child: ListTile(
                      leading: Icon(Icons.login),
                      title: Text('Back to Login'),
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome to NGames!',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: <Widget>[
                _buildGameTile(
                  context: context,
                  title: 'Wordle',
                  subtitle: 'Guess the hidden word.',
                  icon: Icons.text_fields_rounded,
                  routeName: '/game/wordle',
                  tileColor: Colors.green.shade100.withOpacity(0.5),
                  iconColor: Colors.green.shade700,
                ),
                _buildGameTile(
                  context: context,
                  title: 'Snake',
                  subtitle: 'Classic snake game.',
                  icon: Icons.turn_right_rounded,
                  routeName: '/game/snake',
                  tileColor: Colors.teal.shade100.withOpacity(0.5),
                  iconColor: Colors.teal.shade700,
                ),
                _buildGameTile(
                  context: context,
                  title: 'Hangman',
                  subtitle: 'Guess the word before it\'s too late.',
                  icon: Icons.person_search_rounded,
                  routeName: '/game/hangman/select',
                  tileColor: Colors.orange.shade100.withOpacity(0.5),
                  iconColor: Colors.orange.shade700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String routeName,
    required Color tileColor,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: tileColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.go(routeName);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_outline_rounded,
                color: iconColor.withOpacity(0.7),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
