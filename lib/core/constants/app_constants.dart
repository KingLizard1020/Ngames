/// Application-wide constants and configuration values.
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// App name displayed in UI
  static const String appName = 'NGames';

  /// Welcome message on home screen
  static const String welcomeMessage = 'Welcome to NGames!';

  /// Default timeout for network requests
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Minimum password length for authentication
  static const int minPasswordLength = 6;
}
