import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../routes/app_routes.dart';

class ProblemPlayingPage extends StatefulWidget {
  const ProblemPlayingPage({super.key});

  @override
  State<ProblemPlayingPage> createState() => _ProblemPlayingPageState();
}

class _ProblemPlayingPageState extends State<ProblemPlayingPage> {
  // 🎨 สีตาม Theme
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const blueBtn = Color(0xFFA2D2FF);
  static const greenBtn = Color(0xFF88C273);
  static const redText = Color(0xFFFF8A8A); // สีหัวข้อ Diary/Image
  static const yellowBadge = Color(0xFFFFD93D); // สีป้ายชื่อ

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
          'PROBLEMS SOLVE',
          style: GoogleFonts.luckiestGuy(
            fontSize: 26,
            color: sky,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: yellowBadge,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'), // รูปสมมุติ
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KRATON',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 18,
                          color: Colors.black,
                        ),
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
                    backgroundColor: blueBtn,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'ANSWER',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'PLAYING RESULTS',
              style: GoogleFonts.luckiestGuy(
                fontSize: 20,
                color: Colors.black54,
              ),
            ),
            
            const SizedBox(height: 10),

            // Medals Section
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.orange, size: 30),
                const SizedBox(width: 8),
                Text(
                  'MEDALS',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 20,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                // ตัวปรับลดเพิ่มเหรียญ
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() { if(medals > 0) medals--; }),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$medals',
                        style: GoogleFonts.luckiestGuy(fontSize: 20),
                      ),
                      IconButton(
                        onPressed: () => setState(() { medals++; }),
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
              'DIARY',
              style: GoogleFonts.luckiestGuy(fontSize: 20, color: redText),
            ),
            const SizedBox(height: 5),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                maxLines: null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Write something...',
                ),
              ),
            ),

            const SizedBox(height: 15),

            // IMAGE Input
            Text(
              'IMAGE',
              style: GoogleFonts.luckiestGuy(fontSize: 20, color: redText),
            ),
            const SizedBox(height: 5),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
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
                    'TIME',
                    style: GoogleFonts.luckiestGuy(fontSize: 20, color: redText),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      _formatTime(_seconds),
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 24,
                        color: sky,
                      ),
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
                      backgroundColor: greenBtn,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'FINISH',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 20,
                        color: Colors.white,
                      ),
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