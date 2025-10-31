// lib/screens/video_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart'; // 🆕 ต้อง Import Activity Model

class VideoDetailScreen extends StatelessWidget {
  static const String routeName = '/video_detail';

  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const deepGrey = Color(0xFF5D5D5D);

  // 🆕 รับ Activity Object ที่สมบูรณ์
  final Activity activity;

  const VideoDetailScreen({
    super.key,
    required this.activity, // 🆕 เปลี่ยนมาใช้ Activity Object
  });

  @override
  Widget build(BuildContext context) {
    // 🆕 ดึงข้อมูลจาก Activity Object
    final String htmlContent = activity.tiktokHtmlContent ?? '';
    final String name = activity.name;
    final String description =
        activity.description ?? 'No description provided.';
    final String content = activity.content; // 'วิธีเล่น'

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        // 🆕 แสดงชื่อกิจกรรม
        title: Text(name, style: GoogleFonts.luckiestGuy(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ส่วนแสดงวิดีโอ TikTok
            SizedBox(
              height: 450, // กำหนดความสูงเพื่อให้วิดีโอแสดงผลได้ดี
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: htmlContent.isNotEmpty
                    ? InAppWebView(
                        initialData: InAppWebViewInitialData(
                          data: htmlContent,
                          mimeType: 'text/html',
                          encoding: 'utf-8',
                        ),
                        initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true,
                          transparentBackground: true,
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                        ),
                      )
                    : Container(
                        color: deepGrey,
                        alignment: Alignment.center,
                        child: Text(
                          'Video Not Available (HTML Content Missing)',
                          style: GoogleFonts.luckiestGuy(color: Colors.white),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. รายละเอียดกิจกรรม (Description)
            Text(
              'DESCRIPTION:',
              style: GoogleFonts.luckiestGuy(fontSize: 18, color: sky),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.openSans(fontSize: 14, color: deepGrey),
            ),

            const SizedBox(height: 20),

            // 3. วิธีเล่น (Content)
            Text(
              'HOW TO PLAY / INSTRUCTIONS:',
              style: GoogleFonts.luckiestGuy(fontSize: 18, color: sky),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sky, width: 1),
              ),
              child: Text(
                content,
                style: GoogleFonts.openSans(fontSize: 15, color: Colors.black),
              ),
            ),

            const SizedBox(height: 30),

            // 4. ข้อมูลเพิ่มเติม (Category, Difficulty, Max Score)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoPill('Category: ${activity.category}', sky),
                _buildInfoPill('Difficulty: ${activity.difficulty}', sky),
                _buildInfoPill('Max Score: ${activity.maxScore}', Colors.green),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.openSans(
            fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
