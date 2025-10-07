import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngames/screens/home/home_screen.dart';
import 'package:ngames/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

import 'home_screen_test.mocks.dart';

@GenerateMocks([AuthService, User])
void main() {
  late MockAuthService mockAuthService;
  late MockUser mockUser;

  GoRouter setupTestRouter(Widget homeWidget, {String initialLocation = '/'}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => homeWidget),
        GoRoute(
          path: '/game/wordle',
          builder:
              (context, state) =>
                  const Scaffold(body: Text('Mock Wordle Screen')),
        ),
        GoRoute(
          path: '/auth',
          builder:
              (context, state) =>
                  const Scaffold(body: Text('Mock Auth Screen')),
        ),
      ],
    );
    return router;
  }

  setUp(() {
    mockAuthService = MockAuthService();
    mockUser = MockUser();

    when(
      mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(mockUser));
    when(mockAuthService.signOut()).thenAnswer((_) async => null);
  });

  Widget createTestableHomeScreen({required GoRouter router}) {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        authStateChangesProvider.overrideWith((ref) => Stream.value(mockUser)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('HomeScreen renders correctly and shows welcome message', (
    WidgetTester tester,
  ) async {
    final testRouter = setupTestRouter(const HomeScreen());
    await tester.pumpWidget(createTestableHomeScreen(router: testRouter));

    expect(find.text('NGames Home'), findsOneWidget);
    expect(find.text('Welcome to NGames!'), findsOneWidget);
    expect(find.text('Wordle'), findsOneWidget);
  });

  testWidgets('HomeScreen shows game tiles', (WidgetTester tester) async {
    final router = setupTestRouter(const HomeScreen(), initialLocation: '/');
    await tester.pumpWidget(createTestableHomeScreen(router: router));

    expect(find.text('Wordle'), findsOneWidget);
    expect(find.text('Snake'), findsOneWidget);
    expect(find.text('Hangman'), findsOneWidget);
  });
}
