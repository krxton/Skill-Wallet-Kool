import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

class ProblemAnswerScreen extends StatelessWidget {
  const ProblemAnswerScreen({super.key});

  // 🎨 colors not in Palette, kept locally
  static const limeGreen = Color(0xFFDCE775); // สีพื้นหลังเฉลย (เขียวอ่อน)

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final String question = args['question'] ??
        "THERE ARE 6 CATS IN THE FIELD.\nANOTHER 2 CATS WALK INTO THE FIELD.\nHOW MANY CATS ARE THERE IN TOTAL ?";

    final String answer = args['answer'] ?? "THERE ARE 8 CATS IN TOTAL.";

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
          AppLocalizations.of(context)!.problemanswer_title,
          style: AppTextStyles.heading(28, color: Palette.sky).copyWith(
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
                color: Palette.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                question,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading(22, color: Palette.blueChip).copyWith(
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
                style: AppTextStyles.heading(22,
                    color: Palette.deepGrey), // สีเทาเข้มเพื่อให้ตัดกับพื้นหลัง
              ),
            ),
          ],
        ),
      ),
    );
  }
}
