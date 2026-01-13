// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();

  String get apiBaseUrl =>
      "${dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000/api'}/auth";

  // ✅ Sign Up with Email
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final url = Uri.parse("$apiBaseUrl/sign-up/email");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);

        // Save token and user
        if (authResponse.token != null) {
          await _storage.saveToken(authResponse.token!);
          await _storage.saveUser(authResponse.user);
        }

        return authResponse;
      } else {
        print('Sign up error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Sign up exception: $e');
      return null;
    }
  }

  // ✅ Sign In with Email
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse("$apiBaseUrl/sign-in/email");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);

        // Save token and user
        if (authResponse.token != null) {
          await _storage.saveToken(authResponse.token!);
          await _storage.saveUser(authResponse.user);
        }

        return authResponse;
      } else {
        print('Sign in error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Sign in exception: $e');
      return null;
    }
  }

  // ✅ Sign In/Up with Google
  Future<String?> signInWithGoogle() async {
    try {
      final url = Uri.parse("$apiBaseUrl/sign-in/social");

      print(url);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'provider': 'google',
          'callbackURL': 'skillwalletkool://auth-callback',
        }),
      );
      print(response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authUrl = data['url'] as String?;

        if (authUrl != null) {
          // Launch browser for OAuth
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            return authUrl;
          }
        }
      }
      return null;
    } catch (e) {
      print('Google sign in exception: $e');
      return null;
    }
  }

  // ✅ Sign In/Up with Facebook
  Future<String?> signInWithFacebook() async {
    try {
      final url = Uri.parse("$apiBaseUrl/sign-in/social");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'provider': 'facebook',
          'callbackURL': 'skillwalletkool://auth-callback',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authUrl = data['url'] as String?;

        if (authUrl != null) {
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            return authUrl;
          }
        }
      }
      return null;
    } catch (e) {
      print('Facebook sign in exception: $e');
      return null;
    }
  }

  // ✅ Handle OAuth Callback (จาก deep link)
  Future<AuthResponse?> handleOAuthCallback(Uri callbackUri) async {
    try {
      // Better Auth จะ redirect กลับมาพร้อม session
      // เราต้องเรียก get-session เพื่อดึงข้อมูล user
      return await getSession();
    } catch (e) {
      print('OAuth callback error: $e');
      return null;
    }
  }

  // ✅ Get Current Session
  Future<AuthResponse?> getSession() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return null;

      final url = Uri.parse("$apiBaseUrl/get-session");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);

        // Update stored user
        await _storage.saveUser(user);

        return AuthResponse(
          token: token,
          user: user,
        );
      } else {
        // Token invalid, clear storage
        await _storage.clearAll();
        return null;
      }
    } catch (e) {
      print('Get session exception: $e');
      return null;
    }
  }

  // ✅ Sign Out
  Future<bool> signOut() async {
    try {
      final token = await _storage.getToken();

      if (token != null) {
        final url = Uri.parse("$apiBaseUrl/sign-out");
        await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      }

      // Clear local storage
      await _storage.clearAll();
      return true;
    } catch (e) {
      print('Sign out exception: $e');
      // Clear anyway
      await _storage.clearAll();
      return false;
    }
  }

  // ✅ Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    if (token == null) return false;

    // Verify token is still valid
    final session = await getSession();
    return session != null;
  }

  // ✅ Get current user
  Future<User?> getCurrentUser() async {
    return await _storage.getUser();
  }
}
