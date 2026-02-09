import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

/// Centralized text styles for the app.
/// Use these instead of calling GoogleFonts directly in screens.
class AppTextStyles {
  AppTextStyles._();

  static final String _thaiFallback = GoogleFonts.itim().fontFamily!;

  /// Heading font (Luckiest Guy + Itim fallback for Thai)
  static TextStyle heading(double size, {Color? color}) {
    return GoogleFonts.luckiestGuy(
      fontSize: size,
      color: color ?? Palette.text,
    ).copyWith(
      fontFamilyFallback: [_thaiFallback],
    );
  }

  /// Body font (Open Sans)
  static TextStyle body(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.openSans(
      fontSize: size,
      color: color ?? Colors.black,
      fontWeight: weight,
    );
  }

  /// Label font (Open Sans, smaller, semi-bold)
  static TextStyle label(double size, {Color? color}) {
    return GoogleFonts.openSans(
      fontSize: size,
      color: color ?? Palette.deepGrey,
      fontWeight: FontWeight.w600,
    );
  }
}
