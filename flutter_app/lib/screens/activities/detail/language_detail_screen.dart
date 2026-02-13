import 'package:flutter/material.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/youtube_helper.dart';
import '../../../widgets/info_badges.dart';
import '../../../widgets/sticky_bottom_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final String name = widget.activity.name;
    final String description =
        widget.activity.description ?? 'No description provided.';

    if (_ytController != null) {
      return YoutubePlayerScaffold(
        controller: _ytController!,
        aspectRatio: 16 / 9,
        builder: (context, player) {
          return _buildScaffold(context, name, description,
              videoWidget: player);
        },
      );
    }

    return _buildScaffold(context, name, description, videoWidget: null);
  }

  Widget _buildScaffold(
    BuildContext context,
    String name,
    String description, {
    required Widget? videoWidget,
  }) {
    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        title: Text('LANGUAGE: ${widget.activity.name.toUpperCase()}',
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

                  // Playable YouTube Video
                  if (videoWidget != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: videoWidget,
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Palette.languagePlaceholder,
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

                  // Activity Title
                  _buildSectionTitle(AppLocalizations.of(context)!
                      .languagedetail_activityTitleLabel),
                  _buildContentCard(name),

                  const SizedBox(height: 10),

                  // Description
                  _buildSectionTitle(AppLocalizations.of(context)!
                      .languagedetail_descriptionLabel),
                  _buildContentCard(description),

                  const SizedBox(height: 16),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppTextStyles.heading(18, color: Palette.deepGrey),
      ),
    );
  }

  Widget _buildContentCard(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.sky, width: 1),
      ),
      child: Text(
        text,
        style: AppTextStyles.body(15),
      ),
    );
  }
}
