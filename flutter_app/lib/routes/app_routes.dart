// lib/routes/app_routes.dart

import 'package:flutter/material.dart';

// --- Auth & Core Screens ---
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';

// --- Activities & Hubs ---
import '../screens/activities/hub/language_hub_screen.dart';
import '../screens/activities/listing/language_list_screen.dart';
import '../screens/activities/gameplay/item_intro_screen.dart';
import '../screens/activities/gameplay/record_screen.dart';
import '../screens/activities/gameplay/result_screen.dart';
import '../models/activity.dart';
import '../screens/activities/detail/physical_video_screen.dart';
import '../screens/activities/detail/language_detail_screen.dart';
import '../screens/activities/detail/physical_detail_screen.dart';
import '../screens/activities/detail/analysis_activity_screen.dart';

// --- Calculation Screens ---
import '../screens/activities/hub/calculate_hub_screen.dart';
import '../screens/activities/hub/plus_screen.dart';
import '../screens/activities/hub/answer_plus_screen.dart';
import '../screens/activities/hub/problems_solve_screen.dart';
import '../screens/activities/hub/problem_detail_screen.dart';
import '../screens/activities/hub/problem_answer_screen.dart';
import '../screens/activities/hub/problem_playing_screen.dart';

// --- Child Management Screens ---
import '../screens/child/child_setting_screen.dart';
import '../screens/child/add_child_screen.dart';

class AppRoutes {
  // --- Core Routes ---
  static const String home = '/';
  static const String welcome = '/welcome';

  // --- Auth Routes ---
  static const String login = '/login';
  static const String register = '/register';

  // --- Activity Routes ---
  static const String languageHub = '/language-hub';
  static const String languageList = '/language-list';
  static const String itemIntro = '/item-intro';
  static const String record = '/record';
  static const String result = '/result';
  static const String videoDetail = '/video-detail';
  static const String languageDetail = '/language-detail';
  static const String physicalActivity = '/physical-activity';
  static const String analysisActivity = '/analysis-activity';

  // --- Calculation Hub Routes ---
  static const String calculateHub = '/calculate-hub';

  // Plus (Math) Routes
  static const String plusPage = '/plus-page';
  static const String answerPlus = '/answer-plus';

  // Problems Solve Routes
  static const String problemsSolve = '/problems-solve';
  static const String problemDetail = '/problem-detail';
  static const String problemAnswer = '/problem-answer';
  static const String problemPlaying = '/problem-playing';

  // --- Child Management Routes ---
  static const String childSetting = '/child-setting';
  static const String addChild = '/add-child';

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        // Core
        welcome: (_) => const WelcomeScreen(),
        home: (_) => const HomeScreen(),

        // Auth
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),

        // Activities
        languageHub: (_) => const LanguageHubScreen(),
        languageList: (_) => const LanguageListScreen(),

        // Item Intro
        itemIntro: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args == null || args is! Activity) {
            return const Scaffold(
              body: Center(
                child: Text('No Activity data passed to ItemIntroScreen'),
              ),
            );
          }
          return ItemIntroScreen(activity: args);
        },

        record: (_) => const RecordScreen(),

        // Detail Screens
        videoDetail: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return PhysicalVideoScreen(activity: activity);
        },
        languageDetail: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return LanguageDetailScreen(activity: activity);
        },
        physicalActivity: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return PhysicalDetailScreen(activity: activity);
        },
        analysisActivity: (context) {
          final activity =
              ModalRoute.of(context)!.settings.arguments as Activity;
          return AnalysisActivityScreen(activity: activity);
        },

        // --- Calculation Section ---
        calculateHub: (_) => const CalculateHubScreen(),
        plusPage: (_) => const PlusScreen(),
        answerPlus: (_) => const AnswerPlusScreen(),
        problemsSolve: (_) => const ProblemsSolveScreen(),
        problemDetail: (_) => const ProblemDetailScreen(),
        problemAnswer: (_) => const ProblemAnswerScreen(),
        problemPlaying: (_) => const ProblemPlayingScreen(),

        // --- Child Management Section ---
        childSetting: (_) => const ChildSettingScreen(),
        addChild: (_) => const AddChildScreen(),

        // Result
        result: (_) => const ResultScreen(),
      };
}
