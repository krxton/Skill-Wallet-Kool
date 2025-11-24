// lib/screens/video_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
import '../routes/app_routes.dart';

class VideoDetailScreen extends StatelessWidget {
  static const String routeName = '/video_detail';

  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const deepGrey = Color(0xFF5D5D5D);

  final Activity activity;

  const VideoDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final String htmlContent = activity.tiktokHtmlContent ?? '';
    final String name = activity.name;
    final String description =
        activity.description ?? 'No description provided.';
    final String content = activity.content;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          name,
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
            SizedBox(
              height: 300,
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
                style:
                    GoogleFonts.openSans(fontSize: 15, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
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
                style:
                    GoogleFonts.openSans(fontSize: 15, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoPill('Category: ${activity.category}', sky),
                _buildInfoPill('Difficulty: ${activity.difficulty}', sky),
                _buildInfoPill(
                    'Max Score: ${activity.maxScore}', Colors.green),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.physicalActivity,
                        arguments: activity,
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
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
