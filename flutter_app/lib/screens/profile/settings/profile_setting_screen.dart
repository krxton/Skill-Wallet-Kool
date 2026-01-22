import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import 'name_setting_screen.dart';

class ProfileSettingScreen extends StatefulWidget {
  const ProfileSettingScreen({super.key});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  static const cream = Color(0xFFFFF5CD);
  static const pinkRed = Color(0xFFEA5B6F);
  static const textGrey = Color(0xFF8E8E8E);
  static const yellowBadge = Color(0xFFFFD54F);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      context.read<UserProvider>().setProfileImage(bytes);
    }
  }

  // --- ฟังก์ชันแสดง Popup ยืนยันการลบบัญชี ---
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocalizations.of(context)!.profileSet_deleteDialogTitle,
            style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              fontSize: 24,
              color: pinkRed,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            AppLocalizations.of(context)!.profilesetting_areusureBtn,
            style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            // ปุ่ม CANCEL
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppLocalizations.of(context)!.profilesetting_cancelBtn,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ปุ่ม DELETE
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // ปิด Dialog ก่อน
                _performDeleteAccount(); // เรียกฟังก์ชันลบ
              },
              child: Text(
                AppLocalizations.of(context)!.profilesetting_deleteBtn,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 18,
                  color: pinkRed,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- ฟังก์ชันทำงานเมื่อยืนยันการลบ ---
  void _performDeleteAccount() {
    // 1. เรียก Provider ให้ล้างข้อมูล
    context.read<UserProvider>().clearUserData();

    // 2. ดีดกลับไปหน้า Welcome (หรือ Login) และลบประวัติการเปิดหน้าทั้งหมดทิ้ง
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.welcome,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profileImageBytes = userProvider.profileImageBytes;
    final parentName = userProvider.currentParentName ?? 'SWK';

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back,
                  size: 32,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // --- Profile Image ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade300,
                          image: profileImageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(profileImageBytes),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profileImageBytes == null
                            ? const Icon(Icons.person,
                                size: 80, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: yellowBadge,
                            shape: BoxShape.circle,
                            border: Border.all(color: cream, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 24,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Name Label ---
              Text(
                AppLocalizations.of(context)!.profilesetting_nameBtn,
                style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 20,
                    color: textGrey),
              ),

              const SizedBox(height: 12),

              // --- Name Value (Click to Edit) ---
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NameSettingScreen(),
                    ),
                  );
                },
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        parentName,
                        style: TextStyle(
                          fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                          fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                          fontSize: 24,
                          color: Colors.black87,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 32,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- Delete Account Button ---
              GestureDetector(
                onTap: () {
                  _showDeleteConfirmation(context);
                },
                child: Text(
                  AppLocalizations.of(context)!.profilesetting_deleteaccoutBtn,
                  style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 20,
                      color: pinkRed),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
