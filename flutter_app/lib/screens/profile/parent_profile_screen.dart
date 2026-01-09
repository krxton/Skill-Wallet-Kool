// lib/screens/parent_profile_screen.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({
    super.key,
    required this.parentName,
  });

  final String parentName;

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  // เก็บรูปโปรไฟล์ในหน่วยความจำ (ทำงานได้ทั้ง web & mobile)
  Uint8List? _profileBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfileImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() => _profileBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    const cream = Color(0xFFFFF5CD);

    return Container(
      color: cream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Stack(
              children: [
                // รูปโปรไฟล์ตรงกลาง
                Align(
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 66,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _profileBytes != null
                            ? MemoryImage(_profileBytes!)
                            : null,
                        child: _profileBytes == null
                            ? const Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.black87,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                // ปุ่ม setting มุมขวาบน
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.settings, size: 28),
                    onPressed: () {
                      // TODO: ไว้ค่อยเชื่อมไปหน้า Setting ทีหลัง
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ชื่อผู้ปกครอง
          Center(
            child: Text(
              (widget.parentName.isNotEmpty ? widget.parentName : 'PARENT2')
                  .toUpperCase(),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '',
              style: textTheme.bodySmall,
            ),
          ),

          const SizedBox(height: 32),

          // แถบ POST
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.parentprofile_postBtn,
                      style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 18,
                      color: Colors.black),
                ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(thickness: 1),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ดันให้เต็มหน้าจอ เหลือพื้นที่ว่างด้านล่าง
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
