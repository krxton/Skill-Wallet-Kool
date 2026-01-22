import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'package:skill_wallet_kool/providers/user_provider.dart';
import 'package:skill_wallet_kool/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../providers/auth_provider.dart';
import '../../services/child_service.dart';
import '../../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService authService = AuthService();

  final ChildService childService = ChildService();

  late int step;

// palette (UI เดิม)

  static const cream = Color(0xFFFFF5CD);

  static const sky = Color(0xFF0D92F4);

  static const redLabel = Color(0xFFE54D4D);

  static const fieldBg = Color(0xFFFDC05E);

  static const okGreen = Color(0xFF66BB6A);

  static const backPink = Color(0xFFEA5B6F);

  final List<_ChildFields> _children = [_ChildFields()];

  Null get style => null;

  @override
  void initState() {
    super.initState();

    step = (widget.initialStep == 1) ? 1 : 0;
  }

  @override
  void dispose() {
    for (final c in _children) {
      c.dispose();
    }

    super.dispose();
  }

// ---------- STEP 0 : SOCIAL ----------

  Widget _firstPage() {
    final authProvider = Provider.of<AuthProvider>(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      children: [
        Text(
          AppLocalizations.of(context)!.register_signuptoBtn,
          style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              fontSize: 24,
              color: sky),
        ),
        Text('SKILL WALLET KOOL',
            style: GoogleFonts.luckiestGuy(fontSize: 28, color: sky)),
        const SizedBox(height: 24),
        _oauthButton(
          label: AppLocalizations.of(context)!.register_facebookBtn,
          leading:
              _circleIcon(icon: Icons.facebook, bg: const Color(0xFF1877F2)),
          onTap: authProvider.isLoading
              ? () {}
              : () async {
                  final success = await authProvider.signInWithFacebook();

                  if (success && mounted) {
// รอ callback จาก deep link
                  }
                },
        ),
        const SizedBox(height: 16),
        _oauthButton(
            label: AppLocalizations.of(context)!.register_googleBtn,
            leading: _googleGlyph(),
            onTap: authProvider.isLoading
                ? () {}
                : () async {
                    _nativeGoogleSignIn();
                  }),
        if (authProvider.isLoading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'กำลังลงทะเบียน...',
              style: GoogleFonts.itim(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _nativeGoogleSignIn() async {
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

    // 2. เริ่มกระบวนการตรวจสอบสิทธิ์กับ Google
    final googleUser = await googleSignIn.authenticate();
    if (googleUser == null) return; // ผู้ใช้ยกเลิกการ Login

    final String? fullName = googleUser.displayName; // เก็บชื่อจาก Google ไว้

    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
            await googleUser.authorizationClient.authorizeScopes(scopes);

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) throw const AuthException('No ID Token found.');

    final supabase = Supabase.instance.client;

    // ✅ 3. ทำการ Login เข้า Supabase และประกาศตัวแปร 'response' มารับค่า (จุดที่แก้)
    final response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );

    // 4. ดึง user จาก response เพื่อนำไปบันทึกลง Database
    final user = response.user;
    if (user != null) {
      // เตรียมชื่อ: ถ้าใน Google ไม่มีชื่อ (ซึ่งปกติจะมี) ให้ใช้ชื่อจาก Email แทน
      final String nameToSave = fullName ?? user.email!.split('@')[0];

      try {
        // บันทึกข้อมูลลงตาราง parent ใน Supabase
        await supabase.from('parent').upsert({
          'user_id': user.id,
          'email': user.email,
          'name_surname': nameToSave,
        });

        // อัปเดตข้อมูลใน Provider ทันทีเพื่อให้หน้าอื่นๆ แสดงชื่อได้ถูกต้อง
        if (mounted) {
          context.read<UserProvider>().setParentName(nameToSave);
        }
      } catch (e) {
        debugPrint('Error upserting parent: $e');
      }
    }

    if (mounted) {
      setState(() {
        step = 1;
      });
    }
  }

// ---------- STEP 1 : ADDITIONAL INFO ----------

  Widget _secondPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      children: [
        Text(
          AppLocalizations.of(context)!.register_registerBtn,
          style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              fontSize: 28,
              color: sky),
        ),

        const SizedBox(height: 2),

        Text(
          AppLocalizations.of(context)!.register_additionalBtn,
          style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              fontSize: 22,
              color: sky),
        ),

        const SizedBox(height: 20),

// Loop สร้างฟอร์มลูก

        ..._children.asMap().entries.map((e) {
          final i = e.key;

          final c = e.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
// ชื่อลูก + ปุ่มลบ

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!
                            .register_namesurnamechildBtn(i + 1),
                        style: GoogleFonts.luckiestGuy(
                            fontSize: 16, color: redLabel),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_children.length > 1)
                      GestureDetector(
                        onTap: () => setState(() {
                          _children.removeAt(i).dispose();
                        }),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close,
                              size: 26, color: Colors.black87),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                TextField(controller: c.nameCtrl, decoration: _dec()),

// วันเกิด

                const SizedBox(height: 14),

                Text(
                  AppLocalizations.of(context)!.register_birthdayBtn,
                  style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 16,
                      color: redLabel),
                ),

                const SizedBox(height: 6),

                GestureDetector(
                  onTap: () => _pickBirthday(i),
                  child: AbsorbPointer(
                    child:
                        TextField(controller: c.birthCtrl, decoration: _dec()),
                  ),
                ),

// ✅ ส่วนที่เพิ่ม: Relation

                const SizedBox(height: 14),

                Text(
                  AppLocalizations.of(context)!.register_relation,
                  style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 16,
                      color: redLabel),
                ),

                const SizedBox(height: 6),

                TextField(controller: c.relationCtrl, decoration: _dec()),

// ✅ จบส่วนที่เพิ่ม
              ],
            ),
          );
        }),

        const SizedBox(height: 8),

        Center(
          child: InkWell(
            onTap: () => setState(() => _children.add(_ChildFields())),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _submit(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: okGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
            ),
            child: Text(
              AppLocalizations.of(context)!.register_okBtn,
              style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 20,
                  color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

// ---------- Helpers ----------

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickBirthday(int index) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _children[index].birthday ??
          DateTime(now.year - 7, now.month, now.day),
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      helpText: AppLocalizations.of(context)!.register_pickbirthday,
    );

    if (picked != null) {
      setState(() {
        _children[index].birthday = picked;

        _children[index].birthCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  void _submit(BuildContext context) async {
// Validate

    for (var i = 0; i < _children.length; i++) {
// ✅ เช็คเพิ่ม: Relation ต้องไม่ว่าง

      if (_children[i].nameCtrl.text.trim().isEmpty ||
          _children[i].birthCtrl.text.trim().isEmpty ||
          _children[i].relationCtrl.text.trim().isEmpty) {
        _toast(
            AppLocalizations.of(context)!.register_requiredinformation(i + 1));

        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
// ✅ เตรียมข้อมูลลูก (เพิ่ม relation)

      List<Map<String, dynamic>> childrenData = _children.map((c) {
        return {
          'fullName': c.nameCtrl.text.trim(),

          'dob':
              c.birthday, // เช็ค format กับ backend ว่ารับ DateTime หรือ String

          'relation': c.relationCtrl.text.trim(), // ส่งค่า relation
        };
      }).toList();

// บันทึกลูกเข้า database

      final addedChildren = await childService.addChildren(childrenData);

      if (mounted) Navigator.pop(context);

      if (addedChildren.isNotEmpty) {
        _toast(
            AppLocalizations.of(context)!.register_sus(addedChildren.length));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      } else {
        _toast(AppLocalizations.of(context)!.register_Anerroroccurredplstry);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      _toast(AppLocalizations.of(context)!.register_Anerroroccurred(e));

      print(AppLocalizations.of(context)!.register_submitterror);
    }
  }

  InputDecoration _dec() => InputDecoration(
        filled: true,
        fillColor: fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
      );

  Widget _oauthButton({
    required String label,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.black26),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                        fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                        fontSize: 16,
                        color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon({required IconData icon, required Color bg}) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 24),
      );

  Widget _googleGlyph() => Container(
        width: 42,
        height: 42,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text('G',
            style:
                GoogleFonts.luckiestGuy(fontSize: 22, color: Colors.black87)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: (step == 0 || step == 1) ? step : 0,
              children: [
                _firstPage(),
                _secondPage(),
              ],
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: InkWell(
                onTap: () {
                  if (step == 1) {
                    setState(() => step = 0);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, color: backPink, size: 26),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.register_backBtn,
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
}

// ✅ Class นี้ถูกแก้ไขเพิ่ม relationCtrl

class _ChildFields {
  final TextEditingController nameCtrl = TextEditingController();

  final TextEditingController birthCtrl = TextEditingController();

  final TextEditingController relationCtrl = TextEditingController(); // เพิ่ม

  DateTime? birthday;

  void dispose() {
    nameCtrl.dispose();

    birthCtrl.dispose();

    relationCtrl.dispose(); // เพิ่ม
  }
}
