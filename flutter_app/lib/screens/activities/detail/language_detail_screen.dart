// lib/screens/language_detail_screen.dart

// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';

class LanguageDetailScreen extends StatelessWidget {
  static const String routeName = '/language_detail';

  // 🎨 สีที่ใช้ในหน้านี้
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const deepGrey = Color(0xFF5D5D5D);

  final Activity activity;

  const LanguageDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    // 🆕 ดึงข้อมูลที่เกี่ยวข้องกับภาษาออกมา
    final String name = activity.name;
    final String description =
        activity.description ?? 'No description provided.';
    final String content = activity.content; // มักจะเป็นคำแนะนำ/เนื้อหาหลัก

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        // 🆕 แสดงชื่อกิจกรรม (ย้าย Logic จาก title ภายใน Build ไปที่ AppBar)
        title: Text(
            'LANGUAGE: ${activity.name.toUpperCase()}', // 🆕 ใช้ activity.name.toUpperCase()
            style: GoogleFonts.luckiestGuy(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. หัวข้อหลัก (Category)
            Text(
              'CATEGORY: ${activity.category.toUpperCase()}',
              style: GoogleFonts.luckiestGuy(fontSize: 22, color: sky),
            ),

            const SizedBox(height: 16),

            // 2. 🆕 แสดง Name (ชื่อกิจกรรม) แทน Description ใน Card แรก
            _buildSectionTitle('ACTIVITY TITLE'), // 🆕 หัวข้อใหม่
            _buildContentCard(name), // 🆕 ใช้ name

            const SizedBox(height: 20),

            // 3. 🆕 แสดง Description ใน Card ที่สอง
            _buildSectionTitle('DESCRIPTION'), // 🆕 หัวข้อใหม่
            _buildContentCard(description), // 🆕 ใช้ description

            const SizedBox(height: 30),

            // 4. ข้อมูลเสริม (Difficulty, Max Score)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildInfoPill('Difficulty: ${activity.difficulty}', sky),
                const SizedBox(width: 12),
                _buildInfoPill('Max Score: ${activity.maxScore}', Colors.green),
              ],
            ),

            const SizedBox(height: 30),

            // 5. ปุ่มเริ่มกิจกรรม (Start)
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.itemIntro,
                  arguments: activity,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: sky,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'START',
                style:
                    GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper Methods (เพิ่ม _buildInfoPill)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.luckiestGuy(fontSize: 18, color: deepGrey),
      ),
    );
  }

  Widget _buildContentCard(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sky, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.openSans(fontSize: 15, color: Colors.black),
      ),
    );
  }

  Widget _buildInfoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.openSans(
            fontSize: 14, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
