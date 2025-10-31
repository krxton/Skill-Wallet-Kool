// lib/routes/app_routes.dart (ฉบับแก้ไข)

import 'package:flutter/material.dart';

import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/language_hub_screen.dart';
import '../screens/language_list_screen.dart';
import '../screens/item_intro_screen.dart';
import '../screens/record_screen.dart';
import '../screens/result_screen.dart';
import '../screens/video_detail_screen.dart'; // 🆕 Import หน้าจอใหม่

class AppRoutes {
  // core
  static const String home = '/';
  static const String welcome = '/welcome';

  // auth / onboarding
  static const String login = '/login';
  static const String register = '/register';

  // others (เผื่อใช้ต่อ)
  static const String languageHub = '/language-hub';
  static const String languageList = '/language-list';
  static const String itemIntro = '/item-intro';
  static const String record = '/record';
  static const String result = '/result';
  static const String videoDetail = '/video-detail'; // 🆕 เพิ่มชื่อ Route

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        welcome: (_) => const WelcomeScreen(),
        home: (_) => const HomeScreen(),

        // auth
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),

        // อื่น ๆ
        languageHub: (_) => const LanguageHubScreen(),
        languageList: (_) => const LanguageListScreen(),
        itemIntro: (_) => const ItemIntroScreen(),
        record: (_) => const RecordScreen(),
        result: (_) => const ResultScreen(),

        // 🆕 Route สำหรับ VideoDetailScreen
        videoDetail: (context) {
          // รับ Arguments ที่ถูกส่งมาในรูปแบบ Map<String, String>
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, String>;

          return VideoDetailScreen(
            // ดึงค่า htmlContent และ title ออกจาก Map
            htmlContent: args['htmlContent']!,
            title: args['title']!,
          );
        },
      };
}
