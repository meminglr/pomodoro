import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50), // Nature Green
        brightness: Brightness.light,
        surface: const Color(0xFFF5F9F5), // Light minty background
        primary: const Color(0xFF2E7D32),
        secondary: const Color(0xFFFF9800), // Focus Orange
      ),
      textTheme: GoogleFonts.outfitTextTheme(),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4CAF50),
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
        primary: const Color(0xFF81C784),
        secondary: const Color(0xFFFFB74D),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
