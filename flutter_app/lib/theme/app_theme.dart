import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color cream = Color(0xFFF9F1CF);
  static const Color lilac = Color(0xFF8A6FB3);
  static const Color coral = Color(0xFFE86F6F);
  static const Color leaf = Color(0xFF5DBB63);
  static const Color sky = Color(0xFF9ED0FF);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: lilac,
        background: cream,
      ),
      scaffoldBackgroundColor: cream,
      textTheme: GoogleFonts.fredokaTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(.08)),
        ),
      ),
    );
  }
}
