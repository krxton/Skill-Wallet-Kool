import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'daily_activity_screen.dart'; // 🔗 เชื่อมไปหน้าระดับที่ 2

class ActivityHistoryScreen extends StatelessWidget {
  final String gameName;

  const ActivityHistoryScreen({super.key, required this.gameName});

  static const cream = Color(0xFFFFF5CD);
  static const skyBlue = Color(0xFF5AB2FF);
  static const cardBlue = Color(0xFF90CAF9);
  static const pinkNum = Color(0xFFFF8A80);

  @override
  Widget build(BuildContext context) {
    // Mock Data: รายชื่อวันที่ที่มีการเล่น
    final dates = [
      {'date': '24 JULY 2025', 'count': 4}, // เล่นไป 4 ครั้ง
      {'date': '25 JULY 2025', 'count': 2},
      {'date': '28 JULY 2025', 'count': 1},
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
                    child: const Icon(Icons.arrow_back,
                        size: 35, color: Colors.black87),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      gameName,
                      style:
                          GoogleFonts.luckiestGuy(fontSize: 26, color: skyBlue),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'SELECT DATE',
              style: GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Date List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final item = dates[index];
                  return GestureDetector(
                    onTap: () {
                      // 👉 กดวันที่แล้วไปหน้า DailyActivityScreen (ระดับ 2)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyActivityScreen(
                            date: item['date'] as String,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: pinkNum),
                              const SizedBox(width: 15),
                              Text(
                                '${item['date']}',
                                style: GoogleFonts.luckiestGuy(
                                    fontSize: 22, color: Colors.black87),
                              ),
                            ],
                          ),
                          // Badge บอกจำนวนครั้งที่เล่น
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cardBlue,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '${item['count']} TIMES',
                              style: GoogleFonts.luckiestGuy(
                                  fontSize: 14, color: Colors.white),
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
