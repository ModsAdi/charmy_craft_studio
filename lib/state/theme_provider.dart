// lib/state/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A map of theme names to their color values
final Map<String, Color> appThemes = {
  'Default': const Color(0xFFFA8100), // A nice default orange
  'Emerald': const Color(0xFF2ecc71),
  'River': const Color(0xFF3498db),
  'Amethyst': const Color(0xFF9b59b6),
  'Ruby': const Color(0xFFe74c3c),
  'Sun': const Color(0xFFf1c40f),
  'Ocean': const Color(0xFF1abc9c),
  'Hot Pink': const Color(0xFFff7675),
};

// Custom class to hold both theme mode and color
class AppThemeState {
  final ThemeData themeData;
  final ThemeMode themeMode;
  AppThemeState(this.themeData, this.themeMode);
}

// State Notifier for managing the theme
class ThemeNotifier extends StateNotifier<AppThemeState> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(_getInitialTheme(_prefs));

  // Method to get the initial theme from storage
  static AppThemeState _getInitialTheme(SharedPreferences prefs) {
    // Load saved color, default to 'Default'
    final colorName = prefs.getString('themeColor') ?? 'Default';
    final color = appThemes[colorName] ?? const Color(0xFFFA8100);

    // Load saved theme mode, default to 'System'
    final themeModeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
    final themeMode = ThemeMode.values[themeModeIndex];

    return AppThemeState(_buildTheme(color), themeMode);
  }

  // Method to update and save the color
  void setColor(Color newColor) {
    final colorName = appThemes.entries
        .firstWhere((entry) => entry.value == newColor, orElse: () => appThemes.entries.first)
        .key;

    _prefs.setString('themeColor', colorName);
    // Rebuild the theme with the new color, but keep the existing mode
    state = AppThemeState(_buildTheme(newColor), state.themeMode);
  }

  // Method to update and save the theme mode (light/dark/system)
  void setMode(ThemeMode newThemeMode) {
    _prefs.setInt('themeMode', newThemeMode.index);
    // Rebuild the theme with the existing color, but use the new mode
    state = AppThemeState(_buildTheme(state.themeData.primaryColor), newThemeMode);
  }

  // Central place to define your app's theme. Now it only needs the primary color.
  static ThemeData _buildTheme(Color primaryColor) {
    return ThemeData(
      primarySwatch: _createMaterialColor(primaryColor),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: primaryColor,
        brightness: Brightness.light,
      ),
      // You can define your dark theme here if you want different styles
      // darkTheme: ThemeData.dark().copyWith(...),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

// The single provider that the rest of the app will use
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeState>((ref) {
  throw UnimplementedError();
});