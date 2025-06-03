import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ngames/routing/app_router.dart'; // Import the router
import 'firebase_options.dart'; // Make sure you have this file after FlutterFire CLI setup

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure you have run `flutterfire configure` and have firebase_options.dart
  // If you don't have firebase_options.dart yet, you can comment out the next line
  // and the import for it, but Firebase will not be initialized.
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions
            .currentPlatform, // Uncomment after firebase_options.dart is generated
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(
      goRouterProvider,
    ); // Get the router from the provider
    return MaterialApp.router(
      routerConfig: router,
      title: 'NGames',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
