import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/child_service.dart';
import 'activity_history_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  final String? childId; // ใช้สำหรับดึงข้อมูลเด็กคนนี้โดยเฉพาะ
  final String? name;
  final String? imageUrl;
  final int? points;

  const ChildProfileScreen({
    super.key,
    this.childId,
    this.name,
    this.imageUrl,
    this.points,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  // --- Theme Colors ---
  static const creamBg = Color(0xFFFFF5CD);
  static const deepGrey = Color(0xFF000000);
  static const goldText = Color(0xFFFFC107);
  static const orangeBtn = Color(0xFFFFCC80);
  static const yellowBtn = Color(0xFFFFEE58);
  static const pinkBtn = Color(0xFFFFAB91);
  static const sky = Color(0xFF87CEEB);

  int _selectedTab = 0;
  Uint8List? _selectedImageBytes;

  // Activity data
  final ChildService _childService = ChildService();
  List<Map<String, dynamic>> _activityHistory = [];
  Map<String, int> _categoryStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    // ใช้ childId ที่ส่งมา หรือถ้าไม่มีให้ใช้ currentChildId จาก Provider
    final userProvider = context.read<UserProvider>();
    final childId = widget.childId ?? userProvider.currentChildId;

    if (childId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final history = await _childService.getActivityHistory(childId);

      // Count activities by category
      Map<String, int> stats = {
        'ด้านภาษา': 0,
        'ด้านร่างกาย': 0,
        'ด้านคำนวณ': 0,
      };

      for (var record in history) {
        final category = record['activity']?['category'] as String?;
        if (category != null && stats.containsKey(category)) {
          stats[category] = (stats[category] ?? 0) + 1;
        }
      }

      setState(() {
        _activityHistory = history;
        _categoryStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading activity data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get real data from Provider
    final userProvider = context.watch<UserProvider>();
    final childName = widget.name ?? userProvider.currentChildName ?? 'ไม่ระบุชื่อ';
    final childWallet = widget.points ?? userProvider.currentChildWallet;
    final imageUrl = widget.imageUrl ?? '';

    return Scaffold(
      backgroundColor: creamBg,
      bottomNavigationBar: Container(
        color: const Color.fromARGB(255, 45, 163, 248), // salmon color
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 249, 216, 98), // yolk color - selected
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: sky))
            : RefreshIndicator(
                onRefresh: _loadActivityData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),

                      // --- 1. Profile Image ---
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade300,
                                  border: Border.all(color: Colors.white, width: 6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _buildProfileImage(imageUrl),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black12, blurRadius: 4)
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.grey, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- 2. Name ---
                      Text(
                        childName,
                        style: GoogleFonts.luckiestGuy(
                          fontSize: 36,
                          color: deepGrey,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // --- 3. Points ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/medal.png',
                            width: 50,
                            height: 50,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.star, color: Colors.amber, size: 40),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$childWallet',
                            style: GoogleFonts.luckiestGuy(
                              fontSize: 40,
                              color: goldText,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // --- 4. Menu Tabs ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTabIcon(
                              index: 0, assetPath: 'assets/icons/gallery.png'),
                          const SizedBox(width: 60),
                          _buildTabIcon(
                              index: 1, assetPath: 'assets/icons/finish-line.png'),
                        ],
                      ),

                      // --- Divider ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Divider(
                          color: Colors.grey.withOpacity(0.4),
                          thickness: 1,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- 5. Content Area ---
                      _selectedTab == 0 ? _buildStatsView() : _buildCategoryListView(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileImage(String imageUrl) {
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: 160,
        height: 160,
      );
    }

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 160,
        height: 160,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfileIcon();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: Colors.grey.shade300);
        },
      );
    }

    return _buildDefaultProfileIcon();
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      width: 160,
      height: 160,
      child: Icon(Icons.person, size: 80, color: Colors.grey.shade500),
    );
  }

  Widget _buildTabIcon({required int index, required String assetPath}) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isSelected ? Colors.white.withOpacity(0.5) : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          color: isSelected ? null : Colors.white.withOpacity(0.6),
          colorBlendMode: isSelected ? null : BlendMode.modulate,
          errorBuilder: (_, __, ___) => Icon(
            index == 0 ? Icons.bar_chart : Icons.emoji_events,
            size: 40,
            color: isSelected ? deepGrey : Colors.grey,
          ),
        ),
      ),
    );
  }

  // แสดงสถิติกิจกรรม
  Widget _buildStatsView() {
    final totalActivities = _activityHistory.length;

    if (totalActivities == 0) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีประวัติกิจกรรม',
              style: GoogleFonts.itim(
                fontSize: 20,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เริ่มเล่นกิจกรรมเพื่อดูสถิติที่นี่',
              style: GoogleFonts.itim(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Total activities card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'กิจกรรมทั้งหมด',
                  style: GoogleFonts.itim(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalActivities',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 48,
                    color: sky,
                  ),
                ),
                Text(
                  'ครั้ง',
                  style: GoogleFonts.itim(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Category breakdown
          Row(
            children: [
              _buildStatCard('ด้านภาษา', _categoryStats['ด้านภาษา'] ?? 0, yellowBtn, icon: Icons.abc),
              const SizedBox(width: 12),
              _buildStatCard('ด้านร่างกาย', _categoryStats['ด้านร่างกาย'] ?? 0, pinkBtn, icon: Icons.directions_run),
              const SizedBox(width: 12),
              _buildStatCard('ด้านคำนวณ', _categoryStats['ด้านคำนวณ'] ?? 0, orangeBtn, imagePath: 'assets/images/Analysis_img.jpg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, {IconData? icon, String? imagePath}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(imagePath, width: 32, height: 32, fit: BoxFit.cover),
              )
            else
              Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: GoogleFonts.luckiestGuy(
                fontSize: 24,
                color: Colors.black87,
              ),
            ),
            Text(
              title.replaceAll('ด้าน', ''),
              style: GoogleFonts.itim(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // แสดงรายการหมวดหมู่กิจกรรม
  Widget _buildCategoryListView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildCategoryButton(
            "ด้านภาษา",
            yellowBtn,
            _categoryStats['ด้านภาษา'] ?? 0,
            () => _navigateToHistory('ด้านภาษา'),
            icon: Icons.abc,
          ),
          const SizedBox(height: 16),
          _buildCategoryButton(
            "ด้านร่างกาย",
            pinkBtn,
            _categoryStats['ด้านร่างกาย'] ?? 0,
            () => _navigateToHistory('ด้านร่างกาย'),
            icon: Icons.directions_run,
          ),
          const SizedBox(height: 16),
          _buildCategoryButton(
            "ด้านคำนวณ",
            orangeBtn,
            _categoryStats['ด้านคำนวณ'] ?? 0,
            () => _navigateToHistory('ด้านคำนวณ'),
            imagePath: 'assets/images/Analysis_img.jpg',
          ),
        ],
      ),
    );
  }

  void _navigateToHistory(String category) {
    // ใช้ childId ที่ส่งมา หรือ currentChildId จาก Provider
    final userProvider = context.read<UserProvider>();
    final childId = widget.childId ?? userProvider.currentChildId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityHistoryScreen(
          gameName: category,
          childId: childId,
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    String title,
    Color color,
    int count,
    VoidCallback onTap, {
    IconData? icon,
    String? imagePath,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 6,
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: imagePath != null
                  ? ClipOval(
                      child: Image.asset(imagePath, width: 50, height: 50, fit: BoxFit.cover),
                    )
                  : Icon(icon, color: Colors.black87, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.itim(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count ครั้ง',
                style: GoogleFonts.itim(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 36, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
