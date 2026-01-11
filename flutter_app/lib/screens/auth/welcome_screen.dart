import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const cream = Color(0xFFFFF5CD);
  static const blue = Color(0xFF77BEF0);
  static const red = Color(0xFFEA5B6F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Stack(
          children: [
            // เนื้อหากลางหน้าจอ
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/SWK_home.png', height: 260),
                    // เลื่อนปุ่ม PLAY ลงมาอีกนิดนึง
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.home),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 48),
                        decoration: BoxDecoration(
                          color: blue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.welcome_playBtn,
                          style: TextStyle(
                              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                              fontFamilyFallback: [
                                GoogleFonts.itim().fontFamily!
                              ],
                              fontSize: 28,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ปุ่ม SIGN-UP ล่างซ้าย
            Positioned(
              left: 24,
              bottom: 20,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                child: Text(
                  AppLocalizations.of(context)!.welcome_signUpBtn,
                  style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 18,
                      color: red),
                ),
              ),
            ),

            // ปุ่ม LOG IN ล่างขวา
            Positioned(
              right: 24,
              bottom: 20,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                child: Text(
                  AppLocalizations.of(context)!.welcome_signInBtn,
                  style: TextStyle(
                      fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                      fontFamilyFallback: [GoogleFonts.itim().fontFamily!],
                      fontSize: 18,
                      color: red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
