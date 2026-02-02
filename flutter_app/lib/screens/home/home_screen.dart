import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../../routes/app_routes.dart';
import '../../providers/user_provider.dart';
import '../../services/activity_service.dart';
import '../../models/activity.dart';

import '../../widgets/activity_card.dart';
import '../../widgets/scrollable_activity_list.dart';
import '../../widgets/main_bottom_nav.dart';
import '../profile/profile_screen.dart';
import '../post/create_post_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // COLORS
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const deepSky = Color(0xFF7DBEF1);

  // Filter states
  String? _selectedCategory; // null = ทั้งหมด, 'ด้านภาษา', 'ด้านร่างกาย', 'ด้านวิเคราะห์'
  String? _selectedLevel; // null = ทั้งหมด, 'ง่าย', 'กลาง', 'ยาก'

  final ActivityService _activityService = ActivityService();
  late Future<List<Activity>> _popularActivitiesFuture;
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

  // Fallback ไทยสำหรับตำแหน่งที่บังคับ Luckiest Guy
  final List<String> _thaiFallback = [GoogleFonts.itim().fontFamily!];

  // bottom nav: 0 = home, 1 = plus, 2 = profile
  int _selectedTab = 0;

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
        _popularActivitiesFuture = _activityService.fetchPopularActivities(
          childId,
          category: _selectedCategory,
          level: _selectedLevel,
        );
        _newActivitiesFuture = _activityService.fetchNewActivities(
          childId,
          category: _selectedCategory,
          level: _selectedLevel,
        );
      });
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
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(
              'กรุณาเลือกเด็ก',
              style: TextStyle(
                fontFamily: GoogleFonts.itim().fontFamily,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'คุณต้องเลือกเด็กก่อนจึงจะสามารถเล่นกิจกรรมได้',
          style: TextStyle(
            fontFamily: GoogleFonts.itim().fontFamily,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'ปิด',
              style: TextStyle(
                fontFamily: GoogleFonts.itim().fontFamily,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, AppRoutes.childSetting);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: sky,
            ),
            child: Text(
              'ไปเลือกเด็ก',
              style: TextStyle(
                fontFamily: GoogleFonts.itim().fontFamily,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 แสดง Filter Bottom Sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: cream,
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
                  Text(
                    'FILTER ACTIVITIES',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 20,
                      color: sky,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Filter
              Text(
                'CATEGORY',
                style: GoogleFonts.luckiestGuy(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  {'label': 'ทั้งหมด', 'value': null},
                  {'label': 'ภาษา', 'value': 'ด้านภาษา'},
                  {'label': 'ร่างกาย', 'value': 'ด้านร่างกาย'},
                  {'label': 'วิเคราะห์', 'value': 'ด้านวิเคราะห์'},
                ].map((cat) {
                  final isSelected = _selectedCategory == cat['value'];
                  return GestureDetector(
                    onTap: () {
                      _onCategoryFilterChanged(cat['value']);
                      setModalState(() {}); // Update modal UI
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? sky : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? sky : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        cat['label'] as String,
                        style: GoogleFonts.itim(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Level Filter
              Text(
                'LEVEL',
                style: GoogleFonts.luckiestGuy(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  {'label': 'ทั้งหมด', 'value': null},
                  {'label': 'ง่าย', 'value': 'ง่าย'},
                  {'label': 'กลาง', 'value': 'กลาง'},
                  {'label': 'ยาก', 'value': 'ยาก'},
                ].map((level) {
                  final isSelected = _selectedLevel == level['value'];
                  return GestureDetector(
                    onTap: () {
                      _onLevelFilterChanged(level['value']);
                      setModalState(() {}); // Update modal UI
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFB74D) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF9800) : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        level['label'] as String,
                        style: GoogleFonts.itim(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
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
      final videoId = _extractYouTubeVideoId(activity.videoUrl!);
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

        if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
          Navigator.pushNamed(
            context,
            AppRoutes.languageDetail,
            arguments: activity,
          );
        } else if (category == 'ด้านร่างกาย' && activity.videoUrl != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.videoDetail,
            arguments: activity,
          );
        } else if (category == 'ด้านวิเคราะห์') {
          Navigator.pushNamed(
            context,
            AppRoutes.analysisActivity,
            arguments: activity,
          );
        } else {
          Navigator.pushNamed(
            context,
            AppRoutes.itemIntro,
            arguments: activity,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailUrl != null)
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
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 20,
                        color: Colors.white,
                      ).copyWith(fontFamilyFallback: _thaiFallback),
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
                            color: sky,
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
                    color: Colors.orange,
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
                        'POPULAR',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 12,
                          color: Colors.white,
                        ).copyWith(fontFamilyFallback: _thaiFallback),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String category) {
    return Container(
      height: 100,
      width: double.infinity,
      color: deepSky,
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

  String? _extractYouTubeVideoId(String url) {
    if (url.isEmpty) return null;
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})'),
    ];
    for (var p in patterns) {
      final m = p.firstMatch(url);
      if (m != null && m.groupCount >= 1) return m.group(1);
    }
    if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }
    return null;
  }

  Widget _buildHomeBody(BuildContext context) {
    if (_currentChildId == null) {
      return const Center(
        child: CircularProgressIndicator(color: sky),
      );
    }

    final parentName = context.watch<UserProvider>().currentParentName;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search Bar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6D9DC),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Menu icon สำหรับเปิด Filter พร้อม badge
              GestureDetector(
                onTap: _showFilterBottomSheet,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.filter_list, color: Colors.black87, size: 24),
                    ),
                    // Badge แสดงว่ามี filter active
                    if (_selectedCategory != null || _selectedLevel != null)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9800),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ค้นหา',
                    hintStyle: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      color: Colors.black54,
                      fontSize: 16,
                      letterSpacing: .5,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.search, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Parent Name
        if (parentName != null && parentName.isNotEmpty)
          Text(
            parentName,
            style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              fontSize: 28,
              height: 1.0,
              color: sky,
            ),
          ),
        const SizedBox(height: 20),

        // Top Carousel
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sky, width: 3),
          ),
          child: FutureBuilder<List<Activity>>(
            future: _popularActivitiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: sky),
                );
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.home_cannotBtn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                        fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                        fontSize: 16,
                        color: Colors.black),
                  ),
                );
              }

              final topActivities = snapshot.data!.take(3).toList();

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
                                ? sky
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
              style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 20,
                  color: Colors.black),
            ),
            Text(
              AppLocalizations.of(context)!.home_viewallBtn,
              style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 16,
                  color: sky),
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
              style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 20,
                  color: Colors.black),
            ),
            Text(
              AppLocalizations.of(context)!.home_viewallBtn,
              style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 16,
                  color: sky),
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
      const ProfileScreen(),
    ];

    // ถ้าเลือก tab 2 ให้โชว์ index 1 (Profile) ไม่งั้นใช้ Home
    final int visibleIndex = _selectedTab == 2 ? 1 : 0;

    return Scaffold(
      backgroundColor: cream,
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
              // ✅ 2. แก้ไขให้กดแล้วเด้งหน้า CreatePostScreen ขึ้นมาแบบ Modal
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                  fullscreenDialog: true, // ตัวนี้แหละครับที่ทำให้เหมือน IG เด้งจากล่างขึ้นบน
                ),
              );
              return;
            }
            setState(() => _selectedTab = i);
          },
        ),
      ),
    );
  }
}