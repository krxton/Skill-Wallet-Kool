// lib/screens/language_detail_screen.dart (ฉบับแก้ไข)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
// 🆕 เพิ่มการนำเข้า AppRoutes
import '../routes/app_routes.dart';

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
        title: Text(
          'LANGUAGE: $name',
          style: GoogleFonts.luckiestGuy(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. หัวข้อหลัก
            Text(
              'ACTIVITY: ${activity.category}',
              style: GoogleFonts.luckiestGuy(fontSize: 22, color: sky),
            ),

            const SizedBox(height: 16),

            // 2. คำอธิบาย
            _buildSectionTitle('DESCRIPTION'),
            _buildContentCard(description),

            const SizedBox(height: 20),

            // 3. เนื้อหา/คำแนะนำ
            _buildSectionTitle('ACTIVITY INSTRUCTIONS / CONTENT'),
            _buildContentCard(content),

            const SizedBox(height: 30),

            // 4. ปุ่มเริ่มกิจกรรม (Start)
            ElevatedButton(
              onPressed: () {
                // 🚀 ACTION: นำทางไปยัง ItemIntroScreen เพื่อเริ่มกิจกรรมจริง
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
                'START LEVEL (${activity.difficulty.toUpperCase()})',
                style:
                    GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper Methods
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
}
