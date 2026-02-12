import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import 'add_child_screen.dart';
import 'manage_child_screen.dart';
import 'child_profile_screen.dart';
import '../../providers/user_provider.dart';

class ChildSettingScreen extends StatefulWidget {
  const ChildSettingScreen({super.key});

  @override
  State<ChildSettingScreen> createState() => _ChildSettingScreenState();
}

class _ChildSettingScreenState extends State<ChildSettingScreen> {
  // 🎨 สีตาม Theme
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF5AB2FF);
  static const greenIcon = Color(0xFF88C273);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
    });
  }

  Future<void> _loadChildren() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();
    await userProvider.fetchChildrenData();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ฟังก์ชันเพิ่มเด็กใหม่
  Future<void> _addNewChild() async {
    final newChildData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddChildScreen()),
    );

    if (!mounted) return;

    if (newChildData != null && newChildData is Map<String, dynamic>) {
      final userProvider = context.read<UserProvider>();

      // Parse birthday if exists
      DateTime birthday = DateTime.now();
      if (newChildData['birthday'] != null) {
        birthday = newChildData['birthday'] as DateTime;
      }

      final success = await userProvider.addChild(
        name: newChildData['name'] as String,
        birthday: birthday,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.childsetting_addSuccess,
              style: TextStyle(
                fontFamily: GoogleFonts.itim().fontFamily,
              ),
            ),
          ),
        );
      }
    }
  }

  // ✅ ฟังก์ชันจัดการเด็ก
  Future<void> _manageChild(Map<String, dynamic> childData) async {
    final childInfo = childData['child'] as Map<String, dynamic>;
    final childId = childInfo['child_id'] as String;
    final childName = childInfo['name_surname'] as String;
    final childWallet = childInfo['wallet'] as int? ?? 0;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageChildScreen(
          childId: childId, // ส่ง childId เพื่อให้แสดงข้อมูลเด็กคนที่ถูกต้อง
          name: childName,
          imageUrl: '', // No image URL for now
          score: childWallet,
        ),
      ),
    );

    if (!mounted) return;

    final userProvider = context.read<UserProvider>();

    if (result == true) {
      // กรณีได้รับค่า true กลับมา = ลบ
      final success = await userProvider.deleteChild(childId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.childsetting_deleteSuccess,
              style: TextStyle(
                fontFamily: GoogleFonts.itim().fontFamily,
              ),
            ),
          ),
        );
      }
    } else if (result is Map && result['newName'] != null) {
      // กรณีได้รับ Map กลับมา = มีการแก้ไขข้อมูล
      await userProvider.updateChild(
        childId: childId,
        name: result['newName'] as String,
      );
    }
  }

  // ✅ เลือกเด็กเป็น active child
  void _selectChild(String childId) {
    final userProvider = context.read<UserProvider>();
    userProvider.selectChild(childId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.childsetting_selectSuccess,
            style: TextStyle(
              fontFamily: GoogleFonts.itim().fontFamily,
            ),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          AppLocalizations.of(context)!.childsetting_childsettingBtn,
          style: TextStyle(
            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
            fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
            fontSize: 24,
            color: sky,
            letterSpacing: 1.5,
          ),
        ),
        // ปุ่ม + สำหรับเพิ่มเด็ก
        actions: [
          IconButton(
            onPressed: _addNewChild,
            icon: const Icon(Icons.add_circle, color: greenIcon, size: 35),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final children = userProvider.children;
          final currentChildId = userProvider.currentChildId;

          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: sky),
            );
          }

          if (children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.childsetting_noChildren,
                    style: TextStyle(
                      fontFamily: GoogleFonts.itim().fontFamily,
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addNewChild,
                    icon: const Icon(Icons.add),
                    label: Text(
                      AppLocalizations.of(context)!.childsetting_addChild,
                      style: TextStyle(
                        fontFamily: GoogleFonts.itim().fontFamily,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenIcon,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final childData = children[index];
              final childInfo = childData['child'] as Map<String, dynamic>;
              final childId = childInfo['child_id'] as String;
              final childName = childInfo['name_surname'] as String;
              final childWallet = childInfo['wallet'] as int? ?? 0;
              final isSelected = currentChildId == childId;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: isSelected
                      ? Border.all(color: sky, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade200,
                          child: Text(
                            childName.isNotEmpty ? childName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                              fontSize: 28,
                              color: sky,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      childName,
                                      style: TextStyle(
                                        fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                        fontFamilyFallback: [
                                          GoogleFonts.itim().fontFamily!
                                        ],
                                        fontSize: 22,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: greenIcon,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!.childsetting_active,
                                        style: TextStyle(
                                          fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppLocalizations.of(context)!.childsetting_scoreBtn} : $childWallet',
                                style: TextStyle(
                                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                  fontFamilyFallback: [
                                    GoogleFonts.itim().fontFamily!
                                  ],
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Buttons Row
                    Row(
                      children: [
                        // SELECT Button (เฉพาะเมื่อไม่ใช่ child ที่เลือกอยู่)
                        if (!isSelected)
                          Expanded(
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton(
                                onPressed: () => _selectChild(childId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: sky,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.childsetting_select,
                                  style: TextStyle(
                                    fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                    fontFamilyFallback: [
                                      GoogleFonts.itim().fontFamily!
                                    ],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!isSelected) const SizedBox(width: 10),

                        // View Profile Button
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChildProfileScreen(
                                      childId: childId, // ส่ง childId เพื่อให้แสดงข้อมูลเด็กคนที่ถูกต้อง
                                      name: childName,
                                      imageUrl: '',
                                      points: childWallet,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Colors.black, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .childsetting_viewprofileBtn,
                                style: TextStyle(
                                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                  fontFamilyFallback: [
                                    GoogleFonts.itim().fontFamily!
                                  ],
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Manage Button
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: OutlinedButton(
                              onPressed: () => _manageChild(childData),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Colors.black, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .childsetting_manageBtn,
                                style: TextStyle(
                                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                                  fontFamilyFallback: [
                                    GoogleFonts.itim().fontFamily!
                                  ],
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
