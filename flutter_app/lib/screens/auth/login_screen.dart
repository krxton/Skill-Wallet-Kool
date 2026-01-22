import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart'; // ✅ เพิ่ม
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'package:skill_wallet_kool/providers/user_provider.dart';
import 'package:skill_wallet_kool/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart'; // ✅ เพิ่ม

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const cream = Color(0xFFFFF5CD);
  static const fbBlue = Color(0xFF1877F2);
  static const backPink = Color(0xFFEA5B6F);

  @override
  Widget build(BuildContext context) {
    // ✅ เพิ่ม: ดึง AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/SWK_home.png', height: 240),
                    const SizedBox(height: 32),

                    // ปุ่ม FACEBOOK
                    _loginButton(
                      icon: Icons.facebook,
                      text: AppLocalizations.of(context)!.login_facebookBtn,
                      color: fbBlue,
                      onTap:
                          authProvider.isLoading // ✅ เพิ่ม: disable ถ้า loading
                              ? () {}
                              : () async {
                                  // ✅ เพิ่ม: เรียก Facebook login
                                  final success =
                                      await authProvider.signInWithFacebook();
                                  if (success && context.mounted) {
                                    // รอ callback จาก deep link
                                    // จะถูกจัดการใน main.dart
                                  }
                                },
                    ),
                    const SizedBox(height: 16),

                    // ปุ่ม GOOGLE
                    _googleButton(
                      text: AppLocalizations.of(context)!.login_googleBtn,
                      onTap:
                          authProvider.isLoading // ✅ เพิ่ม: disable ถ้า loading
                              ? () {}
                              : () async {
                                  await _nativeGoogleSignIn(
                                    context,
                                  );
                                },
                    ),

                    // ✅ เพิ่ม: แสดง loading indicator
                    if (authProvider.isLoading) ...[
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'กำลังเข้าสู่ระบบ...',
                        style: GoogleFonts.itim(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // BACK มุมซ้ายล่าง (UI เดิม)
            Positioned(
              left: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, color: backPink, size: 26),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.login_backBtn,
                      style: TextStyle(
                        fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                        fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                        fontSize: 24,
                        color: backPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _nativeGoogleSignIn(
    BuildContext context,
  ) async {
    const webClientId =
        '286775717840-494vogfnb2oclk746pgqu83o66sm7qsc.apps.googleusercontent.com';
    const iosClientId =
        '286775717840-etqs6h74ku98274lcb03be4hmoj12s7u.apps.googleusercontent.com';

    final scopes = ['email', 'profile'];
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(
      serverClientId: webClientId,
      clientId: iosClientId,
    );

    final googleUser = await googleSignIn.authenticate();

    if (googleUser == null) return;

    // ✅ 1. ดึงชื่อจริง (DisplayName) จาก Google ไว้ก่อน
    final String? fullName = googleUser.displayName;

    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
            await googleUser.authorizationClient.authorizeScopes(scopes);

    final idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw const AuthException('No ID Token found.');
    }

    final supabase = Supabase.instance.client;

    // ✅ 2. ประกาศตัวแปร response มารับค่าจากการ SignIn
    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );

    final user = response.user;
    if (user != null) {
      final String nameToSave = fullName ?? user.email!.split('@')[0];

      try {
        // ✅ เปลี่ยนจาก upsert มาใช้การตรวจสอบก่อน
        final existingParent = await supabase
            .from('parent')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (existingParent == null) {
          // ถ้ายังไม่มีข้อมูล ให้ Insert
          await supabase.from('parent').insert({
            'user_id': user.id,
            'email': user.email,
            'name_surname': nameToSave,
          });
        } else {
          // ถ้ามีแล้ว ให้ Update ชื่อล่าสุดจาก Google
          await supabase.from('parent').update({
            'name_surname': nameToSave,
          }).eq('user_id', user.id);
        }

        if (context.mounted) {
          context.read<UserProvider>().setParentName(nameToSave);
        }
      } catch (e) {
        debugPrint('Error syncing parent data during login: $e');
      }
    }

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false, // เปลี่ยนเป็น false เพื่อเคลียร์ stack ทั้งหมด
      );
    }
  }

  // UI เดิม - ไม่เปลี่ยน
  Widget _loginButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI เดิม - ไม่เปลี่ยน
  Widget _googleButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  'G',
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 22,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
