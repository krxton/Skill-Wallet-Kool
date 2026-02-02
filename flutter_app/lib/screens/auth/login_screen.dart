import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'package:skill_wallet_kool/providers/user_provider.dart';
import 'package:skill_wallet_kool/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false; // ✅ เพิ่ม local loading state

  static const cream = Color(0xFFFFF5CD);
  static const fbBlue = Color(0xFF1877F2);
  static const backPink = Color(0xFFEA5B6F);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Combine loading states
    final isLoading = _isLoading || authProvider.isLoading;

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
                      onTap: isLoading ? () {} : () => _handleFacebookSignIn(),
                    ),
                    const SizedBox(height: 16),

                    // ปุ่ม GOOGLE
                    _googleButton(
                      text: AppLocalizations.of(context)!.login_googleBtn,
                      onTap: isLoading ? () {} : () => _handleGoogleSignIn(),
                    ),

                    // Loading indicator
                    if (isLoading) ...[
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

            // BACK มุมซ้ายล่าง
            Positioned(
              left: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: isLoading ? null : () => Navigator.pop(context),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: isLoading ? Colors.grey : backPink,
                      size: 26,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.login_backBtn,
                      style: TextStyle(
                        fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                        fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                        fontSize: 24,
                        color: isLoading ? Colors.grey : backPink,
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

  // ========== Facebook Sign-In (เพิ่มใหม่ - ครบถ้วน) ==========
  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // เรียก Facebook Sign-In
      final success = await authProvider.signInWithFacebook();

      if (!success) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showMessage('การเข้าสู่ระบบด้วย Facebook ล้มเหลว');
        }
        return;
      }

      // รอให้ Supabase อัพเดท session
      await Future.delayed(const Duration(seconds: 1));

      // ดึงข้อมูล user
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // บันทึกหรืออัพเดทข้อมูลลง parent table
        await _syncUserData(
          userId: user.id,
          email: user.email,
          fullName: user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              user.email?.split('@')[0],
        );

        setState(() => _isLoading = false);

        // Navigate to home
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          _showMessage('ไม่พบข้อมูลผู้ใช้');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Facebook Sign-In error: $e');
      if (mounted) {
        _showMessage('เกิดข้อผิดพลาด: ${e.toString()}');
      }
    }
  }

  // ========== Google Sign-In (ปรับปรุง) ==========
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await _nativeGoogleSignIn();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Google Sign-In error: $e');
      if (mounted) {
        _showMessage('เกิดข้อผิดพลาด: ${e.toString()}');
      }
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    try {
      // 1. ตั้งค่า Google Sign-In
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

      // 2. Authenticate with Google
      final googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      // 3. Get full name from Google
      final String? fullName = googleUser.displayName;

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
              await googleUser.authorizationClient.authorizeScopes(scopes);

      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw const AuthException('No ID Token found.');
      }

      // 4. Sign in to Supabase
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      final user = response.user;
      if (user != null) {
        // 5. Sync user data to database
        final String nameToSave = fullName ?? user.email!.split('@')[0];
        await _syncUserData(
          userId: user.id,
          email: user.email,
          fullName: nameToSave,
        );

        setState(() => _isLoading = false);

        // 6. Navigate to home
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      rethrow;
    }
  }

  // ========== Helper: Sync User Data (ใหม่) ==========
  Future<void> _syncUserData({
    required String userId,
    required String? email,
    required String? fullName,
  }) async {
    final supabase = Supabase.instance.client;

    final String nameToSave = fullName ?? email?.split('@')[0] ?? 'User';

    try {
      // ตรวจสอบว่ามีข้อมูลอยู่แล้วหรือไม่
      final existingParent = await supabase
          .from('parent')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingParent == null) {
        // Insert new user
        await supabase.from('parent').insert({
          'user_id': userId,
          'email': email,
          'name_surname': nameToSave,
        });
        debugPrint('✅ New user created: $nameToSave');
      } else {
        // Update existing user
        await supabase.from('parent').update({
          'name_surname': nameToSave,
        }).eq('user_id', userId);
        debugPrint('✅ User data updated: $nameToSave');
      }

      // Update Provider
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        userProvider.setParentName(nameToSave);

        // 🆕 ดึงข้อมูล children เพื่อตั้งค่า childId
        await userProvider.fetchChildrenData();
      }
    } catch (e) {
      debugPrint('❌ Error syncing user data: $e');
      // Don't throw - allow user to continue even if sync fails
    }
  }

  // ========== Helper: Show Message ==========
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ========== UI Components ==========

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
