import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_system.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignSystem.primaryPurple,
        primary: DesignSystem.primaryPurple,
        secondary: DesignSystem.primaryOrange,
        surface: DesignSystem.softWhite,
      ),
      scaffoldBackgroundColor: DesignSystem.softWhite,
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          color: DesignSystem.charcoal,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.outfit(
          color: DesignSystem.charcoal,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: DesignSystem.charcoal,
          fontSize: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: DesignSystem.radius16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: DesignSystem.radius16,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignSystem.radius16,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignSystem.radius16,
          borderSide: const BorderSide(
            color: DesignSystem.primaryPurple,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(20),
      ),
    );
  }
}
