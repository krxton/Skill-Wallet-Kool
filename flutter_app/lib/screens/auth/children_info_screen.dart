import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import '../../services/child_service.dart';
import '../../routes/app_routes.dart';

class ChildrenInfoScreen extends StatefulWidget {
  const ChildrenInfoScreen({super.key});

  @override
  State<ChildrenInfoScreen> createState() => _ChildrenInfoScreenState();
}

class _ChildrenInfoScreenState extends State<ChildrenInfoScreen> {
  final ChildService childService = ChildService();
  bool _isLoading = false;

  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const redLabel = Color(0xFFE54D4D);
  static const fieldBg = Color(0xFFBBDEFB);
  static const okGreen = Color(0xFF66BB6A);
  static const backPink = Color(0xFFEA5B6F);

  final List<_ChildFields> _children = [_ChildFields()];

  List<String> _relationOptions(AppLocalizations l10n) => [
        l10n.relation_parent,
        l10n.relation_grandparentPaternal,
        l10n.relation_grandparentMaternal,
        l10n.relation_auntUncle,
        l10n.relation_caregiver,
        l10n.relation_nanny,
      ];

  @override
  void dispose() {
    for (final c in _children) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 80),
              children: [
                Text(
                  l10n.register_registerBtn,
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 28,
                    color: sky,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.register_additionalBtn,
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 22,
                    color: sky,
                  ),
                ),
                const SizedBox(height: 20),
                ..._children.asMap().entries.map((e) {
                  final i = e.key;
                  final c = e.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                l10n.register_namesurnamechildBtn(i + 1),
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
                        TextField(
                          controller: c.nameCtrl,
                          decoration: _dec(hint: 'ชื่อ-นามสกุล'),
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.itim(
                              fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.register_birthdayBtn,
                          style: TextStyle(
                            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                            fontFamilyFallback: [
                              GoogleFonts.itim().fontFamily!
                            ],
                            fontSize: 16,
                            color: redLabel,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickBirthday(i),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: c.birthCtrl,
                              decoration: _dec(hint: 'วัน/เดือน/ปี'),
                              style: GoogleFonts.itim(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.relation_label,
                          style: TextStyle(
                            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                            fontFamilyFallback: [
                              GoogleFonts.itim().fontFamily!
                            ],
                            fontSize: 16,
                            color: redLabel,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickRelation(i, l10n),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.selectedRelation ?? l10n.relation_hint,
                                    style: GoogleFonts.itim(
                                      fontSize: 14,
                                      color: c.selectedRelation != null
                                          ? Colors.black87
                                          : Colors.black38,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.black54),
                              ],
                            ),
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
                    onPressed: _isLoading ? null : () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: okGreen,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.register_okBtn,
                            style: TextStyle(
                              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                              fontFamilyFallback: [
                                GoogleFonts.itim().fontFamily!
                              ],
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: InkWell(
                onTap: _isLoading ? null : () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      color: _isLoading ? Colors.grey : backPink,
                      size: 26,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.register_backBtn,
                      style: TextStyle(
                        fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                        fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                        fontSize: 24,
                        color: _isLoading ? Colors.grey : backPink,
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

  Future<void> _pickRelation(int index, AppLocalizations l10n) async {
    final options = _relationOptions(l10n);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                l10n.relation_label,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 18,
                  color: redLabel,
                ),
              ),
            ),
            ...options.map((option) => ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                  title: Text(
                    option,
                    style:
                        GoogleFonts.itim(fontSize: 16, color: Colors.black87),
                  ),
                  trailing: _children[index].selectedRelation == option
                      ? const Icon(Icons.check, color: Color(0xFF0D92F4))
                      : null,
                  onTap: () {
                    setState(() => _children[index].selectedRelation = option);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 3)),
    );
  }

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

  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    for (var i = 0; i < _children.length; i++) {
      if (_children[i].nameCtrl.text.trim().isEmpty ||
          _children[i].birthCtrl.text.trim().isEmpty ||
          _children[i].selectedRelation == null) {
        _toast(l10n.register_requiredinformation(i + 1));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final childrenData = _children
          .map((c) => {
                'fullName': c.nameCtrl.text.trim(),
                'dob': c.birthday?.toIso8601String(),
                'relation': c.selectedRelation,
              })
          .toList();

      final addedChildren = await childService.addChildren(childrenData);

      setState(() => _isLoading = false);

      if (addedChildren.isNotEmpty) {
        _toast(l10n.register_sus(addedChildren.length));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          );
        }
      } else {
        _toast(l10n.register_Anerroroccurredplstry);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Submit error: $e');
      _toast(AppLocalizations.of(context)!.register_Anerroroccurred(e));
    }
  }

  InputDecoration _dec({String? hint}) => InputDecoration(
        filled: true,
        fillColor: fieldBg,
        hintText: hint,
        hintStyle: GoogleFonts.itim(color: Colors.black38, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
      );
}

class _ChildFields {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController birthCtrl = TextEditingController();
  String? selectedRelation;
  DateTime? birthday;

  void dispose() {
    nameCtrl.dispose();
    birthCtrl.dispose();
  }
}
