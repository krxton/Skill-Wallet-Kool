import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Import Provider
import '../../../providers/user_provider.dart';

// Import หน้าย่อยต่างๆ
import 'profile_setting_screen.dart';       // หน้าแก้ไขโปรไฟล์
import 'notification_setting_screen.dart';  // หน้าตั้งค่าการแจ้งเตือน
import '../../child/child_setting_screen.dart';         // หน้าจัดการเด็ก (เพิ่มใหม่)

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  // สี Theme ตามดีไซน์
  static const cream = Color(0xFFFFF5CD);
  static const pinkRed = Color(0xFFFF8E8E);
  static const blueTitle = Color(0xFF4DA9FF);
  static const textGrey = Color(0xFF8E8E8E);

  @override
  Widget build(BuildContext context) {
    // ดึงรูปโปรไฟล์จาก Provider มาแสดง (เพื่อให้ตรงกับหน้า Profile หลัก)
    final profileImageBytes = context.watch<UserProvider>().profileImageBytes;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. Header (Back & Title) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back, size: 28, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text(
                          'BACK',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 24,
                            color: pinkRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'SETTING',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 24,
                      color: blueTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- 2. Menu: PROFILE ---
              // (ลิงก์ไปหน้า ProfileSettingScreen)
              _buildMenuItem(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileSettingScreen(),
                    ),
                  );
                },
                title: 'PROFILE',
                // ส่วนแสดงรูป Thumbnail วงกลม
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: profileImageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(profileImageBytes),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profileImageBytes == null
                      ? const Icon(Icons.person, size: 30, color: Colors.black87)
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // --- Section: Personal Information ---
              Text(
                'PERSONAL INFORMATION',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 10),
              
              const SizedBox(height: 10),
              
              // Menu: CHILD (ลิงก์ไปหน้า ChildSettingScreen)
              _buildMenuItem(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChildSettingScreen(),
                    ),
                  );
                },
                title: 'CHILD',
                leading: const Icon(Icons.sentiment_satisfied_alt, size: 32, color: Colors.black87),
              ),

              const SizedBox(height: 20),

              // --- Section: General ---
              Text(
                'GENERAL',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 10),
              
              // Menu: NOTIFICATIONS (ลิงก์ไปหน้า NotificationSettingScreen)
              _buildMenuItem(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingScreen(),
                    ),
                  );
                },
                title: 'NOTIFICATIONS',
                leading: const Icon(Icons.notifications_outlined, size: 32, color: Colors.black87),
              ),

              const Spacer(), // ดันปุ่ม Logout ไปล่างสุด

              // --- 3. Log Out Button ---
              GestureDetector(
                onTap: () {
                  // เรียกฟังก์ชัน clearUserData ใน Provider
                  context.read<UserProvider>().clearUserData();
                  // ออกจากหน้า Setting
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LOG OUT',
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 24,
                        color: pinkRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.logout, color: Colors.black87, size: 28),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget สำหรับสร้างแถวเมนู
  Widget _buildMenuItem({
    required String title,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // เพื่อให้พื้นที่ว่างกดได้
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 32, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}