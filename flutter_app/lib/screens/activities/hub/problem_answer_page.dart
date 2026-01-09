import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProblemAnswerPage extends StatelessWidget {
  const ProblemAnswerPage({super.key});

  // 🎨 สีตาม Theme
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const textBlue = Color(0xFF5AB2FF);
  static const limeGreen = Color(0xFFDCE775); // สีพื้นหลังเฉลย (เขียวอ่อน)
  static const darkText = Color(0xFF555555); // สีตัวหนังสือเฉลย

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final String question = args['question'] ??
        "THERE ARE 6 CATS IN THE FIELD.\nANOTHER 2 CATS WALK INTO THE FIELD.\nHOW MANY CATS ARE THERE IN TOTAL ?";

    final String answer = args['answer'] ?? "THERE ARE 8 CATS IN TOTAL.";

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'ANSWER',
          style: GoogleFonts.luckiestGuy(
            fontSize: 28,
            color: sky,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            // 1. การ์ดคำถาม (สีขาว เหมือนหน้าก่อนหน้า)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                question,
                textAlign: TextAlign.center,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 22,
                  color: textBlue,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. การ์ดเฉลย (สีเขียวอ่อน)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: limeGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                answer,
                textAlign: TextAlign.center,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 22,
                  color: darkText, // สีเทาเข้มเพื่อให้ตัดกับพื้นหลัง
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
