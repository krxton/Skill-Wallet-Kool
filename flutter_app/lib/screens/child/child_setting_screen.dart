import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import 'add_child_screen.dart';
import 'manage_child_screen.dart';
import 'child_profile_screen.dart';

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

  // ข้อมูล Mock Data (รายชื่อเด็ก)
  List<Map<String, dynamic>> children = [
    {
      'name': 'KRATON',
      'score': 1000000,
      'img': 'https://i.pravatar.cc/150?img=1'
    },
    {'name': 'GOLF', 'score': 300, 'img': 'https://i.pravatar.cc/150?img=8'},
  ];

  // ฟังก์ชันเพิ่มเด็กใหม่
  void _addNewChild() async {
    final newChildData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddChildScreen()),
    );

    if (newChildData != null) {
      setState(() {
        children.add(newChildData);
      });
    }
  }

  // ✅ ฟังก์ชันจัดการเด็ก
  void _manageChild(int index) async {
    final child = children[index];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageChildScreen(
          name: child['name'],
          imageUrl: child['img'],
          score: child['score'],
        ),
      ),
    );

    if (result == true) {
      // กรณีได้รับค่า true กลับมา = ลบ
      setState(() {
        children.removeAt(index);
      });
    } else if (result is Map) {
      // กรณีได้รับ Map กลับมา = มีการแก้ไขข้อมูล
      setState(() {
        if (result['newName'] != null) {
          children[index]['name'] = result['newName'];
        }
        // ถ้ามี logic อัปเดตรูปภาพเพิ่ม ก็ใส่ตรงนี้ได้
      });
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                      backgroundImage: NetworkImage(child['img']),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child['name'],
                          style: TextStyle(
                            fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                            fontFamilyFallback: [
                              GoogleFonts.itim().fontFamily!
                            ],
                            fontSize: 24,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${AppLocalizations.of(context)!.childsetting_scoreBtn} : ${child['score']}',
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
                  ],
                ),
                const SizedBox(height: 16),

                // Buttons Row
                Row(
                  children: [
                    // View Profile Button
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: OutlinedButton(
                          onPressed: () {
                            // กดเพื่อไปหน้า Profile ของเด็กคนนั้น
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChildProfileScreen(
                                  name: child['name'],
                                  imageUrl: child['img'],
                                  points: child['score'],
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
                          onPressed: () {
                            // เรียกฟังก์ชันจัดการเด็ก
                            _manageChild(index);
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
      ),
    );
  }
}