import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';


void main() => runApp(const SWKApp());

class SWKApp extends StatelessWidget {
  const SWKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.welcome,
        routes: {
          AppRoutes.welcome: (_) => const WelcomeScreen(),
          AppRoutes.signin: (_) => const SignInScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.login: (_) => const LoginScreen(),   
          AppRoutes.home: (_) => const HomeScreen(),     
        },

    );
  }
}
