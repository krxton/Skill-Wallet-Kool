import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

class ProblemsSolveScreen extends StatelessWidget {
  const ProblemsSolveScreen({super.key});

  // 🎨 orange button color not in Palette, kept locally
  static const orangeBtn = Color(0xFFEF9C66);

  @override
  Widget build(BuildContext context) {
    // 📝 ข้อมูล Mock Data (จับคู่ชื่อเมนู กับ คำถามและคำตอบ)
    final List<Map<String, String>> problems = [
      {
        "title": "1. CATS IN THE FIELD",
        "question":
            "THERE ARE 6 CATS IN THE FIELD.\nANOTHER 2 CATS WALK INTO THE FIELD.\nHOW MANY CATS ARE THERE IN TOTAL ?",
        "answer": "THERE ARE 8 CATS IN TOTAL."
      },
      {
        "title": "2. WHO",
        "question": "WHO IS SITTING NEXT TO YOU?",
        "answer": "MY FRIEND IS SITTING NEXT TO ME."
      },
      // ... ใส่ข้อมูลเพิ่มได้ตามต้องการ
      {"title": "3. ARE", "question": "...", "answer": "..."},
      {"title": "4. YOU", "question": "...", "answer": "..."},
      {"title": "5. WHO", "question": "...", "answer": "..."},
      {"title": "6. ARE", "question": "...", "answer": "..."},
      {"title": "7. YOU", "question": "...", "answer": "..."},
      {"title": "8. WHO", "question": "...", "answer": "..."},
      {"title": "9. ARE", "question": "...", "answer": "..."},
      {"title": "10. YOU", "question": "...", "answer": "..."},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.problemplaying_title,
          style: AppTextStyles.heading(28, color: Palette.sky).copyWith(
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        itemCount: problems.length,
        itemBuilder: (context, index) {
          final item = problems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: () {
                // 🆕 กดแล้วไปหน้า Detail พร้อมส่งข้อมูล
                Navigator.pushNamed(context, AppRoutes.problemDetail,
                    arguments: {
                      "question": item['question'],
                      "answer": item['answer'],
                    });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeBtn,
                foregroundColor: Palette.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['title']!,
                    style: AppTextStyles.heading(20, color: Palette.white),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 30, color: Colors.black87),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
