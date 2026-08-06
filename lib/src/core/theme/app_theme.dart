import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'expressive_tokens.dart';

class AppTheme {
  // Cyber Gym Palette
  // static const Color primaryColor = Color(0xFFD500F9); // REMOVED - Dynamic
  static const Color secondaryColor = Color(0xFFEA80FC); // Lilac Accent
  static const Color actionColor = Color(0xFFFF4081); // Cyber Pink

  static const Color darkBackground = Color(0xFF121212); // Deep Black
  static const Color darkSurface = Color(0xFF1E1E1E); // Dark Grey Card
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Colors.white;
  static const Color errorColor = Color(0xFFFF1744); // Neon Red

  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        lightSurface,
        Colors.grey.shade400,
        primaryColor,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(primaryColor),
      // Token del design system Expressive: vedi docs/adr/001-material-3-expressive.md
      extensions: const <ThemeExtension<dynamic>>[ExpressiveTokens()],
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        darkSurface,
        const Color(0xFF333333),
        primaryColor,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(primaryColor),
      // Token del design system Expressive: vedi docs/adr/001-material-3-expressive.md
      extensions: const <ThemeExtension<dynamic>>[ExpressiveTokens()],
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryColor.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.all(
          const IconThemeData(color: Colors.white),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(
    Color fill,
    Color borderColor,
    Color primaryColor,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color primaryColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 4,
        shadowColor: primaryColor.withValues(alpha: 0.4),
      ),
    );
  }
}
