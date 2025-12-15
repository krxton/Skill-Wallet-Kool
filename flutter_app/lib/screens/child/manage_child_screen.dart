import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Import ไฟล์หน้าแก้ชื่อให้ถูกต้อง
import 'child_name_setting_screen.dart'; 

class ManageChildScreen extends StatefulWidget {
  final String name;
  final String imageUrl;

  const ManageChildScreen({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<ManageChildScreen> createState() => _ManageChildScreenState();
}

class _ManageChildScreenState extends State<ManageChildScreen> {
  late String _currentName;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  static const cream = Color(0xFFFFF5CD);
  static const deepGrey = Color(0xFF000000);
  static const deleteRed = Color(0xFFFF6B6B);
  static const labelGrey = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _currentName = widget.name;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
      if (pickedFile != null) {
        setState(() { _imageFile = File(pickedFile.path); });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _navigateToEditName() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChildNameSettingScreen(currentName: _currentName),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _currentName = result;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text('ARE YOU SURE?', textAlign: TextAlign.center, style: GoogleFonts.luckiestGuy(fontSize: 22, color: deepGrey)),
          ),
          content: Text('Do you want to delete this profile?', textAlign: TextAlign.center, style: GoogleFonts.luckiestGuy(fontSize: 16, color: Colors.grey)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade400, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: Text('BACK', style: GoogleFonts.luckiestGuy(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: deleteRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: Text('YES', style: GoogleFonts.luckiestGuy(fontSize: 18, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget profileImageWidget;
    if (_imageFile != null) {
      profileImageWidget = Image.file(_imageFile!, fit: BoxFit.cover);
    } else if (widget.imageUrl.isNotEmpty) {
      profileImageWidget = Image.network(widget.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, size: 80, color: Colors.grey));
    } else {
      profileImageWidget = const Icon(Icons.person, size: 80, color: Colors.grey);
    }

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context, { 'newName': _currentName });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.transparent,
                      child: const Icon(Icons.arrow_back, size: 30, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), color: Colors.grey.shade300),
                      child: ClipOval(child: profileImageWidget),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFFFC107), shape: BoxShape.circle, border: Border.all(color: cream, width: 2)),
                        child: const Icon(Icons.camera_alt, color: Colors.black87, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              Text('NAME', style: GoogleFonts.luckiestGuy(fontSize: 16, color: labelGrey)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_currentName, style: GoogleFonts.luckiestGuy(fontSize: 24, color: deepGrey)),
                                  const Icon(Icons.chevron_right, size: 32, color: deepGrey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.black12),
                    
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Color(0xFFFFC107), size: 30),
                              const SizedBox(width: 16),
                              Expanded(child: Text('MEDALS & REDEMPTION', style: GoogleFonts.luckiestGuy(fontSize: 20, color: deepGrey))),
                              const Icon(Icons.chevron_right, size: 32, color: deepGrey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: TextButton(
                onPressed: _showDeleteConfirmationDialog,
                child: Text('DELETE PROFILE', style: GoogleFonts.luckiestGuy(fontSize: 20, color: deleteRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}