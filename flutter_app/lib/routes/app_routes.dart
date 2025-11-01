// lib/routes/app_routes.dart (ฉบับสมบูรณ์ที่แก้ไขโครงสร้าง)

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
import '../models/activity.dart';
import '../screens/language_detail_screen.dart'; // 🆕 Import หน้าจอ Language Detail

class AppRoutes {
  // core
  static const String home = '/';
  static const String welcome = '/welcome';

  // auth / onboarding
  static const String login = '/login';
  static const String register = '/register';

  // others
  static const String languageHub = '/language-hub';
  static const String languageList = '/language-list';
  static const String itemIntro = '/item-intro';
  static const String record = '/record';
  static const String result = '/result';
  static const String videoDetail = '/video-detail';
  static const String languageDetail = '/language-detail'; // 🆕 ชื่อ Route ใหม่

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        welcome: (_) => const WelcomeScreen(),
        home: (_) => const HomeScreen(),

        // auth
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),

        // อื่น ๆ
        languageHub: (_) => const LanguageHubScreen(),
        languageList: (_) => const LanguageListScreen(),
        // ⚠️ ItemIntroScreen ควรถูกแก้ไขให้รับ Activity Model ใน Constructor
        itemIntro: (_) => const ItemIntroScreen(),
        record: (_) => const RecordScreen(),
        result: (_) => const ResultScreen(),

        // 1. Route สำหรับ VideoDetailScreen
        videoDetail: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return VideoDetailScreen(
            activity: activity,
          );
        },

        // 2. 🆕 Route สำหรับ LanguageDetailScreen (แก้ไขโครงสร้าง)
        languageDetail: (context) {
          // รับ Activity Object โดยตรง
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;

          return LanguageDetailScreen(
            activity: activity,
          );
        },
      };
}
