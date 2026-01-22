import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ 1. เพิ่ม Supabase
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../../providers/user_provider.dart';
import 'settings/setting_screen.dart';
import '../post/post_detail_screen.dart'; // ✅ 2. Import หน้าดูรายละเอียดโพสต์ (ตรวจสอบ path ให้ถูกต้อง)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const cream = Color(0xFFFFF5CD);
  static const deepGrey = Color(0xFF000000);

  // ✅ 3. เพิ่มตัวแปร Stream สำหรับดึงโพสต์แบบ Realtime
  final _postsStream = Supabase.instance.client
      .from('posts')
      .stream(primaryKey: ['id'])
      .eq('user_id', Supabase.instance.client.auth.currentUser?.id ?? '') // ดึงเฉพาะของ user นี้
      .order('created_at', ascending: false); // เรียงจากใหม่ไปเก่า

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      if (!mounted) return;
      // ส่งรูปไปเก็บใน Provider เพื่อให้หน้า Setting เอาไปใช้ได้
      context.read<UserProvider>().setProfileImage(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลจาก Provider มาเฝ้าดู (Watch)
    final userProvider = context.watch<UserProvider>();
    final parentName = userProvider.currentParentName ?? 'PARENT';
    final profileImageBytes = userProvider.profileImageBytes; // ดึงรูปภาพ

    return Container(
      color: cream,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            // --- ส่วน Header (รูปโปรไฟล์ + ชื่อ + ปุ่ม Setting) ---
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
                            // ตรวจสอบว่ามีรูปไหม ถ้ามีแสดงรูป ถ้าไม่มีแสดงไอคอน
                            child: profileImageBytes == null
                                ? const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.black87,
                                  )
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
                        Text(
                          parentName,
                          style: TextStyle(
                            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                            fontFamilyFallback: [
                              GoogleFonts.itim().fontFamily!
                            ],
                            fontSize: 24,
                            color: deepGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings,
                        size: 28,
                      ),
                      onPressed: () {
                        // กดปุ่มนี้เพื่อไปหน้า Setting
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
            
            // --- ส่วนหัวข้อ Grid View ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.parentprofile_postBtn,
                        style: TextStyle(
                            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                            fontFamilyFallback: [
                              GoogleFonts.itim().fontFamily!
                            ],
                            fontSize: 18,
                            color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(thickness: 1),
                ],
              ),
            ),

            // ✅ 4. เพิ่ม Expanded เพื่อแสดงรูปจาก Supabase ให้เต็มพื้นที่ที่เหลือ
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _postsStream,
                builder: (context, snapshot) {
                  // สถานะโหลด
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // สถานะ Error หรือ ไม่มีข้อมูล
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading posts'));
                  }
                  
                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, 
                               size: 48, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          Text(
                            'No posts yet',
                            style: GoogleFonts.itim(
                              color: Colors.grey, 
                              fontSize: 16
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // แสดงผลแบบตาราง (Grid)
                  return GridView.builder(
                    padding: const EdgeInsets.all(2), // เว้นขอบนิดหน่อย
                    itemCount: posts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 รูปต่อแถว
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1.0, // สี่เหลี่ยมจัตุรัส
                    ),
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return GestureDetector(
                        onTap: () {
                          // ✅ 5. กดแล้วไปหน้า PostDetailScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(postData: post),
                            ),
                          );
                        },
                        child: Image.network(
                          post['image_url'],
                          fit: BoxFit.cover,
                          // โหลดรูปไม่ผ่านให้โชว์สีเทา
                          errorBuilder: (context, error, stack) => 
                              Container(color: Colors.grey[300]),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(color: Colors.grey[200]);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}