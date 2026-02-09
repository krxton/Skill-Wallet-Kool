import 'package:flutter/material.dart';

/// Single source of truth for all app colors.
/// Adjust once here → reflects everywhere.
class Palette {
  Palette._(); // prevent instantiation

  // ── Base ──────────────────────────────────────────────
  static const cream = Color(0xFFFFF5CD);
  static const text = Colors.black87;
  static const deepGrey = Color(0xFF5D5D5D);

  // ── Brand / Primary ──────────────────────────────────
  static const sky = Color(0xFF0D92F4); // primary blue
  static const deepSky = Color(0xFF7DBEF1); // lighter blue (home)
  static const blueChip = Color(0xFF59B3FF); // chip/tag blue
  static const blueBtn = Color(0xFF6EC1FF); // play-section blue
  static const bluePill = Color(0xFF78BDF1); // pill badge blue

  // ── Semantic ─────────────────────────────────────────
  static const success = Color(0xFF88C273); // correct / green button
  static const successAlt = Color(0xFF66BB6A); // start / ok green
  static const error = Color(0xFFFF8A8A); // error text / red light
  static const errorStrong = Color(0xFFE85C5C); // record / strong red
  static const warning = Color(0xFFFF9800); // orange (difficulty)
  static const warningLight = Color(0xFFFFB74D); // selected filter

  // ── Accents ──────────────────────────────────────────
  static const pink = Color(0xFFEA5B6F); // back button / finish
  static const purple = Color(0xFFB67CFF); // cast to TV
  static const yellow = Color(0xFFFFD45E); // airplay
  static const yellowBright = Color(0xFFFFCC00); // seed color
  static const yellowLight = Color(0xFFFFCB61);
  static const facebook = Color(0xFF1877F2); // Facebook blue

  // ── Surface / Card ───────────────────────────────────
  static const greyCard = Color(0xFFE9E9EB);
  static const divider = Color(0xFFE5E5E5);
  static const labelGrey = Color(0xFF9E9E9E);
  static const deleteRed = Color(0xFFFF6B6B);
  static const lightBlue = Color(0xFFA2D2FF); // accent blue

  // ── Progress bars ────────────────────────────────────
  static const progressBg = Color(0xFFEEE8D5);
  static const progressFill = Color(0xFF8ED081);

  // ── Category placeholders ────────────────────────────
  static const languagePlaceholder = Color(0xFFFFEB3B); // yellow
  static const physicalPlaceholder = Color(0xFFFFAB91); // pink/peach
}
