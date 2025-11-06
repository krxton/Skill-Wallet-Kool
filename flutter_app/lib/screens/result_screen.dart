// lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: unused_import
import '../theme/palette.dart';
import '../routes/app_routes.dart';
import '../models/activity.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 🌀 Animation สำหรับขยายคะแนนตอนเปิดหน้า
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?) ??
            {};

    final int totalScore = (args['totalScore'] as int?) ?? 0;
    final String activityName =
        (args['activityName'] as String?) ?? 'ACTIVITY COMPLETED';
    final int timeSpentSeconds = (args['timeSpend'] as int?) ?? 0;
    final Duration time = Duration(seconds: timeSpentSeconds);

    // 🆕 รับ Activity Object ที่ ItemIntroScreen ส่งมา
    final Activity? activityToReplay = args['activityObject'] as Activity?;

    // 🆕 รับคะแนนดิบจาก backend (scoreEarned)
    final int scoreEarned = (args['scoreEarned'] as int?) ?? 0;
    final int maxScore = activityToReplay?.maxScore ?? 100;

    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(time.inMinutes % 60), ss = two(time.inSeconds % 60);

    final Color scoreColor = totalScore >= 70 ? Palette.green : Palette.red;

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Palette.cream,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
        ),
        elevation: 0,
        title: Text(
          'RESULT',
          style: GoogleFonts.luckiestGuy(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ชื่อกิจกรรม
            Text(
              activityName.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.luckiestGuy(
                  fontSize: 22, color: Palette.deepGrey),
            ),
            const SizedBox(height: 20),

            // 2. การ์ดคะแนน (มี animation)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scoreColor, width: 3),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL SCORE',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 18, color: Palette.deepGrey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$scoreEarned / $maxScore',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 72, color: scoreColor),
                    ),
                    Text(
                      totalScore >= 70 ? 'GREAT JOB!' : 'KEEP TRYING!',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 24, color: scoreColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. เวลา
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TIME SPENT: ',
                  style: GoogleFonts.openSans(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  '$mm:$ss',
                  style: GoogleFonts.openSans(
                      fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),

            const Spacer(),

            // 4. ปุ่มต่าง ๆ
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ▶ ปุ่ม 1: เล่นกิจกรรมนี้อีกครั้ง (PLAY AGAIN)
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    // 🔥 แก้ไข: ส่ง Activity object แทน activityName
                    onPressed: activityToReplay != null
                        ? () {
                            // 🚀 นำทางกลับไป ItemIntroScreen เพื่อเริ่มข้อแรกใหม่
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.itemIntro,
                              arguments:
                                  activityToReplay, // ✅ ส่ง Activity object
                            );
                          }
                        : null, // ถ้าไม่มี activity object ให้ปุ่มถูก disable
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.bluePill,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      'PLAY AGAIN',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 📘 ปุ่ม 2: กลับไปหน้า Activities (เดิม)
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // กลับไปหน้า Activities list
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes
                            .home, // หรือ route ที่เป็นหน้า activities list
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.deepGrey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      'BACK TO ACTIVITIES',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🏠 ปุ่ม 3: กลับหน้าหลัก
                SizedBox(
                  height: 50,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.home, (route) => false),
                    child: Text(
                      'RETURN HOME',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 16, color: Palette.deepGrey),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 🎨 Palette
class Palette {
  static const cream = Color(0xFFFFF5CD);
  static const red = Color(0xFFEA5B6F);
  static const green = Color(0xFF66BB6A);
  static const greyCard = Color(0xFFEDEFF3);
  static const deepGrey = Color(0xFF5D5D5D);
  static const bluePill = Color(0xFF78BDF1);
}
