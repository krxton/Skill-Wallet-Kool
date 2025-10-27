import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialStep = 0});
  final int initialStep;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late int step;

  // palette
  static const cream    = Color(0xFFFFF5CD);
  static const sky      = Color(0xFF0D92F4);
  static const redLabel = Color(0xFFE54D4D);
  static const fieldBg  = Color(0xFFFDC05E);
  static const okGreen  = Color(0xFF66BB6A);
  static const backPink = Color(0xFFEA5B6F);

  final List<_ChildFields> _children = [ _ChildFields() ];

  @override
  void initState() {
    super.initState();
    step = (widget.initialStep == 1) ? 1 : 0;
  }

  @override
  void dispose() {
    for (final c in _children) { c.dispose(); }
    super.dispose();
  }

  // ---------- STEP 0 : SOCIAL ----------
  Widget _firstPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      children: [
        Text('SIGN-IN TO', style: GoogleFonts.luckiestGuy(fontSize: 24, color: sky)),
        Text('SKILL WALLET KOOL', style: GoogleFonts.luckiestGuy(fontSize: 28, color: sky)),
        const SizedBox(height: 24),
        _oauthButton(
          label: 'CONTINUE WITH FACEBOOK',
          leading: _circleIcon(icon: Icons.facebook, bg: const Color(0xFF1877F2)),
          onTap: () => _toast('Facebook sign-in (mock)'),
        ),
        const SizedBox(height: 16),
        _oauthButton(
          label: 'CONTINUE WITH GOOGLE',
          leading: _googleGlyph(),
          onTap: () => _toast('Google sign-in (mock)'),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: okGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 2,
            ),
            child: Text('NEXT',
              style: GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ---------- STEP 1 : ADDITIONAL INFO ----------
  Widget _secondPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      children: [
        Text('REGISTER', style: GoogleFonts.luckiestGuy(fontSize: 28, color: sky)),
        const SizedBox(height: 2),
        Text('ADDITIONAL INFORMATION',
            style: GoogleFonts.luckiestGuy(fontSize: 22, color: sky)),
        const SizedBox(height: 20),

        ..._children.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title + X
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'NAME & SURNAME (CHILDREN) #${i + 1}',
                        style: GoogleFonts.luckiestGuy(fontSize: 16, color: redLabel),
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
                          child: Icon(Icons.close, size: 26, color: Colors.black87),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(controller: c.nameCtrl, decoration: _dec()),

                const SizedBox(height: 14),
                Text('BIRTHDAY : DD/MM/YYYY',
                    style: GoogleFonts.luckiestGuy(fontSize: 16, color: redLabel)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _pickBirthday(i),
                  child: AbsorbPointer(
                    child: TextField(controller: c.birthCtrl, decoration: _dec()),
                  ),
                ),
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
              width: 58, height: 58,
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
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: okGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
            ),
            child: Text('OK',
              style: GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ---------- helpers ----------
  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickBirthday(int index) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _children[index].birthday ?? DateTime(now.year - 7, now.month, now.day),
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      helpText: 'เลือกวันเกิด',
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

  void _submit() {
    for (var i = 0; i < _children.length; i++) {
      if (_children[i].nameCtrl.text.trim().isEmpty ||
          _children[i].birthCtrl.text.trim().isEmpty) {
        _toast('กรอกข้อมูลให้ครบในรายการที่ ${i + 1}');
        return;
      }
    }
    _toast('ลงทะเบียนสำเร็จ!');
    Navigator.pop(context);
  }

  InputDecoration _dec() => InputDecoration(
    filled: true,
    fillColor: fieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  style: GoogleFonts.luckiestGuy(fontSize: 16, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon({required IconData icon, required Color bg}) => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Icon(icon, color: Colors.white, size: 24),
  );

  Widget _googleGlyph() => Container(
    width: 42, height: 42,
    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text('G', style: GoogleFonts.luckiestGuy(fontSize: 22, color: Colors.black87)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Stack(
          children: [
            // เนื้อหา 2 step
            IndexedStack(
              index: (step == 0 || step == 1) ? step : 0,
              children: [
                _firstPage(),
                _secondPage(),
              ],
            ),
            // BACK มุมซ้ายล่าง
            Positioned(
              left: 12, bottom: 12,
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
                    Text('BACK',
                        style: GoogleFonts.luckiestGuy(fontSize: 24, color: backPink)),
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

class _ChildFields {
  final TextEditingController nameCtrl  = TextEditingController();
  final TextEditingController birthCtrl = TextEditingController();
  DateTime? birthday;
  void dispose() { nameCtrl.dispose(); birthCtrl.dispose(); }
}
