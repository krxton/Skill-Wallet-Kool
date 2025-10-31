// lib/screens/video_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoDetailScreen extends StatelessWidget {
  static const String routeName = '/video_detail'; // ชื่อ Route

  // สีพื้นหลัง
  static const cream = Color(0xFFFFF5CD);

  // ข้อมูลที่จะรับมาจากหน้า HomeScreen
  final String htmlContent;
  final String title;

  const VideoDetailScreen({
    super.key,
    required this.htmlContent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.luckiestGuy(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // สีปุ่ม Back
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ส่วนที่แสดงวิดีโอ TikTok
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InAppWebView(
                  initialData: InAppWebViewInitialData(
                    data: htmlContent,
                    mimeType: 'text/html',
                    encoding: 'utf-8',
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: true,
                    mediaPlaybackRequiresUserGesture:
                        false, // 🆕 อาจช่วยให้เล่นอัตโนมัติ
                    allowsInlineMediaPlayback: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // รายละเอียดอื่นๆ หรือปุ่ม
            Text(
              'Enjoy this physical activity clip!',
              style:
                  GoogleFonts.luckiestGuy(fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            // คุณสามารถเพิ่มรายละเอียดเพิ่มเติมได้ที่นี่
          ],
        ),
      ),
    );
  }
}
