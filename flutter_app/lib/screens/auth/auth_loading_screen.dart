// lib/screens/auth/auth_loading_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/SWK_home.png',
              height: 180,
            ),
            const SizedBox(height: 48),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(sky),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),

            // Loading Text
            Text(
              'กำลังโหลด...',
              style: GoogleFonts.itim(
                fontSize: 18,
                color: sky,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'กรุณารอสักครู่',
              style: GoogleFonts.itim(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
