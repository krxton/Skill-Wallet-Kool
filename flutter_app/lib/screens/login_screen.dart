import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../widgets/social_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ← BACK
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '← BACK',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✨ แทนรูปด้วยข้อความหัวเรื่อง
              const Center(
                child: Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),

              // ปุ่ม Login Facebook/Google
              SocialButton(
                label: 'CONTINUE WITH FACEBOOK',
                icon: Icons.facebook,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
              ),
              const SizedBox(height: 12),
              SocialButton(
                label: 'CONTINUE WITH GOOGLE',
                icon: Icons.g_mobiledata,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
