import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../routes/app_routes.dart';
import '../../../theme/palette.dart';

class PlusScreen extends StatelessWidget {
  const PlusScreen({super.key});

  // 🎨 สีตาม Theme
  static const orangeItem = Color(0xFFEF9C66); // สีพื้นหลังโจทย์
  static const greenBtn = Color(0xFF88C273); // สีปุ่ม Start
  static const purpleBtn = Color(0xFFCD9EFF); // สีปุ่ม Cast
  static const blueBtn = Color(0xFFA2D2FF); // สีปุ่ม Answer

  @override
  Widget build(BuildContext context) {
    // 📝 ข้อมูลสมมุติ (Mock Data)
    final List<String> questions = [
      "1. 2 + 4 = ?",
      "2. 5 + ? = 12",
      "3. 2 + 4 = ?",
      "4. 5 + ? = 12",
      "5. 2 + 4 = ?",
      "6. 5 + ? = 12",
      "7. 2 + 4 = ?",
      "8. 5 + ? = 12",
      "9. 2 + 4 = ?",
      "10. 5 + ? = 12",
    ];

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
          'PLUS +',
          style: GoogleFonts.luckiestGuy(
            fontSize: 32,
            color: Palette.sky,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          // หัวข้อ QUESTION
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'QUESTION',
              style: GoogleFonts.luckiestGuy(
                fontSize: 24,
                color: const Color(0xFF8ECDF7), // สีฟ้าอ่อนตามรูป
              ),
            ),
          ),

          // รายการโจทย์ (Scrollable)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: orangeItem,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    questions[index],
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),

          // ส่วนปุ่มด้านล่าง (Start, Cast, Answer)
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    // ปุ่ม START
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: ใส่ Logic เริ่มเกมตรงนี้
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenBtn,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'START',
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
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: ใส่ Logic Cast ขึ้นจอตรงนี้
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purpleBtn,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'CAST TO TV',
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

                // ปุ่ม ANSWER (เชื่อม Route ไปหน้าเฉลยแล้ว)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.answerPlus);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueBtn,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'ANSWER',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
