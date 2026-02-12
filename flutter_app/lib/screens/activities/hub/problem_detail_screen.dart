import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../../routes/app_routes.dart';
import '../../../theme/palette.dart';

class ProblemDetailScreen extends StatelessWidget {
  const ProblemDetailScreen({super.key});

  // 🎨 สีตาม Theme
  static const greenBtn = Color(0xFF88C273);
  static const purpleBtn = Color(0xFFCD9EFF);
  static const blueBtn = Color(0xFFA2D2FF);
  static const textBlue = Color(0xFF5AB2FF); // สีตัวหนังสือในโจทย์

  @override
  Widget build(BuildContext context) {
    // รับข้อมูล arguments ที่ส่งมาจากหน้า List
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final String question = args['question'] ??
        "THERE ARE 6 CATS IN THE FIELD.\nANOTHER 2 CATS WALK INTO THE FIELD.\nHOW MANY CATS ARE THERE IN TOTAL ?";

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.problemdetail_title,
          style: GoogleFonts.luckiestGuy(
            fontSize: 26,
            color: Palette.sky,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            // การ์ดคำถาม (สีขาว)
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
                  height: 1.4, // ระยะห่างบรรทัด
                ),
              ),
            ),

            const Spacer(), // ดันปุ่มลงไปด้านล่าง

            // ปุ่ม START และ CAST TO TV
            Row(
              children: [
                // ปุ่ม START -> กดแล้วไปหน้าเล่นเกม (ProblemPlayingPage)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 🆕 แก้ไข: ลิงก์ไปหน้า Playing Page
                      Navigator.pushNamed(
                        context,
                        AppRoutes.problemPlaying,
                        arguments: args, // ส่งข้อมูลโจทย์/เฉลย ต่อไปด้วย
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenBtn,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.common_start,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // ปุ่ม CAST TO TV
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Logic ปุ่ม Cast
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purpleBtn,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.problemdetail_castToTvBtn,
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ปุ่ม ANSWER -> ไปหน้าเฉลย (ProblemAnswerPage)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.problemAnswer,
                    arguments: args,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueBtn,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.problemdetail_answerBtn,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
