import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../theme/palette.dart';
import '../theme/app_text_styles.dart';

/// Data model for share content
class ShareResultData {
  final String activityName;
  final int score;
  final int maxScore;
  final int timeSpentSeconds;
  final String? category;

  const ShareResultData({
    required this.activityName,
    required this.score,
    required this.maxScore,
    required this.timeSpentSeconds,
    this.category,
  });

  double get percentage => maxScore > 0 ? (score / maxScore) * 100 : 0;
  bool get isPassed => percentage >= 70;
}

/// Shows share bottom sheet with options
Future<void> showShareBottomSheet(
  BuildContext context,
  ShareResultData data,
) async {
  final l = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ShareBottomSheet(data: data, l: l),
  );
}

class _ShareBottomSheet extends StatefulWidget {
  final ShareResultData data;
  final AppLocalizations l;

  const _ShareBottomSheet({required this.data, required this.l});

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  String _formatTime(int seconds) {
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _buildShareText() {
    final d = widget.data;
    final l = widget.l;
    final emoji = d.isPassed ? '🎉' : '💪';
    return '$emoji ${l.share_textTemplate(d.activityName, d.score, d.maxScore)}';
  }

  Future<void> _shareAsImage() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      if (!mounted) return;
      Navigator.pop(context);

      await Share.shareXFiles(
        [XFile.fromData(pngBytes, mimeType: 'image/png', name: 'result.png')],
        text: _buildShareText(),
      );
    } catch (e) {
      debugPrint('Share image error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareAsText() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      if (!mounted) return;
      Navigator.pop(context);

      await Share.share(_buildShareText());
    } catch (e) {
      debugPrint('Share text error: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final d = widget.data;
    final scoreColor = d.isPassed ? Palette.successAlt : Palette.pink;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Palette.labelGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(l.share_title, style: AppTextStyles.heading(20)),
          const SizedBox(height: 16),

          // Preview card (captured as image)
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Palette.cream,
                    scoreColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scoreColor, width: 2),
              ),
              child: Column(
                children: [
                  // App branding
                  Text('Skill Wallet Kool',
                      style: AppTextStyles.heading(14, color: Palette.sky)),
                  const SizedBox(height: 12),

                  // Activity name
                  Text(
                    d.activityName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading(16, color: Palette.deepGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Score
                  Text(
                    '${d.score} / ${d.maxScore}',
                    style: AppTextStyles.heading(40, color: scoreColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.isPassed ? l.share_greatJob : l.share_keepTrying,
                    style: AppTextStyles.heading(16, color: scoreColor),
                  ),
                  const SizedBox(height: 8),

                  // Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 16, color: Palette.deepGrey),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(d.timeSpentSeconds),
                        style: AppTextStyles.body(13, color: Palette.deepGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Share options
          Row(
            children: [
              Expanded(
                child: _ShareOptionButton(
                  icon: Icons.image_outlined,
                  label: l.share_asImage,
                  color: Palette.sky,
                  onTap: _shareAsImage,
                  isLoading: _isSharing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShareOptionButton(
                  icon: Icons.text_snippet_outlined,
                  label: l.share_asText,
                  color: Palette.success,
                  onTap: _shareAsText,
                  isLoading: _isSharing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ShareOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.label(12, color: color)),
          ],
        ),
      ),
    );
  }
}
