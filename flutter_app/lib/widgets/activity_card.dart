import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/activity.dart';
import '../providers/user_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';
import '../utils/youtube_helper.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
  });

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final category = activity.category.toUpperCase();

    final bool hasTikTokOEmbedData = category == 'ด้านร่างกาย' &&
        activity.videoUrl != null &&
        activity.tiktokHtmlContent != null &&
        activity.thumbnailUrl != null;

    String? youtubeThumbnailUrl;
    if ((category == 'ด้านภาษา' || category == 'LANGUAGE') &&
        activity.videoUrl != null) {
      final videoId = YouTubeHelper.extractVideoId(activity.videoUrl!);
      if (videoId != null) {
        youtubeThumbnailUrl = YouTubeHelper.thumbnailUrl(videoId);
      }
    }
    final bool hasYouTubeVideo = youtubeThumbnailUrl != null;

    final bool shouldGoToVideoDetail =
        category == 'ด้านร่างกาย' && activity.videoUrl != null;

    void showSelectChildDialog() {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(
                l10n.activityCard_selectChild,
                style: AppTextStyles.heading(20),
              ),
            ],
          ),
          content: Text(
            l10n.activityCard_selectChildMsg,
            style: AppTextStyles.body(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.common_close,
                style: AppTextStyles.body(14, color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamed(context, AppRoutes.childSetting);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.sky,
              ),
              child: Text(
                l10n.activityCard_goSelect,
                style: AppTextStyles.body(14, color: Colors.white),
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
      } else if (category == 'ด้านคำนวณ') {
        Navigator.pushNamed(
          context,
          AppRoutes.calculateActivity,
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
        width: 125,
        height: 145,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: _buildThumbnail(
                  hasTikTokOEmbedData: hasTikTokOEmbedData,
                  hasYouTubeVideo: hasYouTubeVideo,
                  youtubeThumbnailUrl: youtubeThumbnailUrl,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: AppTextStyles.heading(11, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.common_score}: ${activity.maxScore}',
                    style: TextStyle(
                      fontSize: 9,
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
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.network(
          activity.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    if (hasYouTubeVideo && youtubeThumbnailUrl != null) {
      // YouTube hqdefault เป็น 4:3 แต่วีดีโอเป็น 16:9 ทำให้มีแถบดำ
      // ขยาย 1.35x เพื่อตัดแถบดำออก
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Transform.scale(
          scale: 1.32,
          child: Image.network(
            youtubeThumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    // กำหนดสีและไอคอนตามประเภทกิจกรรม
    final category = activity.category;

    // ด้านคำนวณ = ใช้รูป Analysis_img
    if (category == 'ด้านคำนวณ') {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Image.asset(
          'assets/images/Analysis_img.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFFF9800),
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
          },
        ),
      );
    }

    // ด้านภาษา = ABC with yellow background
    if (category == 'ด้านภาษา' || category.toUpperCase() == 'LANGUAGE') {
      return Container(
        width: double.infinity,
        height: double.infinity,
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
        width: double.infinity,
        height: double.infinity,
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
      width: double.infinity,
      height: double.infinity,
      color: Palette.sky,
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
}
