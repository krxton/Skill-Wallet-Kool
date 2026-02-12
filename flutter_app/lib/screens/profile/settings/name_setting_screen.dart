import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart'; // อย่าลืม Import นี้
import '../../../providers/user_provider.dart';

class NameSettingScreen extends StatefulWidget {
  const NameSettingScreen({super.key});

  @override
  State<NameSettingScreen> createState() => _NameSettingScreenState();
}

class _NameSettingScreenState extends State<NameSettingScreen> {
  // ตัวควบคุมข้อความในช่องพิมพ์
  late TextEditingController _nameController;

  // สี Theme
  static const cream = Color(0xFFFFF5CD);
  static const pinkRed = Color(0xFFEA5B6F);
  static const blueTitle = Color(0xFF4DA9FF);
  static const okGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    // ดึงชื่อปัจจุบันจาก Provider มาแสดงในช่องพิมพ์ก่อน
    final currentName = context.read<UserProvider>().currentParentName ?? '';
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.updateParentName(newName);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.namesetting_saveFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        size: 30, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(context)!.namesetting_changenameBtn,
                    style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 24,
                      color: blueTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- Input Field Label ---
              Text(
                AppLocalizations.of(context)!.namesetting_enternewnameBtn,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

              // --- Input TextField ---
              TextField(
                controller: _nameController,
                // Style สำหรับข้อความที่พิมพ์เข้าไป
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 20,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: AppLocalizations.of(context)!.namesetting_hint,
                  // Style สำหรับ Hint Text (ข้อความจางๆ)
                  hintStyle: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 20,
                    color: Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const Spacer(),

              // --- Save Button ---
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: okGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.namesetting_saveBtn,
                    style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
