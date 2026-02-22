import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDayController = TextEditingController();
  DateTime? _selectedBirthday;
  String? _selectedRelation;

  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF5AB2FF);
  static const blueInput = Color(0xFFBBDEFB);
  static const greenBtn = Color(0xFF88C273);
  static const redLabel = Color(0xFFFF8A80);

  List<String> _relationOptions(AppLocalizations l10n) => [
        l10n.relation_parent,
        l10n.relation_grandparentPaternal,
        l10n.relation_grandparentMaternal,
        l10n.relation_auntUncle,
        l10n.relation_caregiver,
        l10n.relation_nanny,
      ];

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ??
          DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: sky,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
        _birthDayController.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _pickRelation(AppLocalizations l10n) async {
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
                  trailing: _selectedRelation == option
                      ? const Icon(Icons.check, color: sky)
                      : null,
                  onTap: () {
                    setState(() => _selectedRelation = option);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          l10n.register_registerBtn,
          style: TextStyle(
            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
            fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
            fontSize: 28,
            color: sky,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                l10n.register_additionalBtn,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 20,
                  color: sky,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Name ---
            Text(
              l10n.addchild_namesurnameBtn,
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                fontSize: 16,
                color: redLabel,
              ),
            ),
            const SizedBox(height: 5),
            _inputContainer(
              child: TextField(
                controller: _nameController,
                style: GoogleFonts.itim(fontSize: 15, color: Colors.black87),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Birthday ---
            Text(
              l10n.addchild_birthdayBtn,
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                fontSize: 16,
                color: redLabel,
              ),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: _selectBirthday,
              child: _inputContainer(
                child: AbsorbPointer(
                  child: TextField(
                    controller: _birthDayController,
                    style:
                        GoogleFonts.itim(fontSize: 15, color: Colors.black87),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      hintText: l10n.register_pickbirthday,
                      hintStyle:
                          GoogleFonts.itim(fontSize: 15, color: Colors.grey),
                      suffixIcon:
                          const Icon(Icons.calendar_today, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Relation ---
            Text(
              l10n.relation_label,
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                fontSize: 16,
                color: redLabel,
              ),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () => _pickRelation(l10n),
              child: _inputContainer(
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        _selectedRelation ?? l10n.relation_hint,
                        style: GoogleFonts.itim(
                          fontSize: 15,
                          color: _selectedRelation != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.arrow_drop_down, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),

            // --- OK Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.addchild_errorName,
                          style: TextStyle(
                            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                            fontFamilyFallback: [
                              GoogleFonts.itim().fontFamily!
                            ],
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'name': name,
                    'birthday': _selectedBirthday ?? DateTime.now(),
                    'relation': _selectedRelation,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenBtn,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.addchild_okBtn,
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputContainer({required Widget child}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: blueInput,
        borderRadius: BorderRadius.circular(25),
      ),
      child: child,
    );
  }
}
