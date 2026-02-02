import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/palette.dart';
import '../../../widgets/ui.dart';
import '../../../routes/app_routes.dart';
import '../../../models/language_flow.dart';

class LanguageHubScreen extends StatelessWidget {
  const LanguageHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Palette.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('KRATON', style: luckiestH(20)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SearchBar(),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 18),
              const SizedBox(width: 8),
              Text('LANGUAGE TRAINING',
                  style: GoogleFonts.luckiestGuy(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 18),
          Text('LISTENING AND SPEAKING',
              style: luckiestH(18, color: Palette.sky)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              PillButton(
                label: 'EASY',
                bg: Palette.green,
                fg: Colors.white,
                onTap: () =>
                    _openList(context, 'LISTENING AND SPEAKING', 'EASY'),
              ),
              PillButton(
                label: 'MEDIUM',
                bg: Palette.yellow,
                fg: Colors.black,
                onTap: () =>
                    _openList(context, 'LISTENING AND SPEAKING', 'MEDIUM'),
              ),
              PillButton(
                label: 'DIFFICULT',
                bg: Palette.red,
                fg: Colors.white,
                onTap: () =>
                    _openList(context, 'LISTENING AND SPEAKING', 'DIFFICULT'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('FILL IN THE BLANKS', style: luckiestH(18, color: Palette.sky)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              PillButton(
                label: 'EASY',
                bg: Palette.green,
                fg: Colors.white,
                onTap: () => _openList(context, 'FILL IN THE BLANKS', 'EASY'),
              ),
              PillButton(
                label: 'MEDIUM',
                bg: Palette.yellow,
                fg: Colors.black,
                onTap: () => _openList(context, 'FILL IN THE BLANKS', 'MEDIUM'),
              ),
              PillButton(
                label: 'DIFFICULT',
                bg: Palette.red,
                fg: Colors.white,
                onTap: () => _openList(context, 'FILL IN THE BLANKS', 'DIFFICULT'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openList(BuildContext context, String topic, String level) {
    Navigator.pushNamed(
      context,
      AppRoutes.languageList,
      arguments: LangListArgs(topic, level),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3DDF0),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Row(
        children: [
          Icon(Icons.menu_rounded, size: 18),
          SizedBox(width: 10),
          Expanded(
              child:
                  Text('search...', style: TextStyle(color: Colors.black54))),
          Icon(Icons.search, size: 20),
        ],
      ),
    );
  }
}
