import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const cream = Color(0xFFFFF5CD);
  static const blue  = Color(0xFF77BEF0);
  static const red   = Color(0xFFEA5B6F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/SWK_home.png', height: 260),
              const SizedBox(height: 32),

              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.home),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                  decoration: BoxDecoration(
                    color: blue, borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text('PLAY',
                      style: GoogleFonts.luckiestGuy(fontSize: 28, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ไปหน้า Register (เริ่ม step 0)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: Text('SIGN-UP',
                        style: GoogleFonts.luckiestGuy(fontSize: 18, color: red)),
                  ),
                  const SizedBox(width: 48),
                  // ไปหน้า Login
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                    child: Text('LOG IN',
                        style: GoogleFonts.luckiestGuy(fontSize: 18, color: red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
