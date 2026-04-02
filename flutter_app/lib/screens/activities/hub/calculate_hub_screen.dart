import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';
import '../../../theme/palette.dart';
import '../../../theme/app_text_styles.dart';

class CalculateHubScreen extends StatelessWidget {
  const CalculateHubScreen({super.key});

  // 🎨 orange button color not in Palette, kept locally
  static const orangeBtn = Color(0xFFEF9C66);

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
          'CALCULATE',
          style: AppTextStyles.heading(32, color: Palette.sky).copyWith(
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // PLUS + (ไปหน้า PlusPage)
            _buildMenuButton(context, 'PLUS +', () {
              Navigator.pushNamed(context, AppRoutes.plusPage);
            }),

            _buildMenuButton(context, 'MINUS -', () {
              // TODO: ไปหน้าลบ
            }),
            _buildMenuButton(context, 'MULTIPLY *', () {
              // TODO: ไปหน้าคูณ
            }),
            _buildMenuButton(context, 'DEVIDE /', () {
              // TODO: ไปหน้าหาร
            }),
            _buildMenuButton(context, 'MIX + - * /', () {
              // TODO: ไปหน้าผสม
            }),

            // 🆕 แก้ไขปุ่ม Problems Solve ให้ไปหน้าใหม่
            _buildMenuButton(context, 'PROBLEMS SOLVE', () {
              Navigator.pushNamed(context, AppRoutes.problemsSolve);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: orangeBtn,
          foregroundColor: Palette.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.heading(24, color: Palette.white),
            ),
            const Icon(Icons.chevron_right, size: 30, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}
