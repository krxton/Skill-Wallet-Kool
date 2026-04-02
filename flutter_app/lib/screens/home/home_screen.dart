import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../../models/activity.dart';
import 'all_activities_screen.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/activity_service.dart';
import '../../theme/palette.dart';
import '../../utils/youtube_helper.dart';

import '../../theme/app_text_styles.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/scrollable_activity_list.dart';
import '../../widgets/main_bottom_nav.dart';
import '../profile/profile_screen.dart';
import '../activities/create_activity_screen.dart';
import '../child/add_child_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileKey = GlobalKey<ProfileScreenState>();

  // Filter states
  String?
      _selectedCategory; // null = ทั้งหมด, 'ด้านภาษา', 'ด้านร่างกาย', 'ด้านคำนวณ'
  String? _selectedLevel; // null = ทั้งหมด, 'ง่าย', 'กลาง', 'ยาก'

  final ActivityService _activityService = ActivityService();
  late Future<List<Activity>>
      _recommendedActivitiesFuture; // สำหรับ carousel ด้านบน
  late Future<List<Activity>>
      _popularActivitiesFuture; // สำหรับ Popular list ด้านล่าง
  late Future<List<Activity>> _newActivitiesFuture;

  String? _currentChildId;

  // Carousel
  final PageController _carouselController = PageController();
  int _currentCarouselPage = 0;

  // Horizontal lists
  final ScrollController _popularScrollController = ScrollController();
  final ScrollController _newScrollController = ScrollController();

  // Drag scrolling helpers
  double _popularDragStart = 0;
  double _newDragStart = 0;

  // bottom nav: 0 = home, 1 = plus, 2 = profile
  int _selectedTab = 0;

  // dirty flag — จะ reload home เฉพาะเมื่อมีการเปลี่ยนแปลง activity
  bool _homeNeedsRefresh = false;

  UserProvider? _userProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _userProvider = context.read<UserProvider>();
      _userProvider!.addListener(_onChildrenLoaded);
    });
  }

  void _onChildrenLoaded() {
    final newChildId = _userProvider?.currentChildId;
    // Reload whenever the active child changes (initial load OR manual switch)
    if (newChildId != null && newChildId != _currentChildId) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _userProvider?.removeListener(_onChildrenLoaded);
    _carouselController.dispose();
    _popularScrollController.dispose();
    _newScrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    final childId = userProvider.currentChildId;
    final parentId = userProvider.currentParentId;

    if (childId != null) {
      setState(() {
        _currentChildId = childId;
        _currentCarouselPage = 0;
        if (_carouselController.hasClients) {
          _carouselController.jumpToPage(0);
        }

        // Popular: fetch ครั้งเดียว ใช้ร่วมกับ Carousel (ลด API calls จาก 3 → 2)
        final popularFuture = _activityService.fetchPopularActivities(
          childId,
          category: _selectedCategory,
          level: _selectedLevel,
          parentId: parentId,
        );
        _popularActivitiesFuture = popularFuture;
        // Carousel ใช้ข้อมูลเดียวกับ popular แต่สุ่มเลือก 5 ตัว
        _recommendedActivitiesFuture = popularFuture.then(_pickRecommended);

        _newActivitiesFuture = _activityService.fetchNewActivities(
          childId,
          category: _selectedCategory,
          level: _selectedLevel,
          parentId: parentId,
        );
      });
    }
  }

  /// โหลดแค่ suggest carousel ใหม่ (แอบโหลดตอนออกจากหน้า)
  void _refreshSuggestedOnly() {
    if (!mounted) return;
    final childId = context.read<UserProvider>().currentChildId;
    final parentId = context.read<UserProvider>().currentParentId;
    if (childId != null) {
      final popularFuture = _activityService.fetchPopularActivities(
        childId,
        category: _selectedCategory,
        level: _selectedLevel,
        parentId: parentId,
      );
      setState(() {
        _currentCarouselPage = 0;
        _popularActivitiesFuture = popularFuture;
        _recommendedActivitiesFuture = popularFuture.then(_pickRecommended);
      });
      if (_carouselController.hasClients) {
        _carouselController.jumpToPage(0);
      }
    }
  }

  /// เลือก 5 กิจกรรมแนะนำจาก popular list (ไม่ fetch API เพิ่ม)
  /// - ถ้ามี filter → สุ่มจากผลลัพธ์ที่ filter แล้ว
  /// - ถ้าไม่มี filter → round-robin สลับ category
  List<Activity> _pickRecommended(List<Activity> allActivities) {
    if (allActivities.isEmpty) return [];

    final hasFilter = _selectedCategory != null || _selectedLevel != null;
    if (hasFilter) {
      final shuffled = List.of(allActivities)..shuffle();
      return shuffled.take(5).toList();
    }

    // round-robin สลับ category
    final Map<String, List<Activity>> byCategory = {};
    for (var a in allActivities) {
      byCategory.putIfAbsent(a.category, () => []).add(a);
    }
    for (var list in byCategory.values) {
      list.shuffle();
    }

    final categories = byCategory.keys.toList()..shuffle();
    debugPrint('Category rotation order: $categories');

    List<Activity> recommended = [];
    const int targetCount = 5;
    final Map<String, int> categoryIndex = {
      for (var c in categories) c: 0,
    };

    int catIdx = 0;
    while (recommended.length < targetCount) {
      final cat = categories[catIdx % categories.length];
      final pool = byCategory[cat]!;
      final idx = categoryIndex[cat]!;

      if (idx < pool.length) {
        recommended.add(pool[idx]);
        categoryIndex[cat] = idx + 1;
      }

      catIdx++;
      if (catIdx >= categories.length * (targetCount + 1)) break;
    }

    debugPrint('Recommended activities: ${recommended.length} items');
    return recommended;
  }

  void _onCategoryFilterChanged(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadData();
  }

  void _onLevelFilterChanged(String? level) {
    setState(() {
      _selectedLevel = level;
    });
    _loadData();
  }

  // ✅ แสดง dialog แจ้งเตือนให้เลือกเด็กก่อน
  void _showSelectChildDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text('กรุณาเลือกเด็ก', style: AppTextStyles.heading(20)),
          ],
        ),
        content: Text(
          'คุณต้องเลือกเด็กก่อนจึงจะสามารถเล่นกิจกรรมได้',
          style: AppTextStyles.body(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child:
                Text('ปิด', style: AppTextStyles.label(14, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, AppRoutes.childSetting);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.sky,
            ),
            child: Text('ไปเลือกเด็ก',
                style: AppTextStyles.label(14, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔀 Child switcher bottom sheet
  void _showChildSwitcher() {
    final userProvider = context.read<UserProvider>();
    final children = userProvider.children;
    if (children.length <= 1) return; // no need if only one child

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppLocalizations.of(context)!.home_switchChild,
              style: AppTextStyles.heading(18, color: Palette.deepGrey),
            ),
            const SizedBox(height: 10),
            ...children.map((c) {
              final child = c['child'] as Map<String, dynamic>?;
              if (child == null) return const SizedBox.shrink();
              final id = child['child_id'] as String?;
              final name = child['name_surname'] as String? ?? '—';
              final isSelected = id == userProvider.currentChildId;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: CircleAvatar(
                  backgroundColor: Palette.sky.withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTextStyles.heading(16, color: Palette.sky),
                  ),
                ),
                title: Text(name, style: AppTextStyles.body(16)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Palette.sky)
                    : null,
                onTap: () {
                  if (id != null && !isSelected) {
                    context.read<UserProvider>().selectChild(id);
                  }
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 🆕 แสดง Filter Bottom Sheet
  void _showFilterBottomSheet() {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Palette.cream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.home_filterTitle,
                      style: AppTextStyles.heading(20, color: Palette.sky)),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Filter
              Text(l.home_filterCategory,
                  style: AppTextStyles.heading(14, color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  {'label': l.home_filterAll, 'value': null},
                  {'label': l.home_languageBtn, 'value': 'ด้านภาษา'},
                  {'label': l.home_physicalBtn, 'value': 'ด้านร่างกาย'},
                  {'label': l.home_calculationBtn, 'value': 'ด้านคำนวณ'},
                ].map((cat) {
                  final isSelected = _selectedCategory == cat['value'];
                  return GestureDetector(
                    onTap: () {
                      _onCategoryFilterChanged(cat['value']);
                      setModalState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Palette.sky : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected ? Palette.sky : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        cat['label'] as String,
                        style: AppTextStyles.label(14,
                            color: isSelected ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Level Filter
              Text(l.home_filterLevel,
                  style: AppTextStyles.heading(14, color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  {'label': l.home_filterAll, 'value': null},
                  {'label': l.home_filterEasy, 'value': 'ง่าย'},
                  {'label': l.home_filterMedium, 'value': 'กลาง'},
                  {'label': l.home_filterHard, 'value': 'ยาก'},
                ].map((level) {
                  final isSelected = _selectedLevel == level['value'];
                  return GestureDetector(
                    onTap: () {
                      _onLevelFilterChanged(level['value']);
                      setModalState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Palette.warningLight : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Palette.warning
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        level['label'] as String,
                        style: AppTextStyles.label(14,
                            color: isSelected ? Colors.white : Colors.black87),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Carousel Item =====
  Widget _buildCarouselItem({
    required Activity activity,
    required int totalItems,
  }) {
    final category = activity.category.toUpperCase();

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
      final videoId = YouTubeHelper.extractVideoId(activity.videoUrl!);
      if (videoId != null) {
        youtubeThumbnailUrl =
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }

    String? thumbnailUrl;
    if (hasTikTokOEmbedData) {
      thumbnailUrl = activity.thumbnailUrl;
    } else if (hasYouTubeVideo && youtubeThumbnailUrl != null) {
      thumbnailUrl = youtubeThumbnailUrl;
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          if (_currentCarouselPage == 0) {
            _carouselController.animateToPage(
              totalItems - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            _carouselController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else if (details.primaryVelocity! < 0) {
          if (_currentCarouselPage == totalItems - 1) {
            _carouselController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            _carouselController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      },
      onTap: () {
        // ✅ ตรวจสอบว่าเลือกเด็กแล้วหรือยัง
        final userProvider = context.read<UserProvider>();
        if (userProvider.currentChildId == null) {
          _showSelectChildDialog();
          return;
        }

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

        // แอบโหลด suggest ใหม่ทันทีตอนออกจากหน้า (โหลด background ครั้งเดียว)
        _refreshSuggestedOnly();
        Navigator.pushNamed(context, routeName, arguments: activity);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null && hasYouTubeVideo)
              // YouTube thumbnail 4:3 มีแถบดำ → ขยาย 1.3x ตัดแถบดำ
              Transform.scale(
                scale: 1.3,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(activity.category);
                  },
                ),
              )
            else if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(activity.category);
                },
              )
            else
              _buildPlaceholder(activity.category),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: AppTextStyles.heading(20, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Palette.sky,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _localizeCategory(context, activity.category),
                          style: AppTextStyles.label(12, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${activity.maxScore}',
                        style: AppTextStyles.body(12, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Palette.teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.home_suggested,
                      style: AppTextStyles.heading(12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizeCategory(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'ด้านภาษา':
        return l10n.home_languageBtn;
      case 'ด้านร่างกาย':
        return l10n.home_physicalBtn;
      case 'ด้านคำนวณ':
        return l10n.home_calculationBtn;
      default:
        return category;
    }
  }

  Widget _buildPlaceholder(String category) {
    // ด้านคำนวณ = ใช้รูป Calculate
    if (category == 'ด้านคำนวณ') {
      return Image.asset(
        'assets/images/Analysis_img.jpg',
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: double.infinity,
            width: double.infinity,
            color: Palette.warning,
            alignment: Alignment.center,
            child: Text(
              '+-×÷',
              style: AppTextStyles.body(48,
                  color: Colors.white, weight: FontWeight.bold),
            ),
          );
        },
      );
    }

    // ด้านภาษา = ABC with yellow background
    if (category == 'ด้านภาษา' || category.toUpperCase() == 'LANGUAGE') {
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: Palette.languagePlaceholder,
        alignment: Alignment.center,
        child: Text(
          'ABC',
          style: AppTextStyles.body(48,
              color: Colors.black87, weight: FontWeight.bold),
        ),
      );
    }

    // ด้านร่างกาย = Running icon with pink background
    if (category == 'ด้านร่างกาย') {
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: Palette.physicalPlaceholder,
        alignment: Alignment.center,
        child: const Icon(
          Icons.directions_run,
          color: Colors.white,
          size: 70,
        ),
      );
    }

    // Default fallback
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Palette.sky,
      alignment: Alignment.center,
      child: Text(
        category.isNotEmpty ? category.substring(0, 1) : '?',
        style: AppTextStyles.body(48, color: Colors.white, weight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNoChildrenPlaceholder() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care_rounded,
                size: 80, color: Colors.black26),
            const SizedBox(height: 24),
            Text(
              l10n.home_noChildrenMsg,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(16, color: Colors.black54),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                final userProvider = context.read<UserProvider>();
                final newChildData =
                    await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddChildScreen()),
                );
                if (!mounted || newChildData == null) return;
                final birthday =
                    newChildData['birthday'] as DateTime? ?? DateTime.now();
                await userProvider.addChild(
                  name: newChildData['name'] as String,
                  birthday: birthday,
                  relationship: newChildData['relation'] as String?,
                );
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: Text(
                l10n.childsetting_addChild,
                style: AppTextStyles.label(16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.sky,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.children.isEmpty) {
      return _buildNoChildrenPlaceholder();
    }

    if (_currentChildId == null) {
      return const Center(
        child: CircularProgressIndicator(color: Palette.sky),
      );
    }

    final parentName = userProvider.currentParentName;
    final childName = userProvider.currentChildName;

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      color: Palette.sky,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
        // Filter button
        GestureDetector(
          onTap: _showFilterBottomSheet,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: (_selectedCategory != null || _selectedLevel != null)
                  ? Palette.sky
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Palette.sky, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune,
                    size: 20,
                    color: (_selectedCategory != null || _selectedLevel != null)
                        ? Colors.white
                        : Palette.sky),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.home_filterTitle,
                  style: AppTextStyles.label(14,
                      color:
                          (_selectedCategory != null || _selectedLevel != null)
                              ? Colors.white
                              : Palette.sky),
                ),
                if (_selectedCategory != null || _selectedLevel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(_selectedCategory != null ? 1 : 0) + (_selectedLevel != null ? 1 : 0)}',
                      style: AppTextStyles.label(12, color: Palette.sky),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Parent + Child name
        if (parentName != null && parentName.isNotEmpty)
          Text(
            parentName,
            style: AppTextStyles.heading(24, color: Palette.deepGrey),
          ),
        if (childName != null && childName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: GestureDetector(
              onTap: userProvider.children.length > 1 ? _showChildSwitcher : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.child_care, size: 20, color: Palette.sky),
                  const SizedBox(width: 6),
                  Text(
                    childName,
                    style: AppTextStyles.label(16, color: Palette.sky),
                  ),
                  if (userProvider.children.length > 1) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 20, color: Palette.sky),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),

        // Top Carousel - แสดงกิจกรรมแนะนำตามหมวดที่เคยเล่น
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Palette.sky, width: 3),
          ),
          child: FutureBuilder<List<Activity>>(
            future: _recommendedActivitiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Palette.sky),
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.home_cannotBtn,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading(16, color: Colors.black),
                  ),
                );
              }

              // แสดง 5 กิจกรรมแนะนำ
              final topActivities = snapshot.data!.take(5).toList();

              return Stack(
                children: [
                  PageView.builder(
                    controller: _carouselController,
                    itemCount: topActivities.length,
                    onPageChanged: (i) => setState(() {
                      _currentCarouselPage = i;
                    }),
                    itemBuilder: (_, i) => _buildCarouselItem(
                      activity: topActivities[i],
                      totalItems: topActivities.length,
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        topActivities.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentCarouselPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentCarouselPage == i
                                ? Palette.sky
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (topActivities.length > 1) ...[
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            if (_currentCarouselPage == 0) {
                              _carouselController.animateToPage(
                                topActivities.length - 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _carouselController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            if (_currentCarouselPage ==
                                topActivities.length - 1) {
                              _carouselController.animateToPage(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _carouselController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 30),

        // Popular list
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.home_popularactivityBtn,
              style: AppTextStyles.heading(20, color: Colors.black),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.allActivities,
                arguments: ActivityListType.popular,
              ),
              child: Text(
                AppLocalizations.of(context)!.home_viewallBtn,
                style: AppTextStyles.heading(16, color: Palette.sky),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ScrollableActivityList(
          future: _popularActivitiesFuture,
          controller: _popularScrollController,
          emptyMessage: AppLocalizations.of(context)!.home_cannotBtn,
          onDragStart: (dx) => _popularDragStart = dx,
          onDragUpdate: (dx) {
            final delta = _popularDragStart - dx;
            _popularDragStart = dx;
            _popularScrollController.jumpTo(
              _popularScrollController.offset + delta,
            );
          },
          itemBuilder: (a) => ActivityCard(activity: a),
          emptyAction: TextButton(
            onPressed: () => Navigator.pushNamed(
              context, AppRoutes.allActivities,
              arguments: ActivityListType.popular,
            ),
            child: Text(
              AppLocalizations.of(context)!.home_viewallBtn,
              style: AppTextStyles.label(13, color: Palette.sky),
            ),
          ),
        ),

        const SizedBox(height: 30),

        // New list
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.home_newactivityBtn,
              style: AppTextStyles.heading(20, color: Colors.black),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.allActivities,
                arguments: ActivityListType.newActivity,
              ),
              child: Text(
                AppLocalizations.of(context)!.home_viewallBtn,
                style: AppTextStyles.heading(16, color: Palette.sky),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ScrollableActivityList(
          future: _newActivitiesFuture,
          controller: _newScrollController,
          emptyMessage: AppLocalizations.of(context)!.home_nonewBtn,
          onDragStart: (dx) => _newDragStart = dx,
          onDragUpdate: (dx) {
            final delta = _newDragStart - dx;
            _newDragStart = dx;
            _newScrollController.jumpTo(
              _newScrollController.offset + delta,
            );
          },
          itemBuilder: (a) => ActivityCard(activity: a),
          emptyAction: TextButton(
            onPressed: () => Navigator.pushNamed(
              context, AppRoutes.allActivities,
              arguments: ActivityListType.newActivity,
            ),
            child: Text(
              AppLocalizations.of(context)!.home_viewallBtn,
              style: AppTextStyles.label(13, color: Palette.sky),
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 0 = Home, 2 = Profile  (1 = + ใช้เปิดหน้าใหม่ด้วย Navigator)
    final pages = <Widget>[
      _buildHomeBody(context),
      ProfileScreen(
          key: _profileKey, onActivityChanged: () => _homeNeedsRefresh = true),
    ];

    // ถ้าเลือก tab 2 ให้โชว์ index 1 (Profile) ไม่งั้นใช้ Home
    final int visibleIndex = _selectedTab == 2 ? 1 : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: IndexedStack(
        index: visibleIndex,
        children: pages,
      ),
      bottomNavigationBar: MainBottomNav(
          selectedIndex: _selectedTab,
          onTabSelected: (i) {
            if (i == 1) {
              Navigator.of(context)
                  .push<bool>(
                MaterialPageRoute(
                  builder: (context) => const CreateActivityScreen(),
                  fullscreenDialog: true,
                ),
              )
                  .then((created) {
                if (created == true) {
                  _loadData();
                  _profileKey.currentState?.reloadActivities();
                }
              });
              return;
            }
            // กลับมา home tab → โหลดใหม่เฉพาะเมื่อมีการเปลี่ยนแปลง
            if (i == 0 && _selectedTab != 0 && _homeNeedsRefresh) {
              _homeNeedsRefresh = false;
              _loadData();
            }
            // ออกจาก home tab → แอบโหลด suggest ใหม่
            if (_selectedTab == 0 && i != 0) _refreshSuggestedOnly();
            setState(() => _selectedTab = i);
          },
        ),
    );
  }
}
