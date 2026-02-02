import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/activity.dart';
import '../routes/app_routes.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
  });

  final Activity activity;

  static const deepSky = Color(0xFF7DBEF1);

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

    void navigate() {
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
    return Container(
      height: 100,
      width: double.infinity,
      color: deepSky,
      alignment: Alignment.center,
      child: Text(
        activity.category.isNotEmpty ? activity.category.substring(0, 1) : '?',
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
