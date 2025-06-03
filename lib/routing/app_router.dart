import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngames/screens/auth/auth_screen.dart';
import 'package:ngames/screens/home/home_screen.dart';
import 'package:ngames/games/example_game/example_game_screen.dart';
// import 'package:ngames/services/auth_service.dart'; // Will be used later

// Provider for the GoRouter instance
// final goRouterProvider = Provider<GoRouter>((ref) {
//   // final authService = ref.watch(authServiceProvider); // Placeholder for auth service provider
//   return GoRouter(
//     initialLocation: '/',
//     routes: [
//       GoRoute(
//         path: '/',
//         builder: (context, state) => const HomeScreen(),
//       ),
//       GoRoute(
//         path: '/auth',
//         builder: (context, state) => const AuthScreen(),
//       ),
//       GoRoute(
//         path: '/game/example',
//         builder: (context, state) => const ExampleGameScreen(),
//       ),
//     ],
//     // redirect: (BuildContext context, GoRouterState state) {
//     //   // final loggedIn = authService.authStateChanges.map((user) => user != null); // Simplified
//     //   // final loggingIn = state.matchedLocation == '/auth';
//     //
//     //   // This is a simplified redirect logic. You'll need to adapt it based on Riverpod async providers.
//     //   // if (!loggedIn && !loggingIn) return '/auth';
//     //   // if (loggedIn && loggingIn) return '/';
//     //   return null;
//     // },
//   );
// });

// Placeholder for auth service provider if you create one for Riverpod
// final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// For now, a simple router setup without auth redirection.
// You can uncomment and expand the above when auth is fully integrated.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
        path: '/game/example',
        pageBuilder:
            (context, state) => const MaterialPage(child: ExampleGameScreen()),
      ),
    ],
  );
});
