import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 Brand Palette
  static const Color cream = Color(0xFFFFF5CD);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color lightYellow = Color(0xFFFFCB61);
  static const Color sky = Color(0xFF77BEF0);
  static const Color orange = Color(0xFFFF894F);
  static const Color pink = Color(0xFFEA5B6F);
  static const Color green = Color(0xFF72BF78);
  static const Color lightGreen = Color(0xFFA0D683);
  static const Color pastelGreen = Color(0xFFD3EE98);
  static const Color lightRed = Color(0xFFFF8282);
  static const Color red = Color(0xFFFF6363);
  static const Color blue = Color(0xFF0D92F4);

  static ThemeData light() {
    final base = ThemeData.light();

    return base.copyWith(
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: yellow,
        surface: cream,
      ),

      // ใช้ฟอนต์ Luckiest Guy ทั่วทั้งแอป
      textTheme: GoogleFonts.luckiestGuyTextTheme(base.textTheme).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sky,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: pink,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: .08)),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        titleTextStyle: GoogleFonts.luckiestGuy(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
      ),
    );
  }
}
