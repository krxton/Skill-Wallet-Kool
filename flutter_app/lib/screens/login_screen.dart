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
              // ปุ่ม Back
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← BACK',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),

              // Logo / Illustration
              Center(
                child: Image.asset(
                  'assets/images/skill_wallet_kool.png',
                  height: 200,
                ),
              ),
              const SizedBox(height: 32),

              // ปุ่ม Login Facebook
              SocialButton(
                label: 'CONTINUE WITH FACEBOOK',
                icon: Icons.facebook,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.home);
                },
              ),
              const SizedBox(height: 12),

              // ปุ่ม Login Google
              SocialButton(
                label: 'CONTINUE WITH GOOGLE',
                icon: Icons.g_mobiledata,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.home);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
