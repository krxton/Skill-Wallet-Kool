import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.parentName,
    required this.categoryValue,
    required this.onCategoryChanged,
  });

  final String? parentName;
  final String categoryValue;
  final ValueChanged<String?> onCategoryChanged;

  static const blush = Color(0xFFF6D9DC);
  static const sky = Color(0xFF0D92F4);
  static const deepSky = Color(0xFF7DBEF1);

  @override
  Widget build(BuildContext context) {
    final thaiFallback = [GoogleFonts.itim().fontFamily!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search pill
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: blush,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.menu, color: Colors.black87),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'SEARCH...',
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .5,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.search, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (parentName != null && parentName!.isNotEmpty)
          Text(
            parentName!,
            style: GoogleFonts.luckiestGuy(
              fontSize: 28,
              height: 1.0,
              color: sky,
            ).copyWith(fontFamilyFallback: thaiFallback),
          ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: deepSky.withOpacity(.75),
            borderRadius: BorderRadius.circular(28),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: categoryValue,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: deepSky,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.black87),
              style: GoogleFonts.luckiestGuy(
                fontSize: 20,
                color: Colors.white,
              ).copyWith(fontFamilyFallback: thaiFallback),
              items: const [
                'CATEGORY',
                'PHYSICAL',
                'LANGUAGE',
                'CALCULATION',
              ]
                  .map(
                    (v) =>
                        DropdownMenuItem<String>(value: v, child: Text(v)),
                  )
                  .toList(),
              onChanged: onCategoryChanged,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
