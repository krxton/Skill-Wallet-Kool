import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart'; // 🆕 ต้อง Import Activity Model
import '../routes/app_routes.dart';

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
        title: Text(
          name,
          style: GoogleFonts.luckiestGuy(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      //ส่วนที่ทำให้สามารถเลื่อนหน้าจอได้จะได้ไม่overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ส่วนแสดงวิดีโอ TikTok
            SizedBox(
              height: 300, // กำหนดความสูงเพื่อให้วิดีโอแสดงผลได้ดี
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

            // 2. ชื่อกิจกรรม (Title Block)
            Text(
              'ACTIVITY NAME:',
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
                name,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 20,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // 3. รายละเอียดกิจกรรม (Description)
            Text(
              'DESCRIPTION:',
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
                description,
                style: GoogleFonts.openSans(fontSize: 15, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),

            // 4. วิธีเล่น (Content)
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

            const SizedBox(height: 20),

            // 5. ข้อมูลเพิ่มเติม (Category, Difficulty, Max Score)
            // 🔧 แก้ OVERFLOW: ใช้ Wrap แทน Row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoPill('Category: ${activity.category}', sky),
                _buildInfoPill('Difficulty: ${activity.difficulty}', sky),
                _buildInfoPill('Max Score: ${activity.maxScore}', Colors.green),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                // 1. ปุ่ม START
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 🚀 ACTION: นำทางไปยัง PhysicalActivityScreen
                      Navigator.pushNamed(
                        context,
                        AppRoutes.physicalActivity,
                        arguments: activity, // 🆕 ส่ง Activity Object ไป
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      'START',
                      style: GoogleFonts.luckiestGuy(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sky,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. ปุ่ม ADD (ปล่อยว่างไว้ก่อน)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement Add to Diary/Favorite Logic
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      'ADD',
                      style: GoogleFonts.luckiestGuy(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: deepGrey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
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
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
