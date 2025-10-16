import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goSignIn(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.signin);
  }

  void _goLogin(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.login);
  }

  void _goHome(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 24),

              // โลโก้ / รูป
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/SWK_home.png',
                width: 220,
                height: 220,
                fit: BoxFit.cover,
                ),
              ),


              // ปุ่ม
              Column(
                children: [
                  PrimaryButton(
                    label: 'Play',
                    onPressed: () => _goHome(context),   // <-- ไปหน้า Home
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => _goSignIn(context),
                        child: const Text('SIGN-IN', style: TextStyle(color: Colors.redAccent)),
                      ),
                      TextButton(
                        onPressed: () => _goLogin(context),
                        child: const Text('LOG IN', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
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
