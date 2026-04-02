import 'dart:async';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

class ProblemPlayingScreen extends StatefulWidget {
  const ProblemPlayingScreen({super.key});

  @override
  State<ProblemPlayingScreen> createState() => _ProblemPlayingScreenState();
}

class _ProblemPlayingScreenState extends State<ProblemPlayingScreen> {
  // Logic ตัวแปร
  int medals = 0;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // รับ arguments เดิมมา เพื่อส่งต่อให้หน้า Answer ถ้ากดปุ่ม Answer ในหน้านี้
    final args = ModalRoute.of(context)?.settings.arguments;

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
          style: AppTextStyles.heading(26, color: Palette.sky).copyWith(
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วน Profile และปุ่ม Answer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Palette.yellow,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=12'), // รูปสมมุติ
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KRATON',
                        style: AppTextStyles.heading(18, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                // ปุ่ม ANSWER
                ElevatedButton(
                  onPressed: () {
                    // กดแล้วไปหน้าเฉลย
                    Navigator.pushNamed(
                      context,
                      AppRoutes.problemAnswer,
                      arguments: args,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.problemplaying_answerBtn,
                    style: AppTextStyles.heading(16, color: Palette.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              AppLocalizations.of(context)!.problemplaying_resultsTitle,
              style: AppTextStyles.heading(20, color: Colors.black54),
            ),

            const SizedBox(height: 10),

            // Medals Section
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.orange, size: 30),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.problemplaying_medalsLabel,
                  style: AppTextStyles.heading(20, color: Colors.orange),
                ),
                const Spacer(),
                // ตัวปรับลดเพิ่มเหรียญ
                Container(
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() {
                          if (medals > 0) medals--;
                        }),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$medals',
                        style: AppTextStyles.heading(20),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          medals++;
                        }),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 15),

            // DIARY Input
            Text(
              AppLocalizations.of(context)!.problemplaying_diaryLabel,
              style: AppTextStyles.heading(20, color: Palette.error),
            ),
            const SizedBox(height: 5),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                maxLines: null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  hintText:
                      AppLocalizations.of(context)!.problemplaying_diaryHint,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // IMAGE Input
            Text(
              AppLocalizations.of(context)!.problemplaying_imageLabel,
              style: AppTextStyles.heading(20, color: Palette.error),
            ),
            const SizedBox(height: 5),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () {
                  // TODO: Image Picker Logic
                },
                icon: const Icon(Icons.add, size: 40, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 15),

            // TIME Display
            Center(
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.problemplaying_timeLabel,
                    style: AppTextStyles.heading(20, color: Palette.error),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
                    decoration: BoxDecoration(
                      color: Palette.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _formatTime(_seconds),
                      style: AppTextStyles.heading(24, color: Palette.sky),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Finish Button & Refresh
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Save Result Logic
                      Navigator.pop(context); // กลับหน้าเดิม
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.success,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.problemplaying_finishBtn,
                      style: AppTextStyles.heading(20, color: Palette.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 2),
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _seconds = 0; // Reset Time
                      });
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
