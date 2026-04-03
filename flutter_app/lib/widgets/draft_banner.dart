// lib/widgets/draft_banner.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../models/activity.dart';
import '../providers/user_provider.dart';
import '../routes/app_routes.dart';
import '../services/draft_service.dart';
import '../theme/app_text_styles.dart';
import '../theme/palette.dart';
import '../utils/activity_l10n.dart';

class DraftBanner extends StatefulWidget {
  const DraftBanner({super.key});

  @override
  State<DraftBanner> createState() => _DraftBannerState();
}

class _DraftBannerState extends State<DraftBanner> {
  Map<String, dynamic>? _draft;
  String? _loadedForChildId;

  @override
  void initState() {
    super.initState();
    DraftService.versionNotifier.addListener(_onVersionChange);
  }

  @override
  void dispose() {
    DraftService.versionNotifier.removeListener(_onVersionChange);
    super.dispose();
  }

  void _onVersionChange() {
    // Force reload when draft is saved or cleared
    _loadedForChildId = null;
    _loadDraft();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final childId = context.read<UserProvider>().currentChildId;
    if (childId == _loadedForChildId) return; // already loaded for this child
    _loadedForChildId = childId;
    if (childId == null) {
      if (mounted) setState(() => _draft = null);
      return;
    }
    final draft = await DraftService.loadDraft(childId);
    if (mounted) setState(() => _draft = draft);
  }

  Future<void> _resume() async {
    if (_draft == null) return;
    final type = _draft!['type'] as String;
    final activityJson = _draft!['activityJson'] as Map<String, dynamic>;
    final activity = Activity.fromJson(activityJson);
    final route = switch (type) {
      DraftService.typePhysical => AppRoutes.physicalActivity,
      DraftService.typeCalculate => AppRoutes.calculateActivity,
      _ => AppRoutes.itemIntro,
    };
    if (!mounted) return;
    Navigator.pushNamed(context, route, arguments: activity);
  }

  Future<void> _discard() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.draft_discardTitle, style: AppTextStyles.heading(18)),
        content: Text(l.draft_discardMsg, style: AppTextStyles.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.common_cancel, style: AppTextStyles.body(14)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.draft_bannerDiscard,
                style: AppTextStyles.body(14, color: Palette.pink)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final childId = context.read<UserProvider>().currentChildId;
    if (childId != null) await DraftService.clearDraft(childId);
    // clearDraft bumps versionNotifier → _onVersionChange reloads
  }

  @override
  Widget build(BuildContext context) {
    if (_draft == null) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final activityJson =
        _draft!['activityJson'] as Map<String, dynamic>? ?? {};
    final activityName = activityJson['name_activity'] as String? ?? '—';
    final category = activityJson['category'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Palette.sky.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.sky, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: Palette.sky, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.draft_bannerTitle,
                    style: AppTextStyles.label(12, color: Palette.deepGrey)),
                Text(
                  activityName,
                  style: AppTextStyles.heading(14, color: Palette.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  ActivityL10n.localizedActivityType(context, category),
                  style: AppTextStyles.body(12, color: Palette.deepGrey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _resume,
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.sky,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l.draft_bannerResume,
                style: AppTextStyles.label(13, color: Colors.white)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _discard,
            child: const Icon(Icons.close, size: 20, color: Palette.deepGrey),
          ),
        ],
      ),
    );
  }
}
