import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../../models/activity.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/activity_service.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';
import '../activities/edit_activity_screen.dart';
import 'settings/setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final ActivityService _activityService = ActivityService();
  List<Activity> _myActivities = [];
  bool _loading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActivities());
  }

  /// Public method so HomeScreen can trigger a reload.
  void reloadActivities() => _loadActivities();

  Future<void> _loadActivities() async {
    final parentId =
        Provider.of<UserProvider>(context, listen: false).currentParentId;
    if (parentId == null || parentId.isEmpty) return;

    setState(() => _loading = true);
    final activities = await _activityService.fetchMyActivities(parentId);
    if (mounted) {
      setState(() {
        _myActivities = activities;
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      context.read<UserProvider>().setProfileImage(bytes);
    }
  }

  /// Translate raw difficulty value to localized string
  String _translateDifficulty(String raw, AppLocalizations l) {
    switch (raw) {
      case 'ง่าย':
        return l.common_difficultyEasy;
      case 'กลาง':
        return l.common_difficultyMedium;
      case 'ยาก':
        return l.common_difficultyHard;
      default:
        return raw;
    }
  }

  // ── Play activity ───────────────────────────────────────

  void _playActivity(Activity activity) {
    final category = activity.category;
    String routeName;

    if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
      routeName = AppRoutes.languageDetail;
    } else if (category == 'ด้านร่างกาย' && activity.videoUrl != null) {
      routeName = AppRoutes.videoDetail;
    } else if (category == 'ด้านคำนวณ') {
      routeName = AppRoutes.calculateActivity;
    } else {
      routeName = AppRoutes.itemIntro;
    }

    Navigator.pushNamed(context, routeName, arguments: activity);
  }

  // ── Navigate to edit ───────────────────────────────────

  void _openEdit(Activity activity) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditActivityScreen(activity: activity),
      ),
    );
    if (result == true) _loadActivities();
  }

  // ── Delete ─────────────────────────────────────────────

  void _showDeleteDialog(Activity activity) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.profile_deleteActivity,
            style: AppTextStyles.heading(18)),
        content: Text(l.profile_deleteConfirm(activity.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.dialog_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _activityService.deleteActivity(activity.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.profile_deleteSuccess)),
                  );
                  _loadActivities();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(l.dialog_confirmDelete,
                style: const TextStyle(color: Palette.deleteRed)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final parentName = userProvider.currentParentName ?? 'PARENT';
    final profileImageBytes = userProvider.profileImageBytes;
    final l = AppLocalizations.of(context)!;

    return Container(
      color: Palette.cream,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // ── Header ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.white,
                            child: profileImageBytes == null
                                ? const Icon(Icons.person,
                                    size: 80, color: Colors.black87)
                                : ClipOval(
                                    child: Image.memory(
                                      profileImageBytes,
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(parentName,
                            style: AppTextStyles.heading(24)),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.settings, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Section header ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_esports, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l.profile_myActivities,
                            style: AppTextStyles.heading(18)),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isEditMode = !_isEditMode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isEditMode
                                ? Palette.warning
                                : Palette.sky,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            l.profile_manage,
                            style: AppTextStyles.label(12,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
                ],
              ),
            ),

            // ── Activity list ────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _myActivities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sports_esports_outlined,
                                  size: 48, color: Palette.labelGrey),
                              const SizedBox(height: 8),
                              Text(l.profile_noActivities,
                                  style: AppTextStyles.body(16,
                                      color: Palette.labelGrey)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadActivities,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _myActivities.length,
                            itemBuilder: (context, index) =>
                                _buildActivityCard(_myActivities[index], l),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Activity Card ──────────────────────────────────────

  Widget _buildActivityCard(Activity activity, AppLocalizations l) {
    final isPhysical = activity.category == 'ด้านร่างกาย';
    final categoryColor =
        isPhysical ? Palette.physicalPlaceholder : Palette.blueChip;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isEditMode
            ? () => _openEdit(activity)
            : () => _playActivity(activity),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPhysical ? Icons.directions_run : Icons.psychology,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),

              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.name,
                        style: AppTextStyles.label(14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chipLabel(
                          isPhysical
                              ? l.createActivity_physical
                              : l.createActivity_calculate,
                          categoryColor,
                        ),
                        _chipLabel(
                          _translateDifficulty(activity.difficulty, l),
                          Palette.warning,
                        ),
                        _chipLabel(
                          '${activity.maxScore} pt',
                          Palette.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit/delete buttons
              if (_isEditMode) ...[
                IconButton(
                  icon: const Icon(Icons.edit, size: 20,
                      color: Palette.sky),
                  onPressed: () => _openEdit(activity),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20,
                      color: Palette.deleteRed),
                  onPressed: () => _showDeleteDialog(activity),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style:
              AppTextStyles.body(10, color: color, weight: FontWeight.w600)),
    );
  }
}
