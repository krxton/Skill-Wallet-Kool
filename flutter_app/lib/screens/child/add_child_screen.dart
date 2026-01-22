import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  // 1. สร้าง Controller เพื่อดึงข้อความจากช่องกรอก
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDayController = TextEditingController();

  // 🎨 สีตาม Theme
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF5AB2FF);
  static const orangeInput = Color(0xFFFFCC80);
  static const greenBtn = Color(0xFF88C273);

  @override
  Widget build(BuildContext context) {
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
          AppLocalizations.of(context)!.register_registerBtn,
          style: TextStyle(
            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
            fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
            fontSize: 28,
            color: sky,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                AppLocalizations.of(context)!.register_additionalBtn,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 20,
                  color: sky,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Name Input ---
            Text(
              AppLocalizations.of(context)!.addchild_namesurnameBtn,
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                fontSize: 16,
                color: const Color(0xFFFF8A80),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: orangeInput,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _nameController, // เชื่อม Controller
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Birthday Input ---
            Text(
              AppLocalizations.of(context)!.addchild_birthdayBtn,
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                fontSize: 16,
                color: const Color(0xFFFF8A80),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: orangeInput,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _birthDayController, // เชื่อม Controller
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // --- OK Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // 2. Logic ส่งข้อมูลกลับ
                  String name = _nameController.text;
                  if (name.isNotEmpty) {
                    // สร้าง Map ข้อมูลเด็กใหม่
                    Map<String, dynamic> newChild = {
                      'name': name,
                      'score': 0, // คะแนนเริ่มต้น 0
                      'img':
                          'https://i.pravatar.cc/150?img=12', // รูป Default สุ่มๆ
                    };

                    // ส่งข้อมูลกลับไปหน้าก่อนหน้า (Pop with Result)
                    Navigator.pop(context, newChild);
                  } else {
                    // แจ้งเตือนถ้าไม่ได้กรอกชื่อ
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.addchild_errorName,
                          style: TextStyle(
                            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                            fontFamilyFallback: [
                              GoogleFonts.itim().fontFamily!
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenBtn,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context)!.addchild_okBtn,
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
