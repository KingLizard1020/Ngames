import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ngames/widgets/confetti_overlay.dart';

/// Reusable game over dialog widget.
///
/// Displays a consistent game over UI across all games with optional confetti.
class GameOverDialog extends StatelessWidget {
  /// Whether the game was won
  final bool isWon;

  /// Dialog title (e.g., "Congratulations!" or "Game Over")
  final String? title;

  /// Main message to display
  final String message;

  /// Additional subtitle or details
  final String? subtitle;

  /// Callback when "Play Again" is pressed
  final VoidCallback onPlayAgain;

  /// Callback when "Main Menu" is pressed (defaults to navigating to '/')
  final VoidCallback? onMainMenu;

  /// Whether to show confetti animation
  final bool showConfetti;

  /// Optional custom widget to display (e.g., stats, score)
  final Widget? customContent;

  const GameOverDialog({
    super.key,
    required this.isWon,
    required this.message,
    required this.onPlayAgain,
    this.title,
    this.subtitle,
    this.onMainMenu,
    this.showConfetti = false,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTitle = isWon ? 'Congratulations!' : 'Game Over';

    return ConfettiOverlay(
      showConfetti: showConfetti,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        title: Text(
          title ?? defaultTitle,
          style: TextStyle(
            color: isWon ? theme.colorScheme.primary : theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
              if (customContent != null) ...[
                const SizedBox(height: 16),
                customContent!,
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (onMainMenu != null) {
                onMainMenu!();
              } else {
                context.go('/');
              }
            },
            child: const Text('Main Menu'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onPlayAgain();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  /// Shows the game over dialog.
  ///
  /// Helper method to display the dialog with proper configuration.
  static Future<void> show(
    BuildContext context, {
    required bool isWon,
    required String message,
    required VoidCallback onPlayAgain,
    String? title,
    String? subtitle,
    VoidCallback? onMainMenu,
    bool showConfetti = false,
    Widget? customContent,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => GameOverDialog(
            isWon: isWon,
            message: message,
            onPlayAgain: onPlayAgain,
            title: title,
            subtitle: subtitle,
            onMainMenu: onMainMenu,
            showConfetti: showConfetti,
            customContent: customContent,
          ),
    );
  }
}
