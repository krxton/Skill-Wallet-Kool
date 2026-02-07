import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/activity_l10n.dart';

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

  String _buildYouTubeEmbedHtml(String videoId) {
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
  iframe { width: 100%; height: 100%; border: none; }
</style>
</head>
<body>
<iframe
  src="https://www.youtube.com/embed/$videoId?playsinline=1&rel=0&modestbranding=1"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
  allowfullscreen>
</iframe>
</body>
</html>
''';
  }

  String? _extractYouTubeVideoId(String? url) {
    if (url == null || url.isEmpty) return null;
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    ];
    for (var p in patterns) {
      final m = p.firstMatch(url);
      if (m != null && m.groupCount >= 1) return m.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String name = activity.name;
    final String description =
        activity.description ?? 'No description provided.';

    // YouTube video embed
    final videoId = _extractYouTubeVideoId(activity.videoUrl);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text('LANGUAGE: ${activity.name.toUpperCase()}',
            style: GoogleFonts.luckiestGuy(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Info badges (Category, Difficulty, Max Score)
                  _buildInfoBadges(context),

                  const SizedBox(height: 16),

                  // 2. Playable YouTube Video
                  if (videoId != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InAppWebView(
                          initialData: InAppWebViewInitialData(
                            data: _buildYouTubeEmbedHtml(videoId),
                            mimeType: 'text/html',
                            encoding: 'utf-8',
                          ),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            mediaPlaybackRequiresUserGesture: false,
                            allowsInlineMediaPlayback: true,
                            supportMultipleWindows: false,
                            javaScriptCanOpenWindowsAutomatically: false,
                            transparentBackground: false,
                          ),
                        ),
                      ),
                    )
                  else
                    // Fallback placeholder if no video
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEB3B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'ABC',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 3. Activity Title
                  _buildSectionTitle(AppLocalizations.of(context)!
                      .languagedetail_activityTitleLabel),
                  _buildContentCard(name),

                  const SizedBox(height: 10),

                  // 3. 🆕 แสดง Description ใน Card ที่สอง
                  _buildSectionTitle(AppLocalizations.of(context)!
                      .languagedetail_descriptionLabel), // 🆕 หัวข้อใหม่
                  _buildContentCard(description), // 🆕 ใช้ description

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Sticky START button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: cream,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                  AppLocalizations.of(context)!.languagedetail_startBtn,
                  style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 20,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildInfoBadges(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedCategory =
        ActivityL10n.localizedCategory(context, activity.category);
    final localizedDifficulty =
        ActivityL10n.localizedDifficulty(context, activity.difficulty);

    return Row(
      children: [
        _buildBadge(
          icon: Icons.category_outlined,
          label: l10n.common_categoryLabel,
          value: localizedCategory,
          color: sky,
        ),
        const SizedBox(width: 8),
        _buildBadge(
          icon: Icons.speed_outlined,
          label: l10n.common_difficultyLabel,
          value: localizedDifficulty,
          color: const Color(0xFFFF9800),
        ),
        const SizedBox(width: 8),
        _buildBadge(
          icon: Icons.star_outline,
          label: l10n.common_maxScoreLabel,
          value: '${activity.maxScore}',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
