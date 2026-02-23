import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'package:skill_wallet_kool/providers/user_provider.dart';
import 'package:skill_wallet_kool/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../child/add_child_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _waitingForOAuth = false;
  bool _agreedToTerms = false;

  static const cream = Color(0xFFFFF5CD);
  static const fbBlue = Color(0xFF1877F2);
  static const sky = Color(0xFF0D92F4);

  static const _privacyPolicyUrl =
      'https://krxton.github.io/Skill-Wallet-Kool/privacy-policy.html';
  static const _termsOfServiceUrl =
      'https://krxton.github.io/Skill-Wallet-Kool/terms-of-service.html';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForOAuth) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isLoading && _waitingForOAuth) {
          setState(() {
            _isLoading = false;
            _waitingForOAuth = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = _isLoading || authProvider.isLoading;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main layout (ปุ่มอยู่เดิมเสมอ) ──
            Column(
              children: [
                // Logo
                Expanded(
                  flex: 2,
                  child: Center(
                    child:
                        Image.asset('assets/images/SWK_home.png', height: 260),
                  ),
                ),

                // OAuth buttons
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _oauthButton(
                            icon: Icons.email_outlined,
                            text: l10n.email_loginWithEmail,
                            color: Colors.grey.shade700,
                            onTap: isLoading
                                ? () {}
                                : () => Navigator.pushNamed(
                                    context, AppRoutes.emailLogin),
                          ),
                          const SizedBox(height: 12),
                          _oauthButton(
                            icon: Icons.facebook,
                            text: l10n.login_facebookBtn,
                            color: fbBlue,
                            onTap: isLoading
                                ? () {}
                                : () => _handleOAuth('facebook'),
                          ),
                          const SizedBox(height: 12),
                          _googleButton(
                            text: l10n.login_googleBtn,
                            onTap: isLoading
                                ? () {}
                                : () => _handleOAuth('google'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Terms
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                  child: _buildTermsCheckbox(l10n),
                ),
              ],
            ),

            // ── Loading overlay (ลอยอยู่บนทุกอย่าง) ──
            if (isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          l10n.auth_loading,
                          style: GoogleFonts.itim(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========== Terms Checkbox ==========
  Widget _buildTermsCheckbox(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              activeColor: sky,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.itim(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(text: l10n.auth_termsAgree),
                  TextSpan(text: ' '),
                  TextSpan(
                    text: l10n.auth_termsOfService,
                    style: GoogleFonts.itim(
                      fontSize: 14,
                      color: sky,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openUrl(_termsOfServiceUrl),
                  ),
                  TextSpan(text: ' ${l10n.auth_and} '),
                  TextSpan(
                    text: l10n.auth_privacyPolicy,
                    style: GoogleFonts.itim(
                      fontSize: 14,
                      color: sky,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openUrl(_privacyPolicyUrl),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ========== OAuth Entry Point ==========
  void _handleOAuth(String provider) {
    if (!_agreedToTerms) {
      _showTermsDialog(provider);
      return;
    }
    if (provider == 'facebook') {
      _handleFacebookSignIn();
    } else {
      _handleGoogleSignIn();
    }
  }

  Future<void> _showTermsDialog(String provider) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          l10n.auth_tosDialogMsg,
          style: GoogleFonts.itim(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openUrl(_termsOfServiceUrl);
            },
            child: Text(
              l10n.auth_readTos,
              style: GoogleFonts.itim(fontSize: 14, color: sky),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _agreedToTerms = true);
              if (provider == 'facebook') {
                _handleFacebookSignIn();
              } else {
                _handleGoogleSignIn();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: sky),
            child: Text(
              l10n.auth_enter,
              style: GoogleFonts.itim(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ========== Facebook Sign-In via Supabase OAuth ==========
  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['public_profile', 'email'],
          loginTracking: LoginTracking.enabled);

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.tokenString;
        final response = await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.facebook,
          idToken: accessToken,
        );

        final user = response.user;
        if (user != null) {
          await _handlePostOAuth(
              userId: user.id,
              email: user.email,
              fullName: user.userMetadata?['full_name'] ??
                  user.userMetadata?['name'] ??
                  user.email?.split('@')[0]);
        }
      } else {
        // Handle login cancellation or failure
        setState(() => _isLoading = false);
        debugPrint('Facebook Sign-In error: ${result.status}');
        if (mounted) {
          _showMessage(AppLocalizations.of(context)!
              .common_errorGeneric(result.status.toString()));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Facebook Sign-In error: $e');
      if (mounted) {
        _showMessage(
            AppLocalizations.of(context)!.common_errorGeneric(e.toString()));
      }
    }
  }

  // ========== Google Sign-In ==========
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await _nativeGoogleSignIn();
    } on GoogleSignInException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In cancelled by user');
        return;
      }
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        _showMessage(
            AppLocalizations.of(context)!.common_errorGeneric(e.toString()));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Google Sign-In error: $e');
      if (mounted) {
        _showMessage(
            AppLocalizations.of(context)!.common_errorGeneric(e.toString()));
      }
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    try {
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
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final String? fullName = googleUser.displayName;

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
              await googleUser.authorizationClient.authorizeScopes(scopes);

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('No ID Token found.');
      }

      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );

      final user = response.user;
      if (user != null) {
        await _handlePostOAuth(
          userId: user.id,
          email: user.email,
          fullName: fullName ?? user.email?.split('@')[0],
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      rethrow;
    }
  }

  // ========== Post-OAuth: Auto-detect Login vs Register ==========
  Future<void> _handlePostOAuth({
    required String userId,
    required String? email,
    required String? fullName,
  }) async {
    final hasAccount = await _checkParentExists();

    if (hasAccount) {
      // Existing user → sync + go home
      await _syncUserData(email: email, fullName: fullName);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    } else {
      // New user → save + go to children info
      await _saveUserToDatabase(
        userId: userId,
        email: email,
        fullName: fullName,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const AddChildScreen(isRequired: true)),
          (route) => false,
        );
      }
    }
  }

  // ========== Helpers ==========
  Future<bool> _checkParentExists() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final result = await supabase
          .from('parent')
          .select('parent_id')
          .eq('user_id', user.id)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('Check parent error: $e');
      return false;
    }
  }

  Future<void> _syncUserData({
    required String? email,
    required String? fullName,
  }) async {
    final String nameToSave = fullName ?? email?.split('@')[0] ?? 'User';

    try {
      final apiService = ApiService();
      final result = await apiService.post('/parents/sync', {
        'email': email,
        'fullName': nameToSave,
      });

      final parentName = result['parent']?['nameSurname'] ?? nameToSave;
      final parentId = result['parent']?['parentId']?.toString();
      debugPrint('User synced via API: $parentName (id: $parentId)');

      if (mounted) {
        final userProvider = context.read<UserProvider>();
        userProvider.setParentName(parentName);
        if (parentId != null) userProvider.setParentId(parentId);
        unawaited(userProvider.fetchChildrenData());
      }
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    }
  }

  Future<void> _saveUserToDatabase({
    required String userId,
    required String? email,
    required String? fullName,
  }) async {
    final String nameToSave = fullName ?? email?.split('@')[0] ?? 'User';

    try {
      final apiService = ApiService();
      final result = await apiService.post('/parents/sync', {
        'email': email,
        'fullName': nameToSave,
      });

      final parentName = result['parent']?['nameSurname'] ?? nameToSave;
      debugPrint('User saved via API: $parentName');

      if (mounted) {
        context.read<UserProvider>().setParentName(parentName);
      }
    } catch (e) {
      debugPrint('Error saving user to database: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // ========== UI Components ==========
  Widget _oauthButton({
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
                child: const _GoogleLogoIcon(size: 26),
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

// ─── Google "G" Logo ───────────────────────────────────────────────────────

class _GoogleLogoIcon extends StatelessWidget {
  final double size;
  const _GoogleLogoIcon({this.size = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sw = size.width * 0.22;
    final arcR = size.width / 2 - sw / 2;

    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    double rad(double deg) => deg * math.pi / 180;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: arcR);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.butt;

    // Blue: -10° → 90° (top-right going down)
    arc.color = blue;
    canvas.drawArc(rect, rad(-10), rad(100), false, arc);
    // Green: 90° → 170°
    arc.color = green;
    canvas.drawArc(rect, rad(90), rad(80), false, arc);
    // Yellow: 170° → 230°
    arc.color = yellow;
    canvas.drawArc(rect, rad(170), rad(60), false, arc);
    // Red: 230° → 350°
    arc.color = red;
    canvas.drawArc(rect, rad(230), rad(120), false, arc);

    // Blue crossbar (horizontal bar from center to right edge)
    canvas.drawRect(
      Rect.fromLTRB(cx, cy - sw / 2, cx + arcR + sw / 2, cy + sw / 2),
      Paint()..color = blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
