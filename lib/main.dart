// lib/main.dart

import 'package:charmy_craft_studio/firebase_options.dart';
import 'package:charmy_craft_studio/screens/auth/login_screen.dart';
import 'package:charmy_craft_studio/services/auth_service.dart';
import 'package:charmy_craft_studio/state/theme_provider.dart';
import 'package:charmy_craft_studio/widgets/animated_nav_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Initialize the provider with the prefs instance
        themeProvider.overrideWith((ref) => ThemeNotifier(prefs)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme state
    final appThemeState = ref.watch(themeProvider);
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      title: 'Charmi Craft Studio',
      debugShowCheckedModeBanner: false,

      // Use the theme data and theme mode from our provider
      theme: appThemeState.themeData,
      darkTheme: ThemeData.dark().copyWith( // Optional: Define a dark theme
        colorScheme: ColorScheme.fromSeed(
            seedColor: appThemeState.themeData.primaryColor,
            brightness: Brightness.dark
        ),
      ),
      themeMode: appThemeState.themeMode,

      home: authState.when(
        data: (user) => user != null ? const AnimatedNavBar() : const LoginScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => const Scaffold(body: Center(child: Text('Something went wrong'))),
      ),
    );
  }
}