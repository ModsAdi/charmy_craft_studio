// lib/main.dart

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:charmy_craft_studio/core/app_theme.dart';
import 'package:charmy_craft_studio/firebase_options.dart';
import 'package:charmy_craft_studio/widgets/animated_nav_bar.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FIX: Re-enabled App Check with SafetyNet for reliable testing
  try {
    await FirebaseAppCheck.instance.activate(
      // For a release build on the Play Store, this uses Play Integrity.
      // For a debug build, this now uses SafetyNet.
      androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.safetyNet,
    );
    print('Firebase App Check activated successfully.');
  } catch (e) {
    print('⚠️ App Check initialization error: $e');
  }


  await MobileAds.instance.initialize();

  runApp(
    const ProviderScope(
      child: CharmyCraftStudio(),
    ),
  );
}

class CharmyCraftStudio extends ConsumerWidget {
  const CharmyCraftStudio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Forcing light theme for now as previously requested.
    final initialTheme = AppTheme.lightTheme;


    return ThemeProvider(
      initTheme: initialTheme,
      builder: (context, myTheme) {
        return MaterialApp(
          title: 'Charmy Craft Studio',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: const AnimatedNavBar(),
        );
      },
    );
  }
}