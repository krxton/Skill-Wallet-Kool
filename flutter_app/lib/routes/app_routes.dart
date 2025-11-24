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
import '../models/activity.dart';
import '../screens/language_detail_screen.dart';
import '../screens/physical_activity.dart';

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
  static const String languageDetail = '/language-detail';
  static const String physicalActivity = '/physical-activity';

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        welcome: (_) => const WelcomeScreen(),
        home: (_) => const HomeScreen(),

        // auth
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),

        // อื่น ๆ
        languageHub: (_) => const LanguageHubScreen(),
        languageList: (_) => const LanguageListScreen(),

        // ✅ itemIntro: กัน null / type ผิด ไม่ให้แครช
        itemIntro: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args == null || args is! Activity) {
            // ถ้าไม่มี Activity ส่งมา หรือส่งชนิดอื่น → ไม่แครช แต่แจ้งเตือน
            return const Scaffold(
              body: Center(
                child: Text('No Activity data passed to ItemIntroScreen'),
              ),
            );
          }

          final activity = args as Activity;

          return ItemIntroScreen(
            activity: activity,
          );
        },

        record: (_) => const RecordScreen(),

        // VideoDetailScreen
        videoDetail: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return VideoDetailScreen(
            activity: activity,
          );
        },

        // LanguageDetailScreen
        languageDetail: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return LanguageDetailScreen(
            activity: activity,
          );
        },

        // PhysicalActivityScreen
        physicalActivity: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return PhysicalActivityScreen(
            activity: activity,
          );
        },

        // ResultScreen – รับ args เป็น Map<String, dynamic>
        result: (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;

          return ResultScreen(
              // ResultScreen ดึง args ผ่าน ModalRoute เองแล้ว
              );
        },
      };
}
