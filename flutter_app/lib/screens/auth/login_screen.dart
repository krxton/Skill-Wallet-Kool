import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const cream    = Color(0xFFFFF5CD);
  static const fbBlue   = Color(0xFF1877F2);
  static const backPink = Color(0xFFEA5B6F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/SWK_home.png', height: 240),
                    const SizedBox(height: 32),

                    _loginButton(
                      icon: Icons.facebook,
                      text: 'CONTINUE WITH FACEBOOK',
                      color: fbBlue,
                      onTap: () {
                     
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      },
                    ),
                    const SizedBox(height: 16),

                    _googleButton(
                      text: 'CONTINUE WITH GOOGLE',
                      onTap: () {
                      
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // BACK มุมซ้ายล่างตาม Figma
            Positioned(
              left: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, color: backPink, size: 26),
                    const SizedBox(width: 6),
                    Text('BACK',
                        style: GoogleFonts.luckiestGuy(color: backPink, fontSize: 24)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(text,
                    style: GoogleFonts.luckiestGuy(fontSize: 16, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleButton({required String text, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('G', style: GoogleFonts.luckiestGuy(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(text,
                    style: GoogleFonts.luckiestGuy(fontSize: 16, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
