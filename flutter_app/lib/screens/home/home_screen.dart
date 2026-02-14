import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../../models/activity.dart';
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
  String? _currentParentId;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
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
        _currentParentId = parentId;
        // Carousel ด้านบน = กิจกรรมแนะนำตามหมวดที่เคยเล่น
        _recommendedActivitiesFuture = _fetchRecommendedActivities(childId);
        // Popular list ด้านล่าง = กิจกรรมยอดนิยม (ตาม play_count)
        _popularActivitiesFuture = _activityService.fetchPopularActivities(
          childId,
          category: _selectedCategory,
          level: _selectedLevel,
          parentId: parentId,
        );
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
    if (childId != null) {
      setState(() {
        _currentCarouselPage = 0;
        _recommendedActivitiesFuture = _fetchRecommendedActivities(childId);
      });
      // reset carousel position กลับหน้าแรกเสมอ
      if (_carouselController.hasClients) {
        _carouselController.jumpToPage(0);
      }
    }
  }

  /// ดึงกิจกรรมแนะนำสำหรับ Carousel สลับ category วนรอบ (รวม 5 กิจกรรม)
  Future<List<Activity>> _fetchRecommendedActivities(String childId) async {
    try {
      // 1. ดึงกิจกรรมทั้งหมด
      final allActivities = await _activityService
          .fetchPopularActivities(childId, parentId: _currentParentId);

      if (allActivities.isEmpty) return [];

      // 2. แยกกิจกรรมตาม category แล้วสุ่มภายในแต่ละ category
      final Map<String, List<Activity>> byCategory = {};
      for (var a in allActivities) {
        byCategory.putIfAbsent(a.category, () => []).add(a);
      }
      for (var list in byCategory.values) {
        list.shuffle();
      }

      // 3. สุ่มลำดับ category
      final categories = byCategory.keys.toList()..shuffle();
      debugPrint('🔄 Category rotation order: $categories');

      // 4. Round-robin เลือกทีละ category จนครบ 5
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
        // ป้องกัน infinite loop ถ้ากิจกรรมทั้งหมดน้อยกว่า targetCount
        if (catIdx >= categories.length * (targetCount + 1)) break;
      }

      debugPrint('✅ Recommended activities: ${recommended.length} items');
      return recommended;
    } catch (e) {
      debugPrint('❌ Error fetching recommended activities: $e');
      final all = await _activityService.fetchPopularActivities(childId,
          parentId: _currentParentId);
      all.shuffle();
      return all.take(5).toList();
    }
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
            Text('กรุณาเลือกเด็ก',
                style: AppTextStyles.heading(20)),
          ],
        ),
        content: Text(
          'คุณต้องเลือกเด็กก่อนจึงจะสามารถเล่นกิจกรรมได้',
          style: AppTextStyles.body(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ปิด',
                style: AppTextStyles.label(14, color: Colors.grey)),
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
                            color:
                                isSelected ? Colors.white : Colors.black87),
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
                        color: isSelected
                            ? const Color(0xFFFFB74D)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF9800)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        level['label'] as String,
                        style: AppTextStyles.label(14,
                            color:
                                isSelected ? Colors.white : Colors.black87),
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
                    Colors.black.withOpacity(0.7),
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
                          activity.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${activity.maxScore}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
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
                  color: const Color.fromARGB(255, 26, 170, 136),
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
            color: const Color(0xFFFF9800),
            alignment: Alignment.center,
            child: const Text(
              '+-×÷',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
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
        color: const Color(0xFFFFEB3B), // Yellow
        alignment: Alignment.center,
        child: const Text(
          'ABC',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
      );
    }

    // ด้านร่างกาย = Running icon with pink background
    if (category == 'ด้านร่างกาย') {
      return Container(
        height: double.infinity,
        width: double.infinity,
        color: const Color(0xFFFFAB91), // Pink/Peach
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
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    if (_currentChildId == null) {
      return const Center(
        child: CircularProgressIndicator(color: Palette.sky),
      );
    }

    // แสดงชื่อเด็กที่เลือกอยู่แทนชื่อผู้ปกครอง
    final childName = context.watch<UserProvider>().currentChildName;

    return ListView(
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
                    color: (_selectedCategory != null ||
                            _selectedLevel != null)
                        ? Colors.white
                        : Palette.sky),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.home_filterTitle,
                  style: AppTextStyles.label(14,
                      color: (_selectedCategory != null ||
                              _selectedLevel != null)
                          ? Colors.white
                          : Palette.sky),
                ),
                if (_selectedCategory != null || _selectedLevel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
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

        // Child Name (ชื่อเด็กที่เลือกอยู่)
        if (childName != null && childName.isNotEmpty)
          Text(
            childName,
            style: AppTextStyles.heading(28, color: Palette.sky),
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
                                : Colors.white.withOpacity(0.5),
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
            Text(
              AppLocalizations.of(context)!.home_viewallBtn,
              style: AppTextStyles.heading(16, color: Palette.sky),
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
            Text(
              AppLocalizations.of(context)!.home_viewallBtn,
              style: AppTextStyles.heading(16, color: Palette.sky),
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
        ),

        const SizedBox(height: 30),
      ],
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
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: IndexedStack(
        index: visibleIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: MainBottomNav(
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
      ),
    );
  }
}
