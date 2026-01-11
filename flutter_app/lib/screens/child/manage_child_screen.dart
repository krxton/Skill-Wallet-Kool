import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import 'child_name_setting_screen.dart';
import 'medals_redemption_screen.dart';

class ManageChildScreen extends StatefulWidget {
  final String name;
  final String imageUrl;
  final int score;

  const ManageChildScreen({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.score,
  });

  @override
  State<ManageChildScreen> createState() => _ManageChildScreenState();
}

class _ManageChildScreenState extends State<ManageChildScreen> {
  late String _currentName;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // 🎨 Palette
  static const cream = Color(0xFFFFF5CD);
  static const deepGrey = Color(0xFF000000);
  static const deleteRed = Color(0xFFFF6B6B);
  static const labelGrey = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _currentName = widget.name;
  }

  // --- Functions ---

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _navigateToEditName() async {
    // ไปหน้าแก้ไขชื่อ (สมมติว่า ChildNameSettingScreen รับค่าชื่อปัจจุบันและส่งคืนชื่อใหม่)
    final newName = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildNameSettingScreen(currentName: _currentName),
      ),
    );

    if (newName != null && newName is String) {
      setState(() {
        _currentName = newName;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocalizations.of(context)!.dialog_deleteTitle,
            style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.dialog_deleteContent,
            style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // ปิด Dialog
              child: Text(
                AppLocalizations.of(context)!.dialog_cancel,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog
                Navigator.of(context).pop(true); // กลับหน้าก่อนหน้าพร้อมค่า true (แจ้งลบ)
              },
              child: Text(
                AppLocalizations.of(context)!.dialog_confirmDelete,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  color: deleteRed,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic แสดงรูปภาพ
    Widget profileImageWidget;
    if (_imageBytes != null) {
      profileImageWidget = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (widget.imageUrl.isNotEmpty) {
      profileImageWidget = Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 80, color: Colors.grey),
      );
    } else {
      profileImageWidget =
          const Icon(Icons.person, size: 80, color: Colors.grey);
    }

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // ส่งค่ากลับเมื่อกด Back (กรณีมีการแก้ไข)
                      Navigator.pop(context, {
                        'newName': _currentName,
                        'newImageBytes': _imageBytes
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.transparent,
                      child: const Icon(Icons.arrow_back,
                          size: 30, color: Colors.black87),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppLocalizations.of(context)!.managechild_manageprofileBtn,
                    style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 24,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 46), // จัดกึ่งกลาง
                ],
              ),
            ),
            const SizedBox(height: 10),

            // --- Profile Image ---
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: Colors.grey.shade300),
                      child: ClipOval(child: profileImageWidget),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            shape: BoxShape.circle,
                            border: Border.all(color: cream, width: 2)),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.black87, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Menu Items ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. NAME
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToEditName,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.managechild_nameBtn,
                                style: TextStyle(
                                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                  fontFamilyFallback: [
                                    GoogleFonts.itim().fontFamily!
                                  ],
                                  fontSize: 16,
                                  color: labelGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _currentName,
                                    style: TextStyle(
                                      fontFamily:
                                          GoogleFonts.luckiestGuy().fontFamily,
                                      fontFamilyFallback: [
                                        GoogleFonts.itim().fontFamily!
                                      ],
                                      fontSize: 24,
                                      color: deepGrey,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      size: 32, color: deepGrey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.black12),

                    // 2. MEDALS & REDEMPTION
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // ส่งคะแนนไปหน้า Medals
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedalsRedemptionScreen(
                                score: widget.score,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events,
                                  color: Color(0xFFFFC107), size: 30),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .managechild_medalsandredemptionBtn,
                                  style: TextStyle(
                                    fontFamily:
                                        GoogleFonts.luckiestGuy().fontFamily,
                                    fontFamilyFallback: [
                                      GoogleFonts.itim().fontFamily!
                                    ],
                                    fontSize: 20,
                                    color: deepGrey,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 32, color: deepGrey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Delete Button ---
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: TextButton(
                onPressed: _showDeleteConfirmationDialog,
                child: Text(
                  AppLocalizations.of(context)!.managechild_deleteprofileBtn,
                  style: TextStyle(
                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                    fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                    fontSize: 20,
                    color: deleteRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}