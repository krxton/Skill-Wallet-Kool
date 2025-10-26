import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart'; // ✅ ใส่กลับมา

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'CATEGORY';

  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF77BEF0);
  static const yellow = Color(0xFFFFCC00);
  static const blue = Color(0xFF0D92F4);
  static const chipGrey = Color(0xFFE3E3E3);

  void _openCategorySheet() {
    final items = ['MATH', 'PHYSICAL', 'LANGUAGE'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final text = items[i];
              return ListTile(
                title: Text(text, style: GoogleFonts.luckiestGuy(fontSize: 20)),
                onTap: () {
                  Navigator.pop(context);
                  if (text == 'LANGUAGE') {
                    // ✅ ไปหน้า Language Hub
                    Navigator.pushNamed(context, AppRoutes.languageHub);
                  } else {
                    setState(() => _category = text);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text, {Color? color}) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.luckiestGuy(
            fontSize: 22,
            color: color ?? yellow,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _activityCard(String label) => Container(
        width: 140,
        height: 120,
        decoration: BoxDecoration(
          color: chipGrey,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.luckiestGuy(fontSize: 22)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
        title: Text('SKILL WALLET KOOL',
            style: GoogleFonts.luckiestGuy(color: Colors.black, fontSize: 24)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: _BottomBar(
        onHome: () {},
        onPlus: () {},
        onProfile: () {},
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // search bar
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4D9E5),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    const Icon(Icons.menu, color: Colors.black54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('SEARCH...',
                          style: GoogleFonts.luckiestGuy(
                              color: Colors.black54, fontSize: 16)),
                    ),
                    const Icon(Icons.search, color: Colors.black54),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text('SWK',
                  style: GoogleFonts.luckiestGuy(color: blue, fontSize: 28)),

              const SizedBox(height: 8),

              // ▼ ปุ่ม CATEGORY (ถ้าอยากเอาปุ่ม LANGUAGE สีน้ำเงินออก ให้ลบบล็อกที่คอมเมนต์ไว้ด้านล่าง)
              Row(
                children: [
                  GestureDetector(
                    onTap: _openCategorySheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: sky,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_category,
                              style: GoogleFonts.luckiestGuy(
                                  color: Colors.white, fontSize: 18)),
                          const SizedBox(width: 8),
                          const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white),
                        ],
                      ),
                    ),
                  ),

                  // // ❌ เอาปุ่ม LANGUAGE ออกโดยลบบล็อกนี้ทั้งก้อน
                  // const SizedBox(width: 12),
                  // GestureDetector(
                  //   onTap: () =>
                  //       Navigator.pushNamed(context, AppRoutes.languageHub),
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 16, vertical: 12),
                  //     decoration: BoxDecoration(
                  //       color: blue,
                  //       borderRadius: BorderRadius.circular(28),
                  //     ),
                  //     child: Text('LANGUAGE',
                  //         style: GoogleFonts.luckiestGuy(
                  //             color: Colors.white, fontSize: 16)),
                  //   ),
                  // ),
                ],
              ),

              const SizedBox(height: 16),

              // big clip
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: blue, width: 3),
                ),
                alignment: Alignment.center,
                child: Text('CLIP VDO',
                    style: GoogleFonts.luckiestGuy(fontSize: 32)),
              ),

              _sectionTitle('POPULAR ACTIVITIES', color: blue),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _activityCard('CLIP'),
                ),
              ),

              _sectionTitle('NEW', color: blue),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar(
      {required this.onHome, required this.onPlus, required this.onProfile});
  final VoidCallback onHome;
  final VoidCallback onPlus;
  final VoidCallback onProfile;

  static const red = Color(0xFFEA5B6F);
  static const yellow = Color(0xFFFFCC00);
  static const cream = Color(0xFFFFF5CD);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: red,
        borderRadius:
            BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 6,
            child: GestureDetector(
              onTap: onPlus,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: red.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
                  ],
                ),
                child: const Center(child: Icon(Icons.add, size: 34, color: Colors.white)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onHome,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: yellow, shape: BoxShape.circle),
                    child: const Icon(Icons.home_rounded, color: cream, size: 36),
                  ),
                ),
                GestureDetector(
                  onTap: onProfile,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: yellow, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: cream, size: 34),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
