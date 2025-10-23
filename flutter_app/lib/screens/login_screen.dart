import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../widgets/social_button.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← BACK', style: TextStyle(color: AppTheme.pink)),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Welcome Back!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.pink)),
              ),
              const SizedBox(height: 32),
              SocialButton(label: 'CONTINUE WITH FACEBOOK', icon: Icons.facebook, onPressed: () {
                Navigator.pushNamed(context, AppRoutes.home);
              }),
              const SizedBox(height: 12),
              SocialButton(label: 'CONTINUE WITH GOOGLE', icon: Icons.g_mobiledata, onPressed: () {
                Navigator.pushNamed(context, AppRoutes.home);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
