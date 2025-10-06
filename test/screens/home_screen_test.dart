import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ngames/screens/home/home_screen.dart';
import 'package:ngames/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

part 'home_screen_test.mocks.dart';

@GenerateMocks([AuthService, User])
void main() {
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late GoRouter spiedGoRouter;

  GoRouter setupTestRouter(Widget homeWidget, {String initialLocation = '/'}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => homeWidget),
        GoRoute(
          path: '/game/example',
          builder:
              (context, state) =>
                  const Scaffold(body: Text('Mock Game Screen')),
        ),
        GoRoute(
          path: '/auth', // Add auth route for logout navigation testing
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
    when(
      mockAuthService.signOut(),
    ).thenAnswer((_) async {
      return null;
    }); // Correct for Future<void>
    // No default stub for spiedGoRouter.go here, will be set in specific tests if needed
  });

  Widget createTestableHomeScreen({required GoRouter router}) {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        authStateChangesProvider.overrideWith((ref) => Stream.value(mockUser)),
      ],
      child: MaterialApp.router(
        routerConfig: router, // Use the provided (potentially spied) router
      ),
    );
  }

  testWidgets('HomeScreen renders correctly and shows welcome message', (
    WidgetTester tester,
  ) async {
    final testRouter = setupTestRouter(const HomeScreen());
    await tester.pumpWidget(createTestableHomeScreen(router: testRouter));

    expect(find.text('NGames Home'), findsOneWidget);
    expect(find.text('Welcome to NGames!'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.text('Example Game 1'), findsOneWidget);
  });

  testWidgets('tapping logout button calls signOut', (
    WidgetTester tester,
  ) async {
    final testRouter = setupTestRouter(
      const HomeScreen(),
      initialLocation: '/',
    );

    await tester.pumpWidget(createTestableHomeScreen(router: testRouter));

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    verify(mockAuthService.signOut()).called(1);
  });

  testWidgets('tapping a game navigates to the game screen', (
    WidgetTester tester,
  ) async {
    final initialRouter = setupTestRouter(
      const HomeScreen(),
      initialLocation: '/',
    );
    spiedGoRouter = spy(initialRouter); // Spy on the router instance

    // Stub the go method on the spied router. Since go returns void:
    when(
      spiedGoRouter.go(any),
    ).thenAnswer((_) {}); // Corrected: non-async, returns nothing

    await tester.pumpWidget(createTestableHomeScreen(router: spiedGoRouter));

    await tester.tap(find.text('Example Game 1'));
    await tester.pumpAndSettle();

    verify(spiedGoRouter.go('/game/example')).called(1);
  });
}
