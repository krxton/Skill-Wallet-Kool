import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../widgets/social_button.dart';
import '../widgets/primary_button.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BACK (มุมซ้ายล่างตามม็อก เดี๋ยววางไว้บนสุดเพื่อให้กดง่าย)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('← BACK',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),

              // Title
              Text('SIGN-IN TO', style: Theme.of(context).textTheme.titleMedium),
              Text(
                'SKILL WALLET KOOL',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 24),

              // ปุ่ม Social
              SocialButton(
                label: 'CONTINUE WITH FACEBOOK',
                icon: Icons.facebook,
                onPressed: () {
                  // TODO: เชื่อมจริงภายหลัง
                },
              ),
              const SizedBox(height: 12),
              SocialButton(
                label: 'CONTINUE WITH GOOGLE',
                icon: Icons.g_mobiledata,
                onPressed: () {
                  // TODO: เชื่อมจริงภายหลัง
                },
              ),

              const Spacer(),

              // ปุ่ม NEXT (สีเขียวตามม็อก)
              PrimaryButton(
                label: 'Next',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                color: const Color(0xFF5DBB63), // leaf
              ),
            ],
          ),
        ),
      ),
    );
  }
}
