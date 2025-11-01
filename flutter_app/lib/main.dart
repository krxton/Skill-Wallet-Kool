// lib/main.dart (ฉบับแก้ไข)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🆕 ต้องเพิ่ม import Provider
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'providers/user_provider.dart'; // 🆕 Import UserProvider
import 'package:media_kit/media_kit.dart';
// import 'services/activity_service.dart'; // 🆕 Import ActivityService (ถ้าต้องการ Provider)

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // 🆕 ห่อหุ้มแอปด้วย MultiProvider เพื่อให้ UserProvider ใช้งานได้
  runApp(
    MultiProvider(
      providers: [
        // 1. ประกาศ UserProvider ที่นี่ (พร้อม Mock ID: PR2/CH2)
        ChangeNotifierProvider(create: (_) => UserProvider()),

        // 2. หากต้องการให้ ActivityService ใช้งานได้ทั่วถึง
        // Provider<ActivityService>(create: (_) => ActivityService()),
      ],
      // 3. ใช้ SWKApp เป็น Child
      child: const SWKApp(),
    ),
  );
}

class SWKApp extends StatelessWidget {
  const SWKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Wallet Kool',
      debugShowCheckedModeBanner: false,
      // ⚠️ หากคุณใช้ AppTheme.light() ต้องมั่นใจว่า theme/app_theme.dart มีอยู่
      theme: AppTheme.light(),
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
    );
  }
}
