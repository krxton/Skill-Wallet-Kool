// lib/screens/language_list_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/palette.dart';
import '../widgets/ui.dart';
import '../routes/app_routes.dart';
import '../models/language_flow.dart';

class LanguageListScreen extends StatelessWidget {
  const LanguageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as LangListArgs;
    final items = const [
      'TALE OF PETER RABBIT & BENJAMIN BUNNY',
      'OLAF’S FROZEN ADVENTURE',
      'ALADDIN AND HIS WONDERFUL LAMP',
      'PASCAL’S STORY',
    ];

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Palette.cream,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: Text(args.topic, style: luckiestH(18, color: Palette.sky)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => OutlineCard(
          // ✅ แก้ onTap: ยังไม่ส่ง LangItemArgs ไป itemIntro (เพราะต้องใช้ Activity)
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This flow is not connected to activities yet.'),
              ),
            );

            // ถ้าต่อกับ backend แล้ว ค่อยเปลี่ยนเป็น:
            // final activity = ... ดึง Activity จาก API หรือ mapping
            // Navigator.pushNamed(
            //   context,
            //   AppRoutes.itemIntro,
            //   arguments: activity,
            // );
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  items[i],
                  style: GoogleFonts.luckiestGuy(fontSize: 16),
                  maxLines: 2,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Palette.sky,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
