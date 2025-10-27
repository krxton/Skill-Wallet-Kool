// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // สีหลักให้โทนเดียวกับแอป
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);

  // ค่า dropdown ปัจจุบัน
  String _categoryValue = 'CATEGORY';

  // เรียกเมื่อเปลี่ยนค่า Category
  void _onCategoryChanged(String? value) {
    if (value == null) return;

    // อัปเดต UI ก่อน
    setState(() => _categoryValue = value);

    // ถ้าเลือก Language → ไป LanguageHubScreen
    if (value.toUpperCase() == 'LANGUAGE') {
      // รีเซ็ตกลับเป็น "CATEGORY" ตอนกลับมา
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, AppRoutes.languageHub).then((_) {
          if (mounted) {
            setState(() => _categoryValue = 'CATEGORY');
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        centerTitle: true,
        elevation: 0,
      
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // แถบค้นหา (ตกแต่งให้ดูนุ่ม ๆ)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFD4E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.black87),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('search...',
                      style: GoogleFonts.luckiestGuy(
                          color: Colors.black54, fontSize: 14)),
                ),
                const Icon(Icons.search, color: Colors.black87),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // หัวข้อ SWK
          Text('SWK',
              style:
                  GoogleFonts.luckiestGuy(fontSize: 26, color: sky)),

          const SizedBox(height: 10),

          // ปุ่ม Category (Dropdown) — เลือก LANGUAGE แล้วนำทาง
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF9BD0FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: sky, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _categoryValue,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: GoogleFonts.luckiestGuy(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  dropdownColor: Colors.white,
                  onChanged: _onCategoryChanged,
                  items: const [
                    'CATEGORY',
                    'LANGUAGE',
                    'MATH',
                    'PHYSICAL',
                  ].map((e) {
                    return DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: GoogleFonts.luckiestGuy(
                          color: e == 'CATEGORY' ? Colors.white : Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // การ์ด CLIP VDO (placeholder)
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: sky, width: 3),
            ),
            alignment: Alignment.center,
            child: Text('CLIP VDO',
                style: GoogleFonts.luckiestGuy(
                    fontSize: 28, color: Colors.black87)),
          ),

          const SizedBox(height: 22),

          // หัวข้อ Popular Activities
          Text('POPULAR ACTIVITIES',
              style: GoogleFonts.luckiestGuy(
                  fontSize: 22, color: const Color(0xFF7DBEF1))),

          const SizedBox(height: 12),

          // แถวการ์ดย่อย (placeholder)
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(
                  child: Container(
                    height: 82,
                    margin: EdgeInsets.only(right: i == 2 ? 0 : 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text('CLIP',
                        style: GoogleFonts.luckiestGuy(fontSize: 16)),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 28),

          // NEW
          Text('NEW',
              style: GoogleFonts.luckiestGuy(
                  fontSize: 22, color: const Color(0xFF0D92F4))),
          const SizedBox(height: 12),

          // การ์ดใหม่ (placeholder)
          Container(
            height: 82,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 90), // เว้นพื้นที่ให้พ้น bottom bar ถ้ามี
        ],
      ),

      // แถบล่าง (ไอคอน 3 อัน — placeholder)
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFF06277),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _BottomIcon(bg: Color(0xFFFFD33D), icon: Icons.home),
            _BottomIcon(bg: Color(0xFFE57373), icon: Icons.add),
            _BottomIcon(bg: Color(0xFFFFD33D), icon: Icons.person),
          ],
        ),
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final Color bg;
  final IconData icon;
  const _BottomIcon({required this.bg, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white),
    );
  }
}
