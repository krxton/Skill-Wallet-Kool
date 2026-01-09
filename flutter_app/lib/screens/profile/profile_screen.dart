import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import 'settings/setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const cream = Color(0xFFFFF5CD);
  static const deepGrey = Color(0xFF000000);

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
    final parentName = userProvider.currentParentName ?? 'PARENT2';
    final profileImageBytes = userProvider.profileImageBytes; // ดึงรูปภาพ

    // final textTheme = Theme.of(context).textTheme; // ไม่ได้ใช้แล้ว

    return Container(
      color: cream,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
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
                          style: GoogleFonts.luckiestGuy(
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
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
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
            // ลบส่วนแสดงข้อความ "ยังไม่โพสต์กิจกรรม" ออกไปแล้ว
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
