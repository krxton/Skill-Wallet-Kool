// lib/screens/home_screen.dart (ฉบับแก้ไข - รองรับ Drag Scrolling)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../providers/user_provider.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. COLORS AND STATE
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const deepSky = Color(0xFF7DBEF1);

  String _categoryValue = 'CATEGORY';

  final ActivityService _activityService = ActivityService();
  late Future<List<Activity>> _popularActivitiesFuture;
  late Future<List<Activity>> _newActivitiesFuture;

  String? _currentChildId;

  // สำหรับ Carousel
  final PageController _carouselController = PageController();
  int _currentCarouselPage = 0;

  // ScrollController สำหรับ Popular และ New Activities
  final ScrollController _popularScrollController = ScrollController();
  final ScrollController _newScrollController = ScrollController();

  // ตัวแปรสำหรับ Drag Scrolling
  double _popularDragStart = 0;
  double _newDragStart = 0;

  // 2. LIFECYCLE & DATA LOADING
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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

    final childId = context.read<UserProvider>().currentChildId;

    if (childId != null) {
      setState(() {
        _currentChildId = childId;
        _popularActivitiesFuture =
            _activityService.fetchPopularActivities(childId);
        _newActivitiesFuture = _activityService.fetchNewActivities(childId);
      });
    }
  }

  void _onCategoryChanged(String? value) {
    if (value == null) return;
    setState(() => _categoryValue = value);

    if (value.toUpperCase() == 'LANGUAGE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, AppRoutes.languageHub).then((_) {
          if (mounted) {
            setState(() => _categoryValue = 'CATEGORY');
          }
        });
      });
    }
  }

  // 3. WIDGET BUILDERS

  // 3.1 Widget สำหรับ Carousel Item (Popular Activities Top 3)
  Widget _buildCarouselItem({
    required Activity activity,
    required int totalItems,
  }) {
    final category = activity.category.toUpperCase();

    // ตรวจสอบประเภทกิจกรรม
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

    // Thumbnail URL
    String? thumbnailUrl;
    if (hasTikTokOEmbedData) {
      thumbnailUrl = activity.thumbnailUrl;
    } else if (hasYouTubeVideo && youtubeThumbnailUrl != null) {
      thumbnailUrl = youtubeThumbnailUrl;
    }

    return GestureDetector(
      // เพิ่ม Horizontal Drag
      onHorizontalDragEnd: (details) {
        // ตรวจสอบทิศทางการลาก
        if (details.primaryVelocity! > 0) {
          // ลากไปทางขวา = ย้อนกลับ (Previous)
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
          // ลากไปทางซ้าย = ถัดไป (Next)
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
        // Navigation Logic
        if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
          Navigator.pushNamed(context, AppRoutes.languageDetail,
              arguments: activity);
        } else if (category == 'ด้านร่างกาย' && activity.videoUrl != null) {
          Navigator.pushNamed(context, AppRoutes.videoDetail,
              arguments: activity);
        } else {
          Navigator.pushNamed(context, AppRoutes.itemIntro,
              arguments: activity);
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
              // Background Image/Thumbnail
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

              // Gradient Overlay
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

              // Text Content
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
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sky,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            activity.category,
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Score: ${activity.maxScore}',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Popular Badge
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
                      const Icon(Icons.local_fire_department,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'POPULAR',
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 12,
                          color: Colors.white,
                        ),
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

  // 3.2 Widget สำหรับ Activity Card (สำหรับ Popular และ New Activities List)
  Widget _activityCard(Activity activity) {
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

    final bool shouldGoToVideoDetail =
        category == 'ด้านร่างกาย' && activity.videoUrl != null;

    return GestureDetector(
      onTap: () {
        if (category == 'ด้านภาษา' || category == 'LANGUAGE') {
          Navigator.pushNamed(context, AppRoutes.languageDetail,
              arguments: activity);
        } else if (shouldGoToVideoDetail) {
          Navigator.pushNamed(context, AppRoutes.videoDetail,
              arguments: activity);
        } else {
          Navigator.pushNamed(context, AppRoutes.itemIntro,
              arguments: activity);
        }
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _buildActivityThumbnail(
                activity: activity,
                hasTikTokData: hasTikTokOEmbedData,
                hasYouTubeData: hasYouTubeVideo,
                youtubeThumbnailUrl: youtubeThumbnailUrl,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.name,
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 14, color: Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('Score: ${activity.maxScore}',
                      style: GoogleFonts.openSans(
                          fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityThumbnail({
    required Activity activity,
    required bool hasTikTokData,
    required bool hasYouTubeData,
    String? youtubeThumbnailUrl,
  }) {
    if (hasTikTokData) {
      return Image.network(
        activity.thumbnailUrl!,
        fit: BoxFit.cover,
        height: 100,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(activity.category);
        },
      );
    }

    if (hasYouTubeData && youtubeThumbnailUrl != null) {
      return Image.network(
        youtubeThumbnailUrl,
        fit: BoxFit.cover,
        height: 100,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(activity.category);
        },
      );
    }

    return _buildPlaceholder(activity.category);
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

    for (var pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }

    if (url.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }

    return null;
  }

  // 3.3 Widget สำหรับ Horizontal Scrollable List พร้อม Drag Scrolling
  Widget _buildScrollableActivityList({
    required Future<List<Activity>> future,
    required ScrollController controller,
    required String emptyMessage,
    required Function(double) onDragStart,
    required Function(double) onDragUpdate,
  }) {
    return FutureBuilder<List<Activity>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: sky),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: deepSky, width: 2)),
            alignment: Alignment.center,
            child: Text(
              emptyMessage,
              style: GoogleFonts.openSans(color: Colors.grey),
            ),
          );
        }

        final activities = snapshot.data!;

        return GestureDetector(
          onHorizontalDragStart: (details) {
            onDragStart(details.globalPosition.dx);
          },
          onHorizontalDragUpdate: (details) {
            onDragUpdate(details.globalPosition.dx);
          },
          child: SizedBox(
            height: 180,
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics:
                  const NeverScrollableScrollPhysics(), // ปิด scroll ธรรมดา
              child: Row(
                children: [
                  const SizedBox(width: 4), // padding ซ้าย
                  ...activities.map((activity) => _activityCard(activity)),
                  const SizedBox(width: 4), // padding ขวา
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 4. MAIN BUILD METHOD
  @override
  Widget build(BuildContext context) {
    if (_currentChildId == null) {
      return const Scaffold(
          backgroundColor: cream,
          body: Center(child: CircularProgressIndicator(color: sky)));
    }

    final String childId = _currentChildId!;

    return Scaffold(
      backgroundColor: cream,

      // 4.1 AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SWK - CHILD ID: $childId',
          style: GoogleFonts.luckiestGuy(fontSize: 24, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      // 4.2 Body
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // แถบค้นหาและ Dropdown
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sky, width: 2),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search activities...',
                      hintStyle: GoogleFonts.openSans(color: Colors.grey),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: sky),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: sky,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _categoryValue,
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: GoogleFonts.luckiestGuy(
                        fontSize: 16, color: Colors.white),
                    dropdownColor: sky,
                    items: <String>[
                      'CATEGORY',
                      'PHYSICAL',
                      'LANGUAGE',
                      'CREATIVE'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _onCategoryChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text('SWK', style: GoogleFonts.luckiestGuy(fontSize: 26, color: sky)),
          const SizedBox(height: 10),

          // 1. TOP POPULAR ACTIVITIES CAROUSEL
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
                      child: CircularProgressIndicator(color: sky));
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Cannot load popular activities',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 16, color: Colors.black87),
                    ),
                  );
                }

                // เอาแค่ 3 อันดับแรก
                final topActivities = snapshot.data!.take(3).toList();

                return Stack(
                  children: [
                    // PageView Carousel
                    PageView.builder(
                      controller: _carouselController,
                      itemCount: topActivities.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentCarouselPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildCarouselItem(
                          activity: topActivities[index],
                          totalItems: topActivities.length,
                        );
                      },
                    ),

                    // Page Indicator (Dots)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          topActivities.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentCarouselPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentCarouselPage == index
                                  ? sky
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Navigation Arrows with Infinite Loop
                    if (topActivities.length > 1) ...[
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: Colors.white, size: 32),
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
                            icon: const Icon(Icons.chevron_right,
                                color: Colors.white, size: 32),
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

          // 2. ALL POPULAR ACTIVITIES LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POPULAR ACTIVITIES',
                style:
                    GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.black),
              ),
              Text(
                'View All',
                style: GoogleFonts.openSans(
                    fontSize: 14, color: sky, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ ใช้ Widget ใหม่ที่มี Drag Scrolling
          _buildScrollableActivityList(
            future: _popularActivitiesFuture,
            controller: _popularScrollController,
            emptyMessage: 'Cannot load popular activities',
            onDragStart: (dx) {
              _popularDragStart = dx;
            },
            onDragUpdate: (dx) {
              final delta = _popularDragStart - dx;
              _popularDragStart = dx;
              _popularScrollController.jumpTo(
                _popularScrollController.offset + delta,
              );
            },
          ),

          // 3. NEW ACTIVITIES
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NEW ACTIVITIES',
                  style: GoogleFonts.luckiestGuy(
                      fontSize: 20, color: Colors.black)),
              Text(
                'View All',
                style: GoogleFonts.openSans(
                    fontSize: 14, color: sky, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ ใช้ Widget ใหม่ที่มี Drag Scrolling
          _buildScrollableActivityList(
            future: _newActivitiesFuture,
            controller: _newScrollController,
            emptyMessage: 'No new activities available',
            onDragStart: (dx) {
              _newDragStart = dx;
            },
            onDragUpdate: (dx) {
              final delta = _newDragStart - dx;
              _newDragStart = dx;
              _newScrollController.jumpTo(
                _newScrollController.offset + delta,
              );
            },
          ),

          const SizedBox(height: 30),
        ],
      ),

      // 4.3 Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 60,
        color: sky,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                icon: const Icon(Icons.home, color: cream), onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.star, color: cream), onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.book, color: cream), onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.person, color: cream), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class _BottomIcon extends StatelessWidget {
  final Color bg;
  final IconData icon;
  const _BottomIcon({required this.bg, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white),
    );
  }
}
