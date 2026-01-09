// lib/screens/activities/hub/answer_plus_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnswerPlusPage extends StatelessWidget {
  const AnswerPlusPage({super.key});

  // 🎨 สีตาม Theme
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const orangeItem = Color(0xFFEF9C66);

  @override
  Widget build(BuildContext context) {
    // 📝 ข้อมูลสมมุติ (Mock Data) พร้อมคำตอบ
    final List<Map<String, String>> answers = [
      {'q': '1. 2 + 4 = ?', 'a': '6'},
      {'q': '2. 5 + ? = 12', 'a': '7'},
      {'q': '3. 2 + 4 = ?', 'a': '6'},
      {'q': '4. 5 + ? = 12', 'a': '7'},
      {'q': '5. 2 + 4 = ?', 'a': '6'},
      {'q': '6. 5 + ? = 12', 'a': '7'},
      {'q': '7. 2 + 4 = ?', 'a': '6'},
      {'q': '8. 5 + ? = 12', 'a': '7'},
      {'q': '9. 2 + 4 = ?', 'a': '6'},
      {'q': '10. 5 + ? = 12', 'a': '7'},
    ];

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
          'ANSWER PLUS +', // ชื่อหัวข้อเปลี่ยนเป็น ANSWER PLUS +
          style: GoogleFonts.luckiestGuy(
            fontSize: 28,
            color: sky,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          // หัวข้อตาราง (QUESTION --- ANSWER)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'QUESTION',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 22,
                    color: const Color(0xFF8ECDF7),
                  ),
                ),
                Text(
                  'ANSWER',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 22,
                    color: const Color(0xFF8ECDF7),
                  ),
                ),
              ],
            ),
          ),

          // รายการเฉลย
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: answers.length,
              itemBuilder: (context, index) {
                final item = answers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: orangeItem,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ส่วนโจทย์
                      Text(
                        item['q']!,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      // ส่วนคำตอบ
                      Text(
                        item['a']!,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20), // เว้นระยะด้านล่างเล็กน้อย
        ],
      ),
    );
  }
}
