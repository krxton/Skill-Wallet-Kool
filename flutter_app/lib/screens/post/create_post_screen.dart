import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // Palette สีตาม Theme ของคุณ
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const backPink = Color(0xFFEA5B6F);

  File? _imageFile;
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเลือกรูป
  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // ฟังก์ชันอัปโหลด
  Future<void> _uploadPost() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Upload รูป
      final String fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('posts').upload(fileName, _imageFile!);

      // 2. ขอ Public URL
      final String imageUrl =
          supabase.storage.from('posts').getPublicUrl(fileName);

      // 3. บันทึกข้อมูล
      await supabase.from('posts').insert({
        'user_id': user.id,
        'caption': _captionController.text.trim(),
        'image_url': imageUrl,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // "Post shared successfully!"
              AppLocalizations.of(context)!.createpost_sharesus,
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // "An error occurred: [error]"
              '${AppLocalizations.of(context)!.createpost_error} $e',
              style: TextStyle(
                fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: backPink, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          // "New post"
          AppLocalizations.of(context)!.createpost_newpost,
          style: TextStyle(
            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
            fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
            fontSize: 22, // คงค่าเดิม
            fontWeight: FontWeight.bold, // คงค่าเดิม
            color: Colors.black, // คงค่าเดิม
          ),
        ),
        actions: [
          if (_imageFile != null && !_isLoading)
            TextButton(
              onPressed: _uploadPost,
              child: Text(
                // "Share"
                AppLocalizations.of(context)!.createpost_share,
                style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                  fontSize: 18, // คงค่าเดิม
                  color: sky, // คงค่าเดิม
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // พื้นที่แสดงรูปภาพ
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 350,
                      color: Colors.grey[200],
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 60, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text(
                                  // "Tap to select a picture"
                                  AppLocalizations.of(context)!
                                      .createpost_picksomepicture,
                                  style: TextStyle(
                                    fontFamily:
                                        GoogleFonts.luckiestGuy().fontFamily,
                                    fontFamilyFallback: [
                                      GoogleFonts.itim().fontFamily!
                                    ],
                                    fontSize: 16, // คงค่าเดิม
                                    color: Colors.grey[600], // คงค่าเดิม
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ปุ่มเปลี่ยนรูป
                  if (_imageFile != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library, color: sky),
                        label: Text(
                          // "Change picture"
                          AppLocalizations.of(context)!.createpost_changepic,
                          style: TextStyle(
                            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                            fontFamilyFallback: [
                              GoogleFonts.itim().fontFamily!
                            ],
                            color: sky, // คงค่าเดิม
                          ),
                        ),
                      ),
                    ),

                  const Divider(height: 1),

                  // ช่องกรอก Caption
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              // "Write a caption..."
                              hintText: AppLocalizations.of(context)!
                                  .createpost_writecaption,
                              hintStyle: TextStyle(
                                fontFamily:
                                    GoogleFonts.luckiestGuy().fontFamily,
                                fontFamilyFallback: [
                                  GoogleFonts.itim().fontFamily!
                                ],
                                color: Colors.black38, // คงค่าเดิม
                              ),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                              fontFamilyFallback: [
                                GoogleFonts.itim().fontFamily!
                              ],
                              fontSize: 16, // คงค่าเดิม
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
