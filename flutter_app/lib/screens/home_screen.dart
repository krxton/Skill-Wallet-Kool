// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../providers/user_provider.dart';
import '../services/activity_service.dart';
import '../models/activity.dart'; // 🆕 Activity Model

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
  late Future<Activity?> _physicalActivityClipFuture;
  late Future<List<Activity>> _popularActivitiesFuture;

  String? _currentChildId;

  // 2. LIFECYCLE & DATA LOADING
  @override
  void initState() {
    super.initState();
    // ใช้งาน context หลัง build เพื่อดึงข้อมูลจาก Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (!mounted) return;

    // ดึง ID ผู้ใช้ (PR2/CH2) จาก Provider
    final childId = context.read<UserProvider>().currentChildId;

    if (childId != null) {
      setState(() {
        _currentChildId = childId;
        // 🆕 เริ่มดึงข้อมูลจาก Service จริง
        _physicalActivityClipFuture =
            _activityService.fetchPhysicalActivityClip(childId);
        _popularActivitiesFuture =
            _activityService.fetchPopularActivities(childId);
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

  // 🆕 Widget สำหรับแสดง Thumbnail และนำทางเมื่อกด
  Widget _buildTikTokThumbnail({
    required String thumbnailUrl,
    required String title,
    required String htmlContent,
  }) {
    return GestureDetector(
      onTap: () {
        // นำทางไปยัง VideoDetailScreen พร้อมส่ง Arguments
        Navigator.pushNamed(
          context,
          AppRoutes.videoDetail,
          arguments: {
            'htmlContent': htmlContent,
            'title': title,
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image,
                        size: 50, color: Colors.white),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'CLIP VDO: $title',
              style: GoogleFonts.luckiestGuy(fontSize: 16, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 Widget สำหรับการ์ดกิจกรรมย่อย
  Widget _activityCard(Activity activity) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock Image Placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: deepSky,
              alignment: Alignment.center,
              child: Text(activity.category.substring(0, 1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
                  style: GoogleFonts.luckiestGuy(
                      fontSize: 14, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Score: ${activity.maxScore}',
                  style: GoogleFonts.openSans(
                      fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. MAIN BUILD METHOD

  @override
  Widget build(BuildContext context) {
    // แสดง loading state หาก childId ยังเป็น null
    if (_currentChildId == null) {
      return const Scaffold(
        backgroundColor: cream,
        body: Center(child: CircularProgressIndicator(color: sky)),
      );
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
          // ... (Search Bar, Dropdown)

          // 1. CLIP VDO (FutureBuilder เพื่อดึงข้อมูล TikTok)
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: sky, width: 3),
            ),
            padding: const EdgeInsets.all(8),
            child: FutureBuilder<Activity?>(
              future: _physicalActivityClipFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: sky));
                }

                final activity = snapshot.data;

                // ตรวจสอบ Error และข้อมูลที่จำเป็น
                if (snapshot.hasError ||
                    activity == null ||
                    activity.thumbnailUrl == null ||
                    activity.tiktokHtmlContent == null) {
                  return Center(
                    child: Text(
                      'CLIP VDO\n(Error: Cannot load TikTok Clip or API Error: ${snapshot.error})',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 16, color: Colors.black87),
                    ),
                  );
                }

                // แสดง Thumbnail และเพิ่มฟังก์ชัน Tap
                return _buildTikTokThumbnail(
                  thumbnailUrl: activity.thumbnailUrl!,
                  title: activity.name,
                  htmlContent: activity.tiktokHtmlContent!,
                );
              },
            ),
          ),

          const SizedBox(height: 30),

          // 2. POPULAR ACTIVITIES (FutureBuilder เพื่อดึงข้อมูลกิจกรรมยอดนิยม)
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

          SizedBox(
            height: 180,
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
                      'Cannot load popular activities: ${snapshot.error}',
                      style: GoogleFonts.openSans(color: Colors.grey),
                    ),
                  );
                }

                final activities = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    return _activityCard(activities[index]);
                  },
                );
              },
            ),
          ),

          // ... (ส่วน NEW ACTIVITIES)
          const SizedBox(height: 30),
          Text('NEW ACTIVITIES',
              style:
                  GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.black)),
          const SizedBox(height: 12),
          Container(
              height: 180,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: deepSky, width: 2)),
              alignment: Alignment.center,
              child: Text('COMING SOON!',
                  style:
                      GoogleFonts.luckiestGuy(fontSize: 24, color: deepSky))),
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
