// lib/main.dart (ฉบับแก้ไข)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ เพิ่มบรรทัดนี้
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'package:media_kit/media_kit.dart';

// ✅ เปลี่ยนเป็น async เพื่อรอ dotenv โหลด
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // ✅ โหลด .env file ก่อนรันแอป
  await dotenv.load(fileName: ".env");

  // Debug: ดูว่าโหลดสำเร็จหรือไม่ (ลบออกได้หลังทดสอบ)
  print('🔧 API_BASE_URL: ${dotenv.env['API_BASE_URL']}');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
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
      theme: AppTheme.light(),
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
    );
  }
}
