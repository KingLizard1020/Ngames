import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngames/screens/auth/auth_screen.dart';
import 'package:ngames/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

part 'auth_screen_test.mocks.dart';

@GenerateMocks([AuthService, User])
void main() {
  late MockAuthService mockAuthService;
  late MockUser mockUser;

  // Helper to create a GoRouter instance for testing
  GoRouter setupTestRouter(
    Widget widgetUnderTest, {
    String initialLocation = '/auth',
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/auth', // Route for the AuthScreen
          builder: (context, state) => widgetUnderTest,
        ),
        GoRoute(
          path: '/', // Dummy home route for navigation verification
          builder:
              (context, state) =>
                  const Scaffold(body: Text('Mock Home Screen')),
        ),
      ],
    );
    return router;
  }

  setUp(() {
    mockAuthService = MockAuthService();
    mockUser = MockUser();

    // Default stub for authStateChanges, can be overridden in specific tests
    when(
      mockAuthService.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));
    // Default stubs for auth methods - will be overridden in specific tests if needed
    when(
      mockAuthService.signInWithEmailAndPassword(any, any),
    ).thenAnswer((_) async => mockUser); // Default to success for some tests
    when(
      mockAuthService.createUserWithEmailAndPassword(any, any),
    ).thenAnswer((_) async => mockUser); // Default to success for some tests
  });

  Widget createTestableWidget({
    required Widget child,
    required GoRouter router,
  }) {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        // Explicitly override authStateChangesProvider for consistency,
        // though the test-specific router doesn't use app_router's redirect logic.
        authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AuthScreen Tests', () {
    testWidgets('renders correctly with initial UI elements', (
      WidgetTester tester,
    ) async {
      final testRouter = setupTestRouter(const AuthScreen());
      await tester.pumpWidget(
        createTestableWidget(child: const AuthScreen(), router: testRouter),
      );

      expect(find.widgetWithText(AppBar, 'Login / Register'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // AppBar title, Email label, Password label, Sign In text, Register text
      expect(find.byType(Text), findsNWidgets(5));
    });

    testWidgets('shows loading indicator when signing in', (
      WidgetTester tester,
    ) async {
      final testRouter = setupTestRouter(const AuthScreen());
      final spiedTestRouter = spy(testRouter); // Spy on the router instance

      when(mockAuthService.signInWithEmailAndPassword(any, any)).thenAnswer((
        _,
      ) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockUser;
      });
      // Stub the go method on the spied router. Since go returns void:
      when(
        spiedTestRouter.go(any),
      ).thenAnswer((_) {}); // Corrected: non-async, returns nothing

      await tester.pumpWidget(
        createTestableWidget(
          child: const AuthScreen(),
          router: spiedTestRouter,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('shows Firebase error message on sign-in failure', (
      WidgetTester tester,
    ) async {
      final testRouter = setupTestRouter(const AuthScreen());
      final spiedTestRouter = spy(testRouter);

      final exception = FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user found for that email.',
      );
      when(
        mockAuthService.signInWithEmailAndPassword(any, any),
      ).thenThrow(exception);
      when(spiedTestRouter.go(any)).thenAnswer((_) {}); // Corrected

      await tester.pumpWidget(
        createTestableWidget(
          child: const AuthScreen(),
          router: spiedTestRouter,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'wrong@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'wrongpassword',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Sign-in failed: No user found for that email. (Code: user-not-found)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows Firebase error message on registration failure', (
      WidgetTester tester,
    ) async {
      final testRouter = setupTestRouter(const AuthScreen());
      final spiedTestRouter = spy(testRouter);

      final exception = FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );
      when(
        mockAuthService.createUserWithEmailAndPassword(any, any),
      ).thenThrow(exception);
      when(spiedTestRouter.go(any)).thenAnswer((_) {}); // Corrected

      await tester.pumpWidget(
        createTestableWidget(
          child: const AuthScreen(),
          router: spiedTestRouter,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'existing@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Registration failed: The email address is already in use by another account. (Code: email-already-in-use)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('navigates on successful sign-in', (WidgetTester tester) async {
      final testRouter = setupTestRouter(const AuthScreen());
      final spiedTestRouter = spy(testRouter);

      when(
        mockAuthService.signInWithEmailAndPassword(any, any),
      ).thenAnswer((_) async => mockUser);
      // Stub the specific navigation call we expect
      when(spiedTestRouter.go('/')).thenAnswer((_) {}); // Corrected

      await tester.pumpWidget(
        createTestableWidget(
          child: const AuthScreen(),
          router: spiedTestRouter,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'password',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      verify(spiedTestRouter.go('/')).called(1);
    });

    testWidgets('navigates on successful registration', (
      WidgetTester tester,
    ) async {
      final testRouter = setupTestRouter(const AuthScreen());
      final spiedTestRouter = spy(testRouter);

      when(
        mockAuthService.createUserWithEmailAndPassword(any, any),
      ).thenAnswer((_) async => mockUser);
      when(spiedTestRouter.go('/')).thenAnswer((_) {}); // Corrected

      await tester.pumpWidget(
        createTestableWidget(
          child: const AuthScreen(),
          router: spiedTestRouter,
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Email'),
        'new@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password'),
        'newpassword',
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pumpAndSettle();

      verify(spiedTestRouter.go('/')).called(1);
    });
  });
}
