import 'package:flutter/material.dart';
import '../../../models/activity.dart';
import '../../../services/activity_service.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

/// Summary page shown before final submission.
///
/// Displays every segment's result (recognised text + score).
/// User can:
///   • Re-record a segment (pops with [_SummaryAction.reRecord] + index)
///   • Jump to a segment's Play Section (pops with [_SummaryAction.playSection] + index)
///   • Complete the activity (calls [onComplete])
///
/// Navigation contract with [ItemIntroScreen]:
///   pop result = null           → user just went back normally
///   pop result = {'reRecord': N}  → jump to segment N (0-indexed)
class ActivitySummaryScreen extends StatelessWidget {
  const ActivitySummaryScreen({
    super.key,
    required this.resultsNotifier,
    required this.activity,
    required this.onComplete,
    required this.isSubmitting,
  });

  final ValueNotifier<List<SegmentResult>> resultsNotifier;
  final Activity activity;

  /// Called when user taps "Complete Activity".
  final VoidCallback onComplete;

  /// True while [ItemIntroScreen] is calling finalizeQuest.
  final ValueNotifier<bool> isSubmitting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.summary_title,
          style: AppTextStyles.heading(20, color: Palette.sky),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<List<SegmentResult>>(
              valueListenable: resultsNotifier,
              builder: (context, results, _) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _SegmentCard(
                    index: i,
                    result: results[i],
                    onReRecord: () =>
                        Navigator.pop(context, {'reRecord': i}),
                    onPlaySection: () =>
                        Navigator.pop(context, {'playSection': i}),
                  ),
                );
              },
            ),
          ),

          // ── Sticky Complete Activity button ──────────────────────────
          ValueListenableBuilder<List<SegmentResult>>(
            valueListenable: resultsNotifier,
            builder: (context, results, _) {
              final pendingCount = results
                  .where((r) => r.status == SegmentStatus.processing)
                  .length;

              return ValueListenableBuilder<bool>(
                valueListenable: isSubmitting,
                builder: (context, submitting, _) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      boxShadow: Palette.headerShadow,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pendingCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Palette.sky),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.summary_pendingAnalysis(pendingCount),
                                    style: AppTextStyles.body(13,
                                        color: Palette.deepGrey),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  (submitting || pendingCount > 0)
                                      ? null
                                      : onComplete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.successAlt,
                                disabledBackgroundColor:
                                    Palette.successAlt.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(
                                      l10n.summary_completeActivity,
                                      style: AppTextStyles.heading(17,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Per-segment card ──────────────────────────────────────────────────────────

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.index,
    required this.result,
    required this.onReRecord,
    required this.onPlaySection,
  });

  final int index;
  final SegmentResult result;
  final VoidCallback onReRecord;
  final VoidCallback onPlaySection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _statusColor(result.status, result.maxScore);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Palette.cardShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Palette.blueChip.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.summary_segmentLabel(index + 1),
                  style: AppTextStyles.label(12, color: Palette.blueChip),
                ),
              ),
              const Spacer(),
              _StatusBadge(status: result.status, score: result.maxScore),
            ],
          ),
          const SizedBox(height: 10),

          // ── Target text ─────────────────────────────────────────
          Text(
            '${l10n.itemintro_speak.toUpperCase()}: ${result.text}',
            style: AppTextStyles.body(14,
                color: Palette.deepGrey, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),

          // ── Recognised text / status message ────────────────────
          _buildResultRow(context, l10n),
          const SizedBox(height: 10),

          // ── Score bar (only when done) ───────────────────────────
          if (result.status == SegmentStatus.done) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: result.maxScore / 100,
                backgroundColor: Palette.progressBg,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Action buttons ──────────────────────────────────────
          Row(
            children: [
              _ActionBtn(
                icon: Icons.mic,
                label: result.status == SegmentStatus.done
                    ? l10n.summary_reRecord
                    : l10n.itemintro_record,
                color: Palette.sky,
                onTap: onReRecord,
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.play_circle_outline,
                label: l10n.itemintro_playsection,
                color: Palette.bluePill,
                onTap: onPlaySection,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, AppLocalizations l10n) {
    switch (result.status) {
      case SegmentStatus.idle:
        return Text(
          l10n.summary_notRecorded,
          style: AppTextStyles.body(13, color: Palette.labelGrey),
        );
      case SegmentStatus.processing:
        return Row(
          children: [
            const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Palette.sky)),
            const SizedBox(width: 8),
            Text(l10n.summary_analyzing,
                style: AppTextStyles.body(13, color: Palette.sky)),
          ],
        );
      case SegmentStatus.error:
        return Text(
          l10n.summary_analysisFailed,
          style: AppTextStyles.body(13, color: Palette.errorStrong),
        );
      case SegmentStatus.done:
        return Text(
          '${l10n.summary_youSaid}: "${result.recognizedText ?? ''}"',
          style: AppTextStyles.body(13, color: Colors.black87),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Color _statusColor(SegmentStatus status, int score) {
    if (status != SegmentStatus.done) return Palette.labelGrey;
    if (score >= 70) return Palette.successAlt;
    if (score >= 40) return Palette.warning;
    return Palette.errorStrong;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.score});
  final SegmentStatus status;
  final int score;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case SegmentStatus.idle:
        return _badge(l10n.summary_notRecordedShort, Palette.labelGrey);
      case SegmentStatus.processing:
        return _badge(l10n.summary_analyzing, Palette.sky);
      case SegmentStatus.error:
        return _badge(l10n.summary_error, Palette.errorStrong);
      case SegmentStatus.done:
        final color = score >= 70
            ? Palette.successAlt
            : score >= 40
                ? Palette.warning
                : Palette.errorStrong;
        return _badge('$score%', color);
    }
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: AppTextStyles.label(12, color: color)),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: AppTextStyles.label(12, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
