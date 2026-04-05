import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ivory = Color(0xFFF6F1E9);
  static const Color onyx = Color(0xFF1B1A17);
  static const Color sand = Color(0xFFE5D7C5);
  static const Color bronze = Color(0xFF8B6A46);
  static const Color forest = Color(0xFF2E4A3F);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.cormorantGaramondTextTheme(base.textTheme).copyWith(
      bodyLarge: GoogleFonts.manrope(fontSize: 16, color: onyx),
      bodyMedium: GoogleFonts.manrope(fontSize: 14, color: onyx),
      labelLarge: GoogleFonts.manrope(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      scaffoldBackgroundColor: ivory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: bronze,
        brightness: Brightness.light,
        primary: bronze,
        secondary: forest,
        surface: ivory,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onyx,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.75),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
