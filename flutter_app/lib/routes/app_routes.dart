// lib/routes/app_routes.dart

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
import '../screens/video_detail_screen.dart';
import '../models/activity.dart'; // 🆕 ต้อง Import Activity Model

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
  static const String videoDetail = '/video-detail';

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
          // 🆕 เปลี่ยนไปรับ Activity Object โดยตรง
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;

          return VideoDetailScreen(
            // 🆕 ส่ง Activity Object ไปยัง Constructor
            activity: activity,
          );
        },
      };
}
