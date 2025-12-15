import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ตรวจสอบ path ของไฟล์เหล่านี้ให้ถูกต้อง
import 'manage_child_screen.dart'; 
import 'child_profile_screen.dart'; 

class ChildSettingScreen extends StatelessWidget {
  const ChildSettingScreen({super.key});

  // สี Theme
  static const cream = Color(0xFFFFF5CD);
  static const blueTitle = Color(0xFF4DA9FF);
  static const greenPlus = Color(0xFF86C178);
  static const goldStar = Color(0xFFFFC107);
  static const deepGrey = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    // ข้อมูลจำลอง (Mock Data)
    final children = [
      {'name': 'KRATON', 'img': 'https://i.pravatar.cc/150?img=1', 'points': 250},
      {'name': 'GOLF', 'img': 'https://i.pravatar.cc/150?img=8', 'points': 300},
    ];

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // --- 1. Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 30, color: Colors.black87),
                  ),
                  Text(
                    'CHILD',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 36, // ปรับขนาดให้ใหญ่ขึ้นตามแบบ
                      color: blueTitle,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Logic เพิ่มเด็กใหม่
                    },
                    child: const Icon(Icons.add, color: greenPlus, size: 40), // ปรับไอคอน + ให้เป็นตัวใหญ่
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // --- 2. Children List ---
              Expanded(
                child: ListView.separated(
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final child = children[index];
                    return _buildChildCard(
                      context,
                      name: child['name'] as String,
                      imageUrl: child['img'] as String,
                      points: child['points'] as int,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget การ์ดแสดงข้อมูลเด็ก (ปรับดีไซน์ใหม่)
  Widget _buildChildCard(BuildContext context, {
    required String name,
    required String imageUrl,
    required int points,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // ความมนของขอบการ์ด
        border: Border.all(color: Colors.black12, width: 1), // เส้นขอบจางๆ (ถ้าต้องการ)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // --- ส่วนบน: รูปโปรไฟล์ + ชื่อ + คะแนน ---
          Row(
            children: [
              // รูปโปรไฟล์
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // ชื่อ
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 24,
                    color: deepGrey,
                  ),
                ),
              ),

              // คะแนน + เหรียญ
              Row(
                children: [
                  // ใช้รูป medal.png ที่คุณอัปโหลดมา หรือใช้ Icon แทนถ้าไม่มีรูป
                  Image.asset(
                    'assets/icons/medal.png', 
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.emoji_events, color: goldStar, size: 32),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$points',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 24,
                      color: goldStar,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- ส่วนล่าง: ปุ่มกด 2 ปุ่ม ---
          Row(
            children: [
              // ปุ่ม VIEW PROFILE
              Expanded(
                child: _buildActionButton(
                  title: 'VIEW PROFILE',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChildProfileScreen(
                          name: name,
                          imageUrl: imageUrl,
                          points: points,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12), // ระยะห่างระหว่างปุ่ม
              // ปุ่ม MANAGE
              Expanded(
                child: _buildActionButton(
                  title: 'MANAGE',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageChildScreen(
                          name: name,
                          imageUrl: imageUrl,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget สร้างปุ่ม (ปรับให้ใหญ่และมีขอบชัดเจน)
  Widget _buildActionButton({required String title, required VoidCallback onTap}) {
    return SizedBox(
      height: 48, // ความสูงปุ่ม
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.black87, width: 2), // ขอบหนา 2
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: Colors.black87, // สีเวลาแตะ
        ),
        child: Text(
          title,
          style: GoogleFonts.luckiestGuy(
            fontSize: 14, // ปรับขนาดตัวหนังสือ
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}