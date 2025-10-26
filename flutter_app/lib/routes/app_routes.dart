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

class AppRoutes {
  // Main
  static const String home    = '/';
  static const String welcome = '/welcome';

  // Auth / Onboarding
  static const String login    = '/login';    // Login page (FB/Google + BACK)
  static const String register = '/register'; // Register flow (Step0 Social -> Step1 Additional)

  // Features
  static const String languageHub  = '/language-hub';
  static const String languageList = '/language-list';
  static const String itemIntro    = '/item-intro';
  static const String record       = '/record';
  static const String result       = '/result';

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
    // entry points
    welcome: (_)  => const WelcomeScreen(),
    home:    (_)  => const HomeScreen(),

    // auth
    login:    (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),

    // features (อยู่เหมือนเดิม)
    languageHub:  (_) => const LanguageHubScreen(),
    languageList: (_) => const LanguageListScreen(),
    itemIntro:    (_) => const ItemIntroScreen(),
    record:       (_) => const RecordScreen(),
    result:       (_) => const ResultScreen(),
  };
}
