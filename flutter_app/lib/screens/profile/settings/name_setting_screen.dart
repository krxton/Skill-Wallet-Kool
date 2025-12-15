import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
  static const okGreen  = Color(0xFF66BB6A);

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

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      // 1. บันทึกชื่อใหม่ลงใน Provider
      context.read<UserProvider>().setParentName(newName);
      
      // 2. ปิดหน้านี้กลับไปหน้าเดิม
      Navigator.pop(context);
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
                    child: const Icon(Icons.arrow_back, size: 30, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'CHANGE NAME',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 24,
                      color: blueTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- Input Field ---
              Text(
                'ENTER NEW NAME',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Type your name...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    'SAVE',
                    style: GoogleFonts.luckiestGuy(
                      fontSize: 24,
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