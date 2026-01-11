import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
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

class SWKApp extends StatefulWidget {
  const SWKApp({super.key});

  @override
  State<SWKApp> createState() => _SWKAppState();

  static _SWKAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_SWKAppState>();
}

class _SWKAppState extends State<SWKApp> {
  Locale _locale = const Locale('en');

  // 2. Public method to change the locale
  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Wallet Kool',
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.welcome,
      routes: AppRoutes.routes,
    );
  }
}
