import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // ข้อมูล Mock Data
  List<Map<String, dynamic>> children = [
    {'name': 'KRATON', 'score': 250, 'img': 'https://i.pravatar.cc/150?img=1'},
    {'name': 'GOLF', 'score': 300, 'img': 'https://i.pravatar.cc/150?img=8'},
  ];

  // ฟังก์ชันเพิ่มเด็ก
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

  // ✅ ฟังก์ชันจัดการเด็ก (ลบ)
  void _manageChild(int index) async {
    final child = children[index];
    
    // รอรับค่าผลลัพธ์จากหน้า ManageChildScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageChildScreen(
          name: child['name'],
          imageUrl: child['img'],
        ),
      ),
    );

    // ถ้าค่าที่ส่งกลับมาเป็น true แปลว่าให้ "ลบ"
    if (result == true) {
      setState(() {
        children.removeAt(index);
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
          'CHILD',
          style: GoogleFonts.luckiestGuy(
            fontSize: 32,
            color: sky,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle, color: greenIcon, size: 40),
              onPressed: _addNewChild,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          return _buildChildCard(context, child, index);
        },
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, Map<String, dynamic> child, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: NetworkImage(child['img']),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      child['name'],
                      style: GoogleFonts.luckiestGuy(
                        fontSize: 24,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.orange, size: 28),
                        const SizedBox(width: 5),
                        Text(
                          '${child['score']}',
                          style: GoogleFonts.luckiestGuy(
                            fontSize: 24,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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
                            name: child['name'],
                            imageUrl: child['img'],
                            points: child['score'],
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'VIEW PROFILE',
                      style: GoogleFonts.luckiestGuy(fontSize: 14, color: Colors.black),
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
                      // ✅ เรียกใช้ฟังก์ชัน _manageChild เพื่อรอรับผลลัพธ์การลบ
                      _manageChild(index);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'MANAGE',
                      style: GoogleFonts.luckiestGuy(fontSize: 14, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}