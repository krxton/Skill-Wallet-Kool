import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  static const orangeBtn = Color(0xFFFFCC80); 
  static const yellowBtn = Color(0xFFFFEE58); 
  static const pinkBtn = Color(0xFFFFAB91);   

  int _selectedTab = 0; 

  // 2. เปลี่ยนจาก File? เป็น Uint8List? (เหมือนฝั่งผู้ปกครอง)
  Uint8List? _selectedImageBytes; 

  // 3. ปรับฟังก์ชันเลือกรูปให้แปลงเป็น Bytes
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // ลดขนาดไฟล์รูปนิดหน่อยให้ลื่นขึ้น
        maxWidth: 800,
      );
      
      if (pickedFile != null) {
        // อ่านไฟล์เป็น Bytes
        final bytes = await pickedFile.readAsBytes();
        
        setState(() {
          _selectedImageBytes = bytes;
        });
        print("Image picked and converted to bytes successfully");
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

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
                          child: _buildProfileImage(),
                        ),
                      ),
                      
                      // ไอคอนกล้อง
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
                            ]
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.grey, size: 22),
                        ),
                      ),
                    ],
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

              // --- 4. Menu Tabs ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabIcon(index: 0, assetPath: 'assets/icons/gallery.png'),
                  const SizedBox(width: 60), 
                  _buildTabIcon(index: 1, assetPath: 'assets/icons/finish-line.png'),
                ],
              ),

              // --- เส้นแบ่ง ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Divider(
                  color: Colors.grey.withOpacity(0.4),
                  thickness: 1,
                ),
              ),

              const SizedBox(height: 20),

              // --- 5. Content Area ---
              _selectedTab == 0 
                  ? _buildGalleryView()    
                  : _buildGameListView(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. Logic การแสดงผลรูปภาพ (ใช้ Image.memory แทน Image.file) ---
  Widget _buildProfileImage() {
    // 4.1 ถ้ามีรูปที่เลือกใหม่ (Bytes) -> แสดงด้วย Image.memory
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: 160,
        height: 160,
      );
    }

    // 4.2 ถ้ายังไม่เลือก แต่มี URL จาก Server -> พยายามโหลด
    if (widget.imageUrl.isNotEmpty) {
      return Image.network(
        widget.imageUrl,
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

    // 4.3 Default
    return _buildDefaultProfileIcon();
  }

  // ไอคอนคนสีเทา (Default)
  Widget _buildDefaultProfileIcon() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      width: 160,
      height: 160,
      child: Icon(Icons.person, size: 80, color: Colors.grey.shade500),
    );
  }

  // ปุ่มเลือกแท็บ
  Widget _buildTabIcon({required int index, required String assetPath}) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        width: 70, height: 70,
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
          errorBuilder: (_,__,___) => const Icon(Icons.image, size: 40),
        ),
      ),
    );
  }

  Widget _buildGalleryView() {
    return Container(
      height: 300, 
      alignment: Alignment.center,
    );
  }

  Widget _buildGameListView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildGameButton("PING PONG GAME", Icons.sports_tennis, orangeBtn, () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityHistoryScreen(gameName: 'PING PONG GAME')));
          }),
          const SizedBox(height: 16),
          _buildGameButton("MATH GAME", Icons.calculate_outlined, yellowBtn, () {}),
          const SizedBox(height: 16),
          _buildGameButton("WORK OUT GAME", Icons.favorite, pinkBtn, () {}),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(0, 4), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black87, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.luckiestGuy(fontSize: 24, color: Colors.black87))),
            const Icon(Icons.chevron_right, size: 36, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}