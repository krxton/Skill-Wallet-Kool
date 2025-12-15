import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/main_bottom_nav.dart';
import 'activity_history_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  final String name;
  final String imageUrl;
  final int points;

  const ChildProfileScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.points,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  // --- Theme Colors ---
  static const creamBg = Color(0xFFFFF5CD);
  static const deepGrey = Color(0xFF000000);
  static const goldText = Color(0xFFFFC107);
  
  // Game Button Colors
  static const orangeBtn = Color(0xFFFFCC80); 
  static const yellowBtn = Color(0xFFFFEE58); 
  static const pinkBtn = Color(0xFFFFAB91);   

  // ** State สำหรับสลับหน้า **
  // 0 = Gallery (อัลบั้ม), 1 = Game List (รายการเกม)
  // แก้ไข: ตั้งค่าเริ่มต้นเป็น 0 เพื่อให้โชว์หน้า Gallery ก่อน
  int _selectedTab = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      
      bottomNavigationBar: SafeArea(
        child: MainBottomNav(
          selectedIndex: 2, 
          onTabSelected: (index) {
             if (index == 0) {
               Navigator.popUntil(context, (route) => route.isFirst);
             }
          },
        ),
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // --- 1. Profile Image (แก้ไขส่วนรูปคน) ---
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300, // พื้นหลังสีเทารอไว้ก่อน
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
                    // ตรวจสอบว่ามี URL รูปภาพมาไหม
                    child: widget.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            // ถ้ามี URL แต่โหลดไม่ติด (Net error) ให้โชว์ไอคอนคนสีเทาแทน
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultProfileIcon();
                            },
                          )
                        : _buildDefaultProfileIcon(), // ถ้าไม่มี URL เลย ให้โชว์ไอคอนคนสีเทา
                  ),
                ),
              ),
              
              const SizedBox(height: 10),

              // --- 2. Name ---
              Text(
                widget.name,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 42,
                  color: deepGrey,
                  letterSpacing: 1.2,
                ),
              ),

              // --- 3. Points ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/medal.png', 
                    width: 50, height: 50,
                    errorBuilder: (_,__,___) => const Icon(Icons.star, color: Colors.amber, size: 40),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.points}', 
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 40,
                      color: goldText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- 4. Menu Tabs (เลือก Gallery หรือ Finish Line) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tab 0: Gallery (อัลบั้ม)
                  _buildTabIcon(
                    index: 0, 
                    assetPath: 'assets/icons/gallery.png',
                  ),
                  
                  const SizedBox(width: 60), 
                  
                  // Tab 1: Finish Line (รายการเกม)
                  _buildTabIcon(
                    index: 1, 
                    assetPath: 'assets/icons/finish-line.png',
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- 5. Content Area (เปลี่ยนตามแท็บที่เลือก) ---
              _selectedTab == 0 
                  ? _buildGalleryView()    // ถ้าเลือก 0 โชว์หน้า Gallery (โพส)
                  : _buildGameListView(),  // ถ้าเลือก 1 โชว์หน้าเกม

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget: ไอคอนคนสีเทา (Default Profile) ---
  Widget _buildDefaultProfileIcon() {
    return Container(
      color: Colors.grey.shade300, // พื้นหลังเทาอ่อน
      alignment: Alignment.center,
      child: Icon(
        Icons.person, 
        size: 80, 
        color: Colors.grey.shade500 // ไอคอนคนสีเทาเข้ม
      ),
    );
  }

  // --- Widget: ปุ่มเลือกแท็บ ---
  Widget _buildTabIcon({required int index, required String assetPath}) {
    bool isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        width: 70, height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          // แสดงกรอบขาวจางๆ เมื่อถูกเลือก
          color: isSelected ? Colors.white.withOpacity(0.5) : Colors.transparent,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          // ถ้าไม่ได้เลือก ทำให้รูปจางลงนิดนึง
          color: isSelected ? null : Colors.white.withOpacity(0.6),
          colorBlendMode: isSelected ? null : BlendMode.modulate,
          errorBuilder: (_,__,___) => const Icon(Icons.image, size: 40),
        ),
      ),
    );
  }

  // --- View 1: หน้า Gallery ว่างๆ (โชว์เป็นหน้าแรก) ---
  Widget _buildGalleryView() {
    return Container(
      height: 300, 
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined, 
            size: 80, 
            color: Colors.grey.withOpacity(0.4)
          ),
          const SizedBox(height: 16),
          Text(
            "NO POSTS YET",
            style: GoogleFonts.luckiestGuy(
              fontSize: 24,
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // --- View 2: หน้า Game List ---
  Widget _buildGameListView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildGameButton(
            "PING PONG GAME", 
            Icons.sports_tennis, 
            orangeBtn,
            () {
               Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ActivityHistoryScreen(gameName: 'PING PONG GAME'))
              );
            }
          ),
          const SizedBox(height: 16),
          _buildGameButton(
            "MATH GAME", 
            Icons.calculate_outlined, 
            yellowBtn,
            () {}
          ),
          const SizedBox(height: 16),
          _buildGameButton(
            "WORK OUT GAME", 
            Icons.favorite, 
            pinkBtn,
            () {}
          ),
        ],
      ),
    );
  }

  Widget _buildGameButton(String title, IconData icon, Color color, VoidCallback onTap) {
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
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black87, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.luckiestGuy(
                  fontSize: 24,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 36, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}