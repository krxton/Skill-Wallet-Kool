import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'child_name_setting_screen.dart'; 
import 'medals_redemption_screen.dart'; 

class ManageChildScreen extends StatefulWidget {
  final String name;
  final String imageUrl;
  final int score; // ✅ 1. เพิ่มตัวแปรรับคะแนน

  const ManageChildScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.score, // ✅ 2. บังคับรับค่า
  });

  @override
  State<ManageChildScreen> createState() => _ManageChildScreenState();
}

class _ManageChildScreenState extends State<ManageChildScreen> {
  // ... (ส่วนตัวแปรอื่น ๆ เหมือนเดิม) ...
  late String _currentName;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  
  static const cream = Color(0xFFFFF5CD);
  static const deepGrey = Color(0xFF000000);
  static const deleteRed = Color(0xFFFF6B6B);
  static const labelGrey = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _currentName = widget.name;
  }
  
  // ... (ฟังก์ชัน _pickImage, _navigateToEditName, _showDeleteConfirmationDialog เหมือนเดิม) ...
  // เพื่อประหยัดพื้นที่ ผมขอละไว้ในฐานที่เข้าใจ ถ้าไม่ได้แก้ logic อะไร

  Future<void> _pickImage() async { /* ... */ }
  Future<void> _navigateToEditName() async { /* ... */ }
  Future<void> _showDeleteConfirmationDialog() async { /* ... */ }

  @override
  Widget build(BuildContext context) {
    // Logic การแสดงผลรูปภาพเหมือนเดิม...
    Widget profileImageWidget;
    if (_imageBytes != null) {
      profileImageWidget = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (widget.imageUrl.isNotEmpty) {
      profileImageWidget = Image.network(widget.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, size: 80, color: Colors.grey));
    } else {
      profileImageWidget = const Icon(Icons.person, size: 80, color: Colors.grey);
    }

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            // ... (Header ส่วนบนเหมือนเดิม) ...
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, { 
                        'newName': _currentName,
                        'newImageBytes': _imageBytes 
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.transparent,
                      child: const Icon(Icons.arrow_back, size: 30, color: Colors.black87),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'MANAGE PROFILE',
                    style: GoogleFonts.luckiestGuy(fontSize: 24, color: Colors.black87),
                  ),
                  const Spacer(),
                  const SizedBox(width: 46),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // ... (ส่วนรูปภาพ Profile เหมือนเดิม) ...
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: Colors.white, width: 4), 
                        color: Colors.grey.shade300
                      ),
                      child: ClipOval(child: profileImageWidget),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107), 
                          shape: BoxShape.circle, 
                          border: Border.all(color: cream, width: 2)
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.black87, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // --- เมนูแก้ไข ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... (ส่วนแก้ไขชื่อ Name เหมือนเดิม) ...
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToEditName,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NAME', style: GoogleFonts.luckiestGuy(fontSize: 16, color: labelGrey)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_currentName, style: GoogleFonts.luckiestGuy(fontSize: 24, color: deepGrey)),
                                  const Icon(Icons.chevron_right, size: 32, color: deepGrey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.black12),
                    
                    // ✅ แก้ไขส่วนปุ่มไปหน้า Medals ให้ส่งคะแนนไปด้วย
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // 🚀 นำทางไปหน้า Medals พร้อมส่งคะแนนจริง
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedalsRedemptionScreen(
                                score: widget.score, // ส่งค่าคะแนนไปที่นี่!
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Color(0xFFFFC107), size: 30),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'MEDALS & REDEMPTION', 
                                  style: GoogleFonts.luckiestGuy(fontSize: 20, color: deepGrey)
                                )
                              ),
                              const Icon(Icons.chevron_right, size: 32, color: deepGrey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ... (ปุ่มลบ Delete Profile เหมือนเดิม) ...
             Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: TextButton(
                onPressed: _showDeleteConfirmationDialog,
                child: Text('DELETE PROFILE', style: GoogleFonts.luckiestGuy(fontSize: 20, color: deleteRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}