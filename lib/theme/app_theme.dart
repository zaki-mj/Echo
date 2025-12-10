import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF6A0DAD), // Shadow Purple
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6A0DAD), // Shadow Purple
      secondary: Color(0xFFB22222), // Crimson
      background: Color(0xFFF5F5DC), // Antique White
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black,
    ),
    fontFamily: 'Garamond', // Example of a gothic-style font
    // ... other theme properties
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFB22222), // Crimson
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFB22222), // Crimson
      secondary: Color(0xFF6A0DAD), // Shadow Purple
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    fontFamily: 'Garamond',
    // ... other theme properties
  );
}
