// lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/palette.dart';
import '../../../routes/app_routes.dart';
import '../../../models/activity.dart';
import '../../../widgets/share_result_helper.dart';

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
        (args['activityName'] as String?) ?? AppLocalizations.of(context)!.result_activityCompletedDefault;
    final int timeSpentSeconds = (args['timeSpend'] as int?) ?? 0;
    final Duration time = Duration(seconds: timeSpentSeconds);

    // 🆕 รับ Activity Object ที่ ItemIntroScreen ส่งมา
    final Activity? activityToReplay = args['activityObject'] as Activity?;

    // 🆕 รับคะแนนดิบจาก backend (scoreEarned)
    final int scoreEarned = (args['scoreEarned'] as int?) ?? 0;
    final int maxScore = activityToReplay?.maxScore ?? 100;

    // รับ evidence image path (จากกิจกรรมร่างกาย/คำนวณ)
    final String? evidenceImagePath = args['evidenceImagePath'] as String?;

    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(time.inMinutes % 60), ss = two(time.inSeconds % 60);

    final Color scoreColor = totalScore >= 70 ? Palette.successAlt : Palette.pink;

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
          AppLocalizations.of(context)!.result_resultTitle,
          style: GoogleFonts.luckiestGuy(color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Palette.sky),
            onPressed: () {
              showShareBottomSheet(
                context,
                ShareResultData(
                  activityName: activityName,
                  score: scoreEarned,
                  maxScore: maxScore,
                  timeSpentSeconds: timeSpentSeconds,
                  category: activityToReplay?.category,
                  evidenceImagePath: evidenceImagePath,
                ),
              );
            },
          ),
        ],
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
                      AppLocalizations.of(context)!.result_totalScoreTitle,
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
                      totalScore >= 70 ? AppLocalizations.of(context)!.result_greatJobTitle : AppLocalizations.of(context)!.result_keepTryingTitle,
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
                  AppLocalizations.of(context)!.result_timeSpentPrefix,
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
                    onPressed: activityToReplay != null
                        ? () {
                            // 🚀 นำทางไปหน้าที่เหมาะสมตาม category
                            final category = activityToReplay.category.toUpperCase();

                            if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.itemIntro,
                                arguments: activityToReplay,
                              );
                            } else if (category == 'ด้านร่างกาย' && activityToReplay.videoUrl != null) {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.videoDetail,
                                arguments: activityToReplay,
                              );
                            } else if (category == 'ด้านคำนวณ') {
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.calculateActivity,
                                arguments: activityToReplay,
                              );
                            } else {
                              // Fallback: กลับไป itemIntro
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.itemIntro,
                                arguments: activityToReplay,
                              );
                            }
                          }
                        : null, // ถ้าไม่มี activity object ให้ปุ่มถูก disable
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.bluePill,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.result_playAgainBtn,
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
                      AppLocalizations.of(context)!.result_backToActivitiesBtn,
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
