import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'services/deep_link_service.dart';
import 'services/storage_service.dart';
import 'services/mock_auth_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // ✅ โหลด .env file
  await dotenv.load(fileName: ".env");

  // ✅ Initialize Hive Storage
  await StorageService().init();

  print('🔧 API_BASE_URL: ${dotenv.env['API_BASE_URL']}');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 🔧 Developer Mode Check
  MockAuthService.printDebugInfo();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // ✅ เรียกหลัง frame แรกเสร็จ เพื่อหลีกเลี่ยง rebuild ระหว่าง build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  // ✅ Initialize App + Deep Links
  Future<void> _initializeApp() async {
    if (!mounted) return; // เช็คว่า widget ยังอยู่หรือไม่

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // 1. เช็คว่ามี session เดิมอยู่หรือไม่
    await authProvider.initialize();

    // 1.1 หลัง initialize สำเร็จ: ดึงชื่อผู้ปกครองจาก Supabase แล้วตั้งใน UserProvider
    //ต้องรีสตาทชื่อจากdatabaseถึงจะขึ้นชื่อใหม่
    await _populateParentNameFromSupabase();

    // 2. Deep Links (เฉพาะ Mobile/Desktop ที่รองรับ)
    // ✅ Skip สำหรับ Windows/Web (uni_links ไม่รองรับ)
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      try {
        // เช็คว่าแอปเปิดจาก deep link หรือไม่ (cold start)
        final initialUri = await _deepLinkService.getInitialLink();
        if (initialUri != null && mounted) {
          _handleDeepLink(initialUri);
        }

        // ฟัง deep links ที่เข้ามาตอนแอปเปิดอยู่ (warm start)
        _deepLinkService.startListening((uri) {
          if (mounted) {
            _handleDeepLink(uri);
          }
        });
      } catch (e) {
        print('⚠️ Deep links not supported on this platform: $e');
      }
    } else {
      print('ℹ️ Deep links skipped for ${defaultTargetPlatform.name}');
    }
  }

  // ✅ ดึงชื่อผู้ปกครองจาก API แล้วตั้งใน UserProvider
  Future<void> _populateParentNameFromSupabase() async {
    if (!mounted) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final apiService = ApiService();
      final result = await apiService.get('/parents/me');

      final parentName = result['nameSurname'] as String?;

      if (parentName != null && parentName.isNotEmpty) {
        userProvider.setParentName(parentName);
        print('👤 Parent name set: $parentName');

        await userProvider.fetchChildrenData();
      }
    } catch (e) {
      print('⚠️ Fetch parent name failed: $e');
    }
  }

  // ✅ Handle Deep Link Callback from OAuth
  void _handleDeepLink(Uri uri) {
    print('📱 Handling deep link: $uri');
    print('🔍 Scheme: ${uri.scheme}');
    print('🔍 Host: ${uri.host}');
    print('🔍 Query: ${uri.query}');

    // เช็คว่าเป็น OAuth callback หรือไม่
    if (uri.scheme == 'skillwalletkool' && uri.host == 'auth-callback') {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      authProvider.handleOAuthCallback(uri).then((success) {
        if (success && mounted) {
          print('✅ OAuth login successful');
          // หลัง login สำเร็จ: ตั้งชื่อผู้ปกครองจาก Supabase
          _populateParentNameFromSupabase();
          // Navigate จะถูกจัดการโดย AuthWrapper
        } else {
          print('❌ OAuth login failed');
          // แสดง error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _deepLinkService.stopListening();
    super.dispose();
  }

  // Public method to change the locale
  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ สร้าง routes ใหม่โดยไม่มี '/' (home route)
    final appRoutes = Map<String, WidgetBuilder>.from(AppRoutes.routes);
    appRoutes.remove('/'); // ลบ home route ออกเพื่อไม่ให้ซ้ำ

    return MaterialApp(
      title: 'SkillWalletKool',
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthWrapper(), // ✅ ใช้ home แทน initialRoute
      routes: appRoutes, // ✅ ใช้ routes ที่ลบ '/' ออกแล้ว
    );
  }
}

// ✅ AuthWrapper - ตรวจสอบสถานะ login
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // ถ้าเปิด Developer Mode ให้สร้าง mock session
    if (MockAuthService.isDeveloperMode) {
      try {
        await MockAuthService.createMockSession();
        // ตั้งชื่อ parent ใน UserProvider
        if (mounted) {
          context.read<UserProvider>().setParentName('Developer (Mock User)');
        }
        setState(() {
          _isAuthenticated = true;
          _isInitialized = true;
        });
        return;
      } catch (e) {
        print('⚠️ Error initializing developer mode: $e');
      }
    }

    // ✅ ตรวจสอบ session จากทั้ง Supabase และ Custom API
    bool authenticated = false;

    // 1. ตรวจสอบ Supabase session ก่อน
    final supabase = Supabase.instance.client;
    final supabaseSession = supabase.auth.currentSession;
    if (supabaseSession != null) {
      authenticated = true;
      debugPrint('✅ Found Supabase session');
    }

    // 2. ถ้าไม่มี Supabase session ให้ตรวจสอบ token ใน storage
    if (!authenticated) {
      try {
        final storageService = StorageService();
        final token = await storageService.getToken();
        if (token != null && mounted) {
          // มี token ใน storage ให้ลอง validate
          final authProvider = context.read<AuthProvider>();
          await authProvider.initialize();
          authenticated = authProvider.isAuthenticated;
          debugPrint('✅ Token validation result: $authenticated');
        }
      } catch (e) {
        debugPrint('⚠️ Token validation error: $e');
      }
    }

    // 3. ถ้า authenticated แล้วให้ดึงข้อมูล children
    if (authenticated && mounted) {
      final userProvider = context.read<UserProvider>();
      await userProvider.fetchChildrenData();
    }

    if (mounted) {
      setState(() {
        _isAuthenticated = authenticated;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // รอให้ initialize เสร็จก่อน
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 🔧 Developer Mode: Bypass authentication
    if (MockAuthService.isDeveloperMode) {
      return const HomeScreen();
    }

    // ✅ ใช้ค่า _isAuthenticated ที่ตรวจสอบแล้ว
    if (_isAuthenticated) {
      return const HomeScreen();
    }

    // ถ้ายังไม่ login ไปหน้า Welcome
    return const WelcomeScreen();
  }
}
