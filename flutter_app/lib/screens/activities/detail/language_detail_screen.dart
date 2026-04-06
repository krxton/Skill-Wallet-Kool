import 'package:flutter/material.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/youtube_helper.dart';
import '../../../widgets/info_badges.dart';
import '../../../utils/activity_l10n.dart';
import '../../../widgets/sticky_bottom_button.dart';

const _kAmber = Color(0xFFFFB300);

class LanguageDetailScreen extends StatefulWidget {
  static const String routeName = '/language_detail';

  final Activity activity;

  const LanguageDetailScreen({
    super.key,
    required this.activity,
  });

  @override
  State<LanguageDetailScreen> createState() => _LanguageDetailScreenState();
}

class _LanguageDetailScreenState extends State<LanguageDetailScreen> {
  YoutubePlayerController? _ytController;
  String _videoId = '';
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _videoId = YouTubeHelper.extractVideoId(widget.activity.videoUrl) ?? '';

    if (_videoId.isNotEmpty) {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: _videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          origin: 'https://www.youtube-nocookie.com',
        ),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  Future<void> _openInYouTube() async {
    if (_videoId.isEmpty) return;
    final appUri = Uri.parse('youtube://watch?v=$_videoId');
    final webUri = Uri.parse('https://www.youtube.com/watch?v=$_videoId');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.activity.name;

    if (_ytController != null) {
      return YoutubePlayerScaffold(
        controller: _ytController!,
        aspectRatio: 16 / 9,
        builder: (context, player) {
          return _buildScaffold(context, name, videoWidget: player);
        },
      );
    }

    return _buildScaffold(context, name, videoWidget: null);
  }

  Widget _buildScaffold(
    BuildContext context,
    String name, {
    required Widget? videoWidget,
  }) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
            ActivityL10n.localizedActivityType(
                context, widget.activity.category),
            style: AppTextStyles.heading(22, color: Colors.black)),
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
                  InfoBadges(activity: widget.activity),

                  const SizedBox(height: 16),

                  // ── YouTube Player ──
                  if (videoWidget != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: videoWidget,
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: _kAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _kAmber.withValues(alpha: 0.3), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline_rounded,
                              size: 48, color: _kAmber.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text('ABC',
                              style: AppTextStyles.heading(40,
                                  color: _kAmber.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),

                  // ── Open in YouTube (TV) banner ──
                  if (_videoId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onTap: _openInYouTube,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: Palette.cardShadow,
                            border: Border.all(
                                color: const Color(0xFFFF0000)
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF0000),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.tv_rounded,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .languagedetail_openInYoutube,
                                      style: AppTextStyles.label(14,
                                          color:
                                              const Color(0xFFFF0000)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .calculate_tvModeBannerSub,
                                      style: AppTextStyles.body(12,
                                          color: Palette.labelGrey),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Color(0xFFFF0000), size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ── Activity Title ──
                  _buildSectionLabel(
                    Icons.text_fields_rounded,
                    AppLocalizations.of(context)!
                        .languagedetail_activityTitleLabel,
                  ),
                  const SizedBox(height: 8),
                  _buildContentCard(name),
                  const SizedBox(height: 16),

                  // ── Description (collapsible) ──
                  if ((widget.activity.description ?? '').isNotEmpty)
                    StatefulBuilder(
                      builder: (_, setLocal) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setLocal(() => _descExpanded = !_descExpanded),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: Palette.sky, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!
                                      .languagedetail_descriptionLabel,
                                  style: AppTextStyles.heading(18,
                                      color: Palette.sky),
                                ),
                                const Spacer(),
                                AnimatedRotation(
                                  turns: _descExpanded ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Palette.sky,
                                      size: 24),
                                ),
                              ],
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: _descExpanded
                                ? Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: Palette.cardShadow,
                                      border: Border.all(
                                          color: Palette.sky.withValues(alpha: 0.25)),
                                    ),
                                    child: Text(
                                      widget.activity.description!,
                                      style: AppTextStyles.body(15),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          StickyBottomButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.itemIntro,
                arguments: widget.activity,
              );
            },
            label: AppLocalizations.of(context)!.languagedetail_startBtn,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Palette.sky, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.heading(18, color: Palette.sky)),
      ],
    );
  }

  Widget _buildContentCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: Palette.cardShadow,
        border: Border.all(color: Palette.sky.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: AppTextStyles.body(15)),
    );
  }
}
