import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:simple_music_player_2/providers/settings_provider.dart'; // Import ThemePreset

class AppTheme {
  // Use a predefined set of colors for the UI (similar to Spotube/Vibes)
  static const Color darkPrimaryColor =
      Color(0xFF6C5CE7); // Deep Purple/Blue Accent
  static const Color darkBackgroundColor =
      Color(0xFF0C131B); // Very dark background
  static const Color darkCardColor = Color(0xFF141F2B); // Sidebar/Card color

  // Method to get colors based on preset
  static Map<String, Color> getColorsForPreset(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.oledBlack:
        return {
          'background': Colors.black,
          'card': const Color(0xFF101010),
          'surface': const Color(0xFF101010),
        };
      case ThemePreset.deepGrey:
        return {
          'background': const Color(0xFF121212),
          'card': const Color(0xFF1E1E1E),
          'surface': const Color(0xFF1E1E1E),
        };
      case ThemePreset.dracula:
        return {
          'background': const Color(0xFF282A36),
          'card': const Color(0xFF44475A),
          'surface': const Color(0xFF44475A),
        };
      case ThemePreset.midnightPurple:
        return {
          'background': const Color(0xFF180E29), // Deep Purple Black
          'card': const Color(0xFF2D1B4E),
          'surface': const Color(0xFF2D1B4E),
        };
      case ThemePreset.forest:
        return {
          'background': const Color(0xFF0B140E),
          'card': const Color(0xFF162B1F),
          'surface': const Color(0xFF162B1F),
        };
      case ThemePreset.batikBlue:
         // Light Blue Theme for Batik
        return {
          'background': const Color(0xFFE3F2FD), // Light Blue 50
          'card': const Color(0xFFBBDEFB), // Light Blue 100
          'surface': const Color(0xFFFFFFFF), // White surface
          'text': const Color(0xFF0D47A1), // Dark Blue Text
          'icon': const Color(0xFF0D47A1), // Dark Blue Icon
        };
      case ThemePreset.deepBlue:
      default:
        return {
          'background': darkBackgroundColor,
          'card': darkCardColor,
          'surface': darkCardColor,
        };
    }
  }

  static ThemeData darkTheme(Color accentColor, ThemePreset preset) {
    final colors = getColorsForPreset(preset);
    final isLightMode = preset == ThemePreset.batikBlue; // Batik is light

    return ThemeData(
      brightness: isLightMode ? Brightness.light : Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: colors['background'],
      canvasColor: colors['background'], // Default background for drawers/dialogs
      cardColor: colors['card'], // Used for the Sidebar
      dividerColor: isLightMode ? Colors.black12 : Colors.white10,
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme(
        isLightMode ? ThemeData.light().textTheme : ThemeData.dark().textTheme
      ).apply(
        bodyColor: colors['text'],
        displayColor: colors['text'],
      ),
      colorScheme: isLightMode 
      ? ColorScheme.light(
          primary: accentColor,
          secondary: accentColor.withOpacity(0.8),
          surface: colors['surface']!,
          background: colors['background']!,
        )
      : ColorScheme.dark(
          primary: accentColor,
          secondary: accentColor.withOpacity(0.8),
          surface: colors['surface']!,
          background: colors['background']!,
        ),
      listTileTheme: ListTileThemeData(
        dense: true,
        selectedTileColor: accentColor.withOpacity(0.1),
        iconColor: colors['icon'] ?? Colors.white70,
        selectedColor: accentColor,
      ),
      iconTheme: IconThemeData(color: colors['icon'] ?? Colors.white70),
      appBarTheme: AppBarTheme(
        backgroundColor: colors['card'],
        foregroundColor: colors['text'] ?? Colors.white,
        elevation: 0,
      ),
    );
  }

  // Placeholder for light theme (required by main.dart)
  // We can reuse this for actual light themes if we want
  static ThemeData lightTheme(Color accentColor) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentColor,
      useMaterial3: true,
      // Add more customization if needed
    );
  }
}
