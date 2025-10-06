import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngames/services/theme_service.dart';
import 'package:ngames/services/game_settings_service.dart'; // Import game settings service

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentAppThemeMode = ref.watch(
      themeModeNotifierProvider.select(
        (tm) =>
            ref.read(themeModeNotifierProvider.notifier).currentAppThemeMode,
      ),
    );
    final currentSnakeDifficulty = ref.watch(snakeDifficultyNotifierProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      title: Text(
        'Settings',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        // Make content scrollable for more settings
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Mode',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            ...AppThemeMode.values.map((mode) {
              return RadioListTile<AppThemeMode>(
                title: Text(
                  mode.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                value: mode,
                groupValue: currentAppThemeMode,
                onChanged: (AppThemeMode? value) {
                  if (value != null) {
                    ref
                        .read(themeModeNotifierProvider.notifier)
                        .setThemeMode(value);
                  }
                },
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 20),
            Text(
              'Snake Game Difficulty',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            ...SnakeDifficulty.values.map((difficulty) {
              return RadioListTile<SnakeDifficulty>(
                title: Text(
                  difficulty.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                value: difficulty,
                groupValue: currentSnakeDifficulty,
                onChanged: (SnakeDifficulty? value) {
                  if (value != null) {
                    ref
                        .read(snakeDifficultyNotifierProvider.notifier)
                        .setDifficulty(value);
                  }
                },
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
