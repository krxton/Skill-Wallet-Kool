import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const cream = Color(0xFFFFF5CD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'PROFILE',
          style: GoogleFonts.luckiestGuy(
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: const Center(
        child: Text('Profile Page (Blank)'),
      ),
    );
  }
}
