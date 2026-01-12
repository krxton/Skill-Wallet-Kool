import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // ✅ เพิ่ม
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // ✅ Initialize - เช็คว่ามี session อยู่แล้วไหม
  Future<void> initialize() async {
    _isLoading = true;
    // ✅ ใช้ SchedulerBinding เพื่อรอให้ frame ปัจจุบันเสร็จก่อน
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final user = await _storage.getUser();
      if (user != null) {
        // ตรวจสอบ session ยังใช้งานได้ไหม
        final session = await _authService.getSession();
        if (session != null) {
          _user = session.user;
          _isAuthenticated = true;
        } else {
          // Session หมดอายุ
          await _storage.clearAll();
        }
      }
    } catch (e) {
      print('Initialize error: $e');
    }

    _isLoading = false;
    // ✅ ใช้ SchedulerBinding เพื่อรอให้ frame ปัจจุบันเสร็จก่อน
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // ✅ Sign Up with Email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      if (response != null) {
        _user = response.user;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Sign up error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ✅ Sign In with Email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response != null) {
        _user = response.user;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Sign in error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ✅ Sign In with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = await _authService.signInWithGoogle();
      // URL จะถูก launch ใน service
      // รอ callback จาก deep link
      return url != null;
    } catch (e) {
      print('Google sign in error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ Sign In with Facebook
  Future<bool> signInWithFacebook() async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = await _authService.signInWithFacebook();
      return url != null;
    } catch (e) {
      print('Facebook sign in error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ Handle OAuth Callback
  Future<bool> handleOAuthCallback(Uri uri) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.handleOAuthCallback(uri);

      if (response != null) {
        _user = response.user;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('OAuth callback error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ✅ Sign Out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authService.signOut();

    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
  }

  // ✅ Refresh User Data
  Future<void> refreshUser() async {
    try {
      final session = await _authService.getSession();
      if (session != null) {
        _user = session.user;
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Refresh user error: $e');
    }
  }
}
