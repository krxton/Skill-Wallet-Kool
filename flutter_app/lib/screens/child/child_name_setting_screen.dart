import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChildNameSettingScreen extends StatefulWidget {
  final String currentName;

  const ChildNameSettingScreen({super.key, required this.currentName});

  @override
  State<ChildNameSettingScreen> createState() => _ChildNameSettingScreenState();
}

class _ChildNameSettingScreenState extends State<ChildNameSettingScreen> {
  late TextEditingController _nameController;

  static const cream = Color(0xFFFFF5CD);
  static const blueTitle = Color(0xFF4DA9FF);
  static const okGreen = Color(0xFF66BB6A); 

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      Navigator.pop(context, newName);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'EDIT NAME',
                    style: GoogleFonts.luckiestGuy(fontSize: 32, color: blueTitle),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8.0), 
                        child: const Icon(Icons.arrow_back, size: 30, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- TextField ---
              TextField(
                controller: _nameController,
                style: GoogleFonts.luckiestGuy(fontSize: 24, color: Colors.black87),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Type your name...',
                  hintStyle: GoogleFonts.luckiestGuy(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
              ),
              const Spacer(),

              // --- SAVE Button ---
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _saveName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: okGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: Text(
                    'SAVE', 
                    style: GoogleFonts.luckiestGuy(fontSize: 24, color: Colors.white, letterSpacing: 1.5)
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