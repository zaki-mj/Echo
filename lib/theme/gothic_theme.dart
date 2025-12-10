import 'package:flutter/material.dart';

class GothicTheme {
  // 8 Gothic accent colors
  static const List<Color> accentColors = [
    Color(0xFF8B0000), // Dark Red
    Color(0xFF4B0082), // Indigo
    Color(0xFF800080), // Purple
    Color(0xFF2F4F4F), // Dark Slate Gray
    Color(0xFF8B4513), // Saddle Brown
    Color(0xFF556B2F), // Dark Olive Green
    Color(0xFF483D8B), // Dark Slate Blue
    Color(0xFF8B0000), // Crimson
  ];

  static ThemeData getDarkTheme(int accentIndex) {
    final accentColor = accentColors[accentIndex.clamp(0, 7)];
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      cardColor: const Color(0xFF1A1A1A),
      dividerColor: const Color(0xFF2A2A2A),
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: const Color(0xFF6B006B), // Shadow purple
        surface: const Color(0xFF1A1A1A),
        background: const Color(0xFF0A0A0A),
        error: const Color(0xFF8B0000),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white70,
        onBackground: Colors.white70,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Gothic',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Gothic',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white60,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: const TextStyle(
          fontFamily: 'Gothic',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }

  static ThemeData getLightTheme(int accentIndex) {
    final accentColor = accentColors[accentIndex.clamp(0, 7)];
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE0E0E0),
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: const Color(0xFF6B006B),
        surface: Colors.white,
        background: const Color(0xFFF5F5F5),
        error: const Color(0xFF8B0000),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Gothic',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Gothic',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          fontFamily: 'Gothic',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }
}

