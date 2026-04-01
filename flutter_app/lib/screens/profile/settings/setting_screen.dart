import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'package:skill_wallet_kool/main.dart';
import 'package:skill_wallet_kool/routes/app_routes.dart';

// Import Provider
import '../../../providers/user_provider.dart';
import '../../../services/api_service.dart';

// Import หน้าย่อยต่างๆ
import 'profile_setting_screen.dart'; // หน้าแก้ไขโปรไฟล์
import '../../child/child_setting_screen.dart'; // หน้าจัดการเด็ก

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // สี Theme ตามดีไซน์
  static const cream = Color(0xFFFFF5CD);
  static const pinkRed = Color(0xFFFF8E8E);
  static const blueTitle = Color(0xFF4DA9FF);
  static const textGrey = Color(0xFF8E8E8E);
  static const buttonYellow = Color(0xFFF6CE78); // สีเหลืองของปุ่มภาษา

  // ตัวแปรเก็บค่าภาษาที่เลือก (Default เป็น 'TH')
  String _selectedLanguage = 'TH';

  @override
  Widget build(BuildContext context) {
    final photoUrl = context.watch<UserProvider>().parentPhotoUrl;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            // --- Scrollable content ---
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- 1. Header (Back & Title) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back,
                                    size: 28, color: Colors.black87),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.setting_backBtn,
                                  style: TextStyle(
                                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                                      fontSize: 24,
                                      color: pinkRed),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.setting_settingBtn,
                            style: TextStyle(
                                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                                fontSize: 24,
                                color: blueTitle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // --- 2. Menu: PROFILE ---
                      _buildMenuItem(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileSettingScreen(),
                            ),
                          );
                        },
                        title: AppLocalizations.of(context)!.setting_profileBtn,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            image: photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 30, color: Colors.black87)
                              : null,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- Section: Personal Information ---
                      Text(
                        AppLocalizations.of(context)!.setting_personalBtn,
                        style: TextStyle(
                          fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                          fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                          fontSize: 20,
                          color: textGrey,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Menu: CHILD
                      _buildMenuItem(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChildSettingScreen(),
                            ),
                          );
                        },
                        title: AppLocalizations.of(context)!.setting_childBtn,
                        leading: const Icon(Icons.sentiment_satisfied_alt,
                            size: 32, color: Colors.black87),
                      ),

                      const SizedBox(height: 20),

                      // --- Language Buttons ---
                      _buildLanguageButton(
                        code: 'th',
                        label: AppLocalizations.of(context)!.setting_thaiBtn,
                        flagEmoji: '🇹🇭',
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageButton(
                        code: 'en',
                        label: AppLocalizations.of(context)!.setting_englishBtn,
                        flagEmoji: '🇺🇸',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // --- Sticky Bottom: Logout + Delete Account ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Log Out Button
                  GestureDetector(
                    onTap: _confirmLogout,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.setting_logoutBtn,
                          style: TextStyle(
                              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                              fontSize: 24,
                              color: pinkRed),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.logout, color: Colors.black87, size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delete Account
                  GestureDetector(
                    onTap: _confirmDeleteAccount,
                    child: Text(
                      AppLocalizations.of(context)!.setting_deleteAccountBtn,
                      style: TextStyle(
                        fontFamily: GoogleFonts.itim().fontFamily,
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.setting_logoutTitle,
          style: GoogleFonts.itim(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.setting_logoutMsg,
          style: GoogleFonts.itim(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel,
                style: GoogleFonts.itim(fontSize: 14, color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: pinkRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.setting_logoutConfirm,
                style: GoogleFonts.itim(fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    if (!mounted) return;
    context.read<UserProvider>().clearUserData();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.welcome,
        (route) => false,
      );
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.setting_deleteTitle,
          style: GoogleFonts.itim(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          l10n.setting_deleteMsg,
          style: GoogleFonts.itim(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel,
                style: GoogleFonts.itim(fontSize: 14, color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.setting_deleteConfirm,
                style: GoogleFonts.itim(fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // 1. Call backend to delete parent + children data
      final apiService = ApiService();
      await apiService.delete('/parents/me');

      // 2. Delete Supabase auth user
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}

      // 3. Clear local state
      if (!mounted) return;
      context.read<UserProvider>().clearUserData();

      // 4. Navigate to welcome
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.setting_deleteSuccess)),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.setting_deleteError)),
        );
      }
    }
  }

  // Helper Widget: สร้างแถวเมนู (Profile, Child, Noti)
  Widget _buildMenuItem({
    required String title,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // จัดให้ leading (icon/image) อยู่ตรงกลางของความกว้าง 50 เพื่อความเป็นระเบียบ
            SizedBox(
              width: 50,
              child: Center(child: leading),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 32, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  // Helper Widget: สร้างปุ่มเปลี่ยนภาษา
  Widget _buildLanguageButton({
    required String code,
    required String label,
    required String flagEmoji,
  }) {
    // ตรวจสอบว่าปุ่มนี้ถูกเลือกอยู่หรือไม่
    bool isActive = _selectedLanguage == code;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });

        if (code == 'th') {
          SWKApp.of(context)?.setLocale(const Locale('th'));
        } else if (code == 'en') {
          SWKApp.of(context)?.setLocale(const Locale('en'));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // เอฟเฟกต์เปลี่ยนสีนุ่มๆ
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          // Logic ความสว่าง:
          // ถ้าเลือก (Active) -> สีชัด (Opacity 1.0)
          // ถ้าไม่เลือก -> สีจาง (Opacity 0.4)
          color: isActive ? buttonYellow : buttonYellow.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                fontSize: 22,
                // ถ้าไม่ Active ให้ตัวหนังสือจางลงด้วยนิดหน่อย เพื่อความสวยงาม
                color: isActive ? Colors.black87 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
