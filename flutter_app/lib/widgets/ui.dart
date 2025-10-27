import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/palette.dart';

// เปลี่ยนให้รับ double
TextStyle luckiestH(double size, {Color? color}) =>
    GoogleFonts.luckiestGuy(fontSize: size, color: color ?? Palette.text);

class PillButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final double fontSize;

  const PillButton({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.radius = 22,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: padding,
          child: Text(label, style: luckiestH(fontSize, color: fg)),
        ),
      ),
    );
  }
}

class OutlineCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const OutlineCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Palette.blueChip, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: child,
        ),
      ),
    );
  }
}

class TinyProgress extends StatelessWidget {
  final double value; // 0..1
  const TinyProgress({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(height: 14, color: Palette.progressBg),
          FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(height: 14, color: Palette.progressFill),
          ),
        ],
      ),
    );
  }
}
