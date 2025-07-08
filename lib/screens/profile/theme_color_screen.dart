// lib/screens/profile/theme_color_screen.dart
import 'package:charmy_craft_studio/state/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeColorScreen extends ConsumerWidget {
  const ThemeColorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Color', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: appThemes.length,
        itemBuilder: (context, index) {
          final themeColor = appThemes.values.elementAt(index);
          final isSelected = currentTheme.themeData.primaryColor == themeColor;

          return InkWell(
            onTap: () {
              ref.read(themeProvider.notifier).setColor(themeColor);
            },
            borderRadius: BorderRadius.circular(100),
            child: CircleAvatar(
              backgroundColor: themeColor,
              child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
            ),
          );
        },
      ),
    );
  }
}