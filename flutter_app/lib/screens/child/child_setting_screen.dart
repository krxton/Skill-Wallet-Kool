import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/palette.dart';
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
        relationship: newChildData['relation'] as String?,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.childsetting_addSuccess,
              style: AppTextStyles.body(14),
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
          childId: childId,
          name: childName,
          imageUrl: childInfo['photo_url'] as String?,
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
              style: AppTextStyles.body(14),
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

    // Reload after any manage action (delete/edit)
    await _loadChildren();
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
            style: AppTextStyles.body(14),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          style: AppTextStyles.heading(24, color: Palette.sky)
              .copyWith(letterSpacing: 1.5),
        ),
        // ปุ่ม + สำหรับเพิ่มเด็ก
        actions: [
          IconButton(
            onPressed: _addNewChild,
            icon: const Icon(Icons.add_circle, color: Palette.success, size: 35),
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
              child: CircularProgressIndicator(color: Palette.sky),
            );
          }

          if (children.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.child_care_rounded,
                        size: 80, color: Colors.black26),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.childsetting_noChildren,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body(16, color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: _addNewChild,
                      icon: const Icon(Icons.add, color: Colors.white, size: 20),
                      label: Text(
                        AppLocalizations.of(context)!.childsetting_addChild,
                        style: AppTextStyles.label(16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.sky,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ],
                ),
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
                      ? Border.all(color: Palette.sky, width: 3)
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
                          backgroundImage:
                              (childInfo['photo_url'] as String? ?? '')
                                      .isNotEmpty
                                  ? NetworkImage(
                                      childInfo['photo_url'] as String)
                                  : null,
                          child:
                              (childInfo['photo_url'] as String? ?? '').isEmpty
                                  ? Text(
                                      childName.isNotEmpty
                                          ? childName[0].toUpperCase()
                                          : '?',
                                      style: AppTextStyles.heading(28,
                                          color: Palette.sky),
                                    )
                                  : null,
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
                                      style: AppTextStyles.heading(22,
                                          color: Palette.text),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Palette.success,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .childsetting_active,
                                        style: AppTextStyles.heading(10,
                                            color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppLocalizations.of(context)!.childsetting_scoreBtn} : $childWallet',
                                style: AppTextStyles.body(14,
                                    color: Colors.grey),
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
                                  backgroundColor: Palette.sky,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .childsetting_select,
                                  style: AppTextStyles.heading(14,
                                      color: Colors.white),
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
                                      childId: childId,
                                      name: childName,
                                      imageUrl: childInfo['photo_url']
                                              as String? ??
                                          '',
                                      points: childWallet,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.black, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .childsetting_viewprofileBtn,
                                style: AppTextStyles.heading(14,
                                    color: Colors.black),
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
                                side: const BorderSide(
                                    color: Colors.black, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!
                                    .childsetting_manageBtn,
                                style: AppTextStyles.heading(14,
                                    color: Colors.black),
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
