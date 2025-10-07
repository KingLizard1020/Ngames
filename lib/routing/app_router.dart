import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'package:ngames/screens/auth/auth_screen.dart';
import 'package:ngames/screens/home/home_screen.dart';
import 'package:ngames/screens/easter_egg_screen.dart';
import 'package:ngames/screens/high_scores/high_score_screen.dart';
import 'package:ngames/screens/high_scores/select_game_for_high_score_screen.dart';
import 'package:ngames/screens/messaging/contacts_screen.dart';
import 'package:ngames/screens/messaging/chat_screen.dart';

// Games
import 'package:ngames/games/example_game/example_game_screen.dart';
import 'package:ngames/games/wordle/wordle_screen.dart';
import 'package:ngames/games/snake/snake_screen.dart';
import 'package:ngames/games/hangman/hangman_screen.dart';
import 'package:ngames/games/hangman/hangman_category_selection_screen.dart';

// Services
import 'package:ngames/services/auth_service.dart';

// Utils
import 'package:ngames/core/utils/logger.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateChanges = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/auth',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        pageBuilder:
            (context, state) => const MaterialPage(child: HomeScreen()),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder:
            (context, state) => const MaterialPage(child: AuthScreen()),
      ),
      GoRoute(
        path: '/easter-egg',
        pageBuilder:
            (context, state) => const MaterialPage(child: EasterEggScreen()),
      ),
      GoRoute(
        path: '/high-scores',
        pageBuilder:
            (context, state) =>
                const MaterialPage(child: SelectGameForHighScoreScreen()),
      ),
      GoRoute(
        path: '/high-scores/:gameId',
        pageBuilder: (context, state) {
          final gameId = state.pathParameters['gameId']!;
          String gameName = gameId
              .replaceAll('-', ' ')
              .splitMapJoin(
                ' ',
                onMatch: (m) => ' ',
                onNonMatch: (n) => '${n[0].toUpperCase()}${n.substring(1)}',
              );
          if (gameId == 'wordle') gameName = 'Wordle';
          if (gameId == 'snake') gameName = 'Snake';
          if (gameId == 'hangman') gameName = 'Hangman';
          return MaterialPage(
            child: HighScoreScreen(gameId: gameId, gameName: gameName),
          );
        },
      ),
      GoRoute(
        path: '/contacts',
        pageBuilder:
            (context, state) => const MaterialPage(child: ContactsScreen()),
      ),
      GoRoute(
        path: '/chat/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final receiverName = state.extra as String? ?? 'Chat';
          return MaterialPage(
            child: ChatScreen(receiverId: userId, receiverName: receiverName),
          );
        },
      ),
      GoRoute(
        path: '/game/example',
        pageBuilder:
            (context, state) => const MaterialPage(child: ExampleGameScreen()),
      ),
      GoRoute(
        path: '/game/wordle',
        pageBuilder:
            (context, state) => const MaterialPage(child: WordleScreen()),
      ),
      GoRoute(
        path: '/game/snake',
        pageBuilder:
            (context, state) => const MaterialPage(child: SnakeScreen()),
      ),
      GoRoute(
        path: '/game/hangman/select',
        pageBuilder:
            (context, state) =>
                const MaterialPage(child: HangmanCategorySelectionScreen()),
      ),
      GoRoute(
        path: '/game/hangman',
        pageBuilder: (context, state) {
          final category = state.extra as String?;
          return MaterialPage(child: HangmanScreen(selectedCategory: category));
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      // Handle loading state - allow navigation to proceed while auth loads
      if (authStateChanges.isLoading) {
        AppLogger.info(
          'Auth state loading, allowing navigation to ${state.matchedLocation}',
          'ROUTER',
        );
        return null;
      }

      final loggedIn = authStateChanges.asData?.value != null;
      final onAuthScreen = state.matchedLocation == '/auth';

      AppLogger.debug(
        'Redirect check: loggedIn=$loggedIn, onAuthScreen=$onAuthScreen, location=${state.matchedLocation}',
        'ROUTER',
      );

      if (!loggedIn && !onAuthScreen) {
        return '/auth';
      }
      if (loggedIn && onAuthScreen) {
        return '/';
      }
      return null;
    },
    refreshListenable: GoRouterRefreshStream(
      authStateChanges.asData?.value != null
          ? Stream.value(authStateChanges.asData!.value)
          : const Stream.empty(),
    ),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
