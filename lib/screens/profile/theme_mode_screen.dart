// lib/screens/profile/theme_mode_screen.dart
import 'package:charmy_craft_studio/state/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeModeScreen extends ConsumerWidget {
  const ThemeModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeProvider).themeMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Appearance', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setMode(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Follow System'),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setMode(value);
              }
            },
          ),
        ],
      ),
    );
  }
}