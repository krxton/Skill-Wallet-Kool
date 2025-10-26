import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SWKApp());
}

class SWKApp extends StatelessWidget {
  const SWKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Wallet Kool',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
    );
  }
}
