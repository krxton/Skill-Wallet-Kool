// lib/theme/app_theme.dart
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

    // ฟอนต์จาก google_fonts
    final String thaiFallback = GoogleFonts.itim().fontFamily!;

    // เริ่มจาก TextTheme ของ Luckiest Guy (ใช้กับตัวอักษรอังกฤษ)
    TextTheme tt = GoogleFonts.luckiestGuyTextTheme(base.textTheme).apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    );

    // helper: เติม fallback ไทย (Itim) ให้ทุกสไตล์ โดยไม่ยุ่ง fontFamily เดิม
    TextStyle withThaiFallback(TextStyle? s) =>
        (s ?? const TextStyle()).merge(
          TextStyle(fontFamilyFallback: [thaiFallback]),
        );

    tt = tt.copyWith(
      displayLarge:   withThaiFallback(tt.displayLarge),
      displayMedium:  withThaiFallback(tt.displayMedium),
      displaySmall:   withThaiFallback(tt.displaySmall),
      headlineLarge:  withThaiFallback(tt.headlineLarge),
      headlineMedium: withThaiFallback(tt.headlineMedium),
      headlineSmall:  withThaiFallback(tt.headlineSmall),
      titleLarge:     withThaiFallback(tt.titleLarge),
      titleMedium:    withThaiFallback(tt.titleMedium),
      titleSmall:     withThaiFallback(tt.titleSmall),
      bodyLarge:      withThaiFallback(tt.bodyLarge),
      bodyMedium:     withThaiFallback(tt.bodyMedium),
      bodySmall:      withThaiFallback(tt.bodySmall),
      labelLarge:     withThaiFallback(tt.labelLarge),
      labelMedium:    withThaiFallback(tt.labelMedium),
      labelSmall:     withThaiFallback(tt.labelSmall),
    );

    return base.copyWith(
      scaffoldBackgroundColor: cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: yellow,
        surface: cream,
      ),

      textTheme: tt,
      primaryTextTheme: tt,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sky,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: withThaiFallback(
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: pink,
          textStyle: withThaiFallback(
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: withThaiFallback(
          const TextStyle(color: Colors.black54),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            // ✅ ใช้ withValues ตามคำแนะนำของ SDK
            color: Colors.black.withValues(alpha: .08),
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        titleTextStyle: withThaiFallback(
          GoogleFonts.luckiestGuy(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
