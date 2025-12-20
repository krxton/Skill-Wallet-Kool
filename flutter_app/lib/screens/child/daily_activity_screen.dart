import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'playing_result_detail_screen.dart'; // 🔗 เชื่อมไปหน้าระดับที่ 3

class DailyActivityScreen extends StatelessWidget {
  final String date;

  const DailyActivityScreen({super.key, required this.date});

  static const cream = Color(0xFFFFF5CD);
  static const skyBlue = Color(0xFF5AB2FF);
  static const itemBlue = Color(0xFF90CAF9);
  static const numberPink = Color(0xFFFF8A80);

  @override
  Widget build(BuildContext context) {
    // Mock Data: รายการเล่นในวันนั้น (สมมติว่าเล่น 4 ครั้ง)
    final sessions = [
      {'id': 1, 'time': '09:00 AM', 'medals': 5},
      {'id': 2, 'time': '11:30 AM', 'medals': 3},
      {'id': 3, 'time': '02:15 PM', 'medals': 6},
      {'id': 4, 'time': '04:45 PM', 'medals': 4},
    ];

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 35, color: Colors.black87),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      date, // แสดงวันที่ที่เลือกมา
                      style: GoogleFonts.luckiestGuy(fontSize: 26, color: skyBlue),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'PLAYING HISTORY',
              style: GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // List of Times (Time 1, Time 2...)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return GestureDetector(
                    onTap: () {
                      // 👉 กดแล้วไปดูรายละเอียด (หน้า Result Detail)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayingResultDetailScreen(
                            sessionNumber: session['id'] as int,
                            date: date,
                            medals: session['medals'] as int,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          // วงกลมตัวเลข (1, 2, 3, 4)
                          Container(
                            width: 50, height: 50,
                            decoration: const BoxDecoration(
                              color: numberPink,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${session['id']}',
                              style: GoogleFonts.luckiestGuy(fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 15),
                          
                          // กล่องรายละเอียดเวลา
                          Expanded(
                            child: Container(
                              height: 60,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: itemBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${session['time']}',
                                    style: GoogleFonts.luckiestGuy(fontSize: 18, color: Colors.white),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.emoji_events, color: Colors.yellow, size: 24),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${session['medals']}',
                                        style: GoogleFonts.luckiestGuy(fontSize: 18, color: Colors.white),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}