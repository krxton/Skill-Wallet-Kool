import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../routes/app_routes.dart';
import '../providers/user_provider.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
  });

  final Activity activity;

  static const deepSky = Color(0xFF7DBEF1);
  static const sky = Color(0xFF5AB2FF);

  @override
  Widget build(BuildContext context) {
    final category = activity.category.toUpperCase();
    final thaiFallback = [GoogleFonts.itim().fontFamily!];

    final bool hasTikTokOEmbedData = category == 'ด้านร่างกาย' &&
        activity.videoUrl != null &&
        activity.tiktokHtmlContent != null &&
        activity.thumbnailUrl != null;

    final bool hasYouTubeVideo =
        (category == 'ด้านภาษา' || category == 'LANGUAGE') &&
            activity.videoUrl != null &&
            activity.videoUrl!.contains('youtube');

    String? youtubeThumbnailUrl;
    if (hasYouTubeVideo) {
      final videoId = _extractYouTubeVideoId(activity.videoUrl!);
      if (videoId != null) {
        youtubeThumbnailUrl =
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }

    final bool shouldGoToVideoDetail =
        category == 'ด้านร่างกาย' && activity.videoUrl != null;

    void showSelectChildDialog() {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                'กรุณาเลือกเด็ก',
                style: TextStyle(
                  fontFamily: GoogleFonts.itim().fontFamily,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'คุณต้องเลือกเด็กก่อนจึงจะสามารถเล่นกิจกรรมได้',
            style: TextStyle(
              fontFamily: GoogleFonts.itim().fontFamily,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'ปิด',
                style: TextStyle(
                  fontFamily: GoogleFonts.itim().fontFamily,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamed(context, AppRoutes.childSetting);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: sky,
              ),
              child: Text(
                'ไปเลือกเด็ก',
                style: TextStyle(
                  fontFamily: GoogleFonts.itim().fontFamily,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    void navigate() {
      // ✅ ตรวจสอบว่าเลือกเด็กแล้วหรือยัง
      final userProvider = context.read<UserProvider>();
      if (userProvider.currentChildId == null) {
        showSelectChildDialog();
        return;
      }

      if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
        Navigator.pushNamed(
          context,
          AppRoutes.languageDetail,
          arguments: activity,
        );
      } else if (shouldGoToVideoDetail) {
        Navigator.pushNamed(
          context,
          AppRoutes.videoDetail,
          arguments: activity,
        );
      } else if (category == 'ด้านวิเคราะห์') {
        Navigator.pushNamed(
          context,
          AppRoutes.analysisActivity,
          arguments: activity,
        );
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.itemIntro,
          arguments: activity,
        );
      }
    }

    return GestureDetector(
      onTap: navigate,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildThumbnail(
                hasTikTokOEmbedData: hasTikTokOEmbedData,
                hasYouTubeVideo: hasYouTubeVideo,
                youtubeThumbnailUrl: youtubeThumbnailUrl,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 14,
                      color: Colors.black,
                    ).copyWith(fontFamilyFallback: thaiFallback),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Score: ${activity.maxScore}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail({
    required bool hasTikTokOEmbedData,
    required bool hasYouTubeVideo,
    String? youtubeThumbnailUrl,
  }) {
    if (hasTikTokOEmbedData && activity.thumbnailUrl != null) {
      return Image.network(
        activity.thumbnailUrl!,
        fit: BoxFit.cover,
        height: 100,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    if (hasYouTubeVideo && youtubeThumbnailUrl != null) {
      return Image.network(
        youtubeThumbnailUrl,
        fit: BoxFit.cover,
        height: 100,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    // กำหนดสีและไอคอนตามประเภทกิจกรรม
    final category = activity.category;

    // ด้านวิเคราะห์ = Math symbols with orange background
    if (category == 'ด้านวิเคราะห์') {
      return Container(
        height: 100,
        width: double.infinity,
        color: const Color(0xFFFF9800), // Orange
        alignment: Alignment.center,
        child: const Text(
          '+-×÷',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      );
    }

    // ด้านภาษา = ABC with yellow background
    if (category == 'ด้านภาษา' || category.toUpperCase() == 'LANGUAGE') {
      return Container(
        height: 100,
        width: double.infinity,
        color: const Color(0xFFFFEB3B), // Yellow
        alignment: Alignment.center,
        child: const Text(
          'ABC',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      );
    }

    // ด้านร่างกาย = Running icon with pink background
    if (category == 'ด้านร่างกาย') {
      return Container(
        height: 100,
        width: double.infinity,
        color: const Color(0xFFFFAB91), // Pink/Peach
        alignment: Alignment.center,
        child: const Icon(
          Icons.directions_run,
          color: Colors.white,
          size: 50,
        ),
      );
    }

    // Default fallback
    return Container(
      height: 100,
      width: double.infinity,
      color: deepSky,
      alignment: Alignment.center,
      child: Text(
        category.isNotEmpty ? category.substring(0, 1) : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String? _extractYouTubeVideoId(String? url) {
    if (url == null || url.isEmpty) return null;
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})'),
    ];
    for (var p in patterns) {
      final m = p.firstMatch(url);
      if (m != null && m.groupCount >= 1) return m.group(1);
    }
    if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }
    return null;
  }
}
