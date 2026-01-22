import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. ส่วนข้อมูล ID (Child/Parent ID)
  // ==========================================
  String? _currentChildId = 'CHILD_001'; // ปรับตามการใช้งานจริงของคุณ
  String? _currentParentId = '';

  String? get currentChildId => _currentChildId;
  String? get currentParentId => _currentParentId;

  void setChildId(String id) {
    _currentChildId = id;
    notifyListeners();
  }

  void setParentId(String id) {
    _currentParentId = id;
    notifyListeners();
  }

  // ==========================================
  // 2. ส่วนชื่อผู้ปกครอง (Parent Name)
  // ==========================================
  // ปรับจาก 'PARENT2' เป็นค่าว่าง เพื่อรอรับข้อมูลจริงจาก Google หรือ Database
  String? _currentParentName = '';

  String? get currentParentName => _currentParentName;

  /// ใช้สำหรับอัปเดตค่าในแอปทันที (เช่น ตอน Google Login สำเร็จ)
  void setParentName(String name) {
    _currentParentName = name;
    notifyListeners();
  }

  // ==========================================
  // 3. ฟังก์ชันจัดการข้อมูลใน Database (Supabase)
  // ==========================================
  Future<void> fetchParentData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId != null) {
        final data = await _supabase
            .from('parent')
            .select('name_surname, parent_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (data != null) {
          _currentParentName = data['name_surname'] ?? '';
          _currentParentId = data['parent_id']?.toString();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('fetchParentData error: $e');
    }
  }

  Future<bool> updateParentName(String name) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('Update failed: No authenticated user found.');
        return false;
      }

      await _supabase
          .from('parent')
          .update({'name_surname': name}).eq('user_id', userId);

      _currentParentName = name;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('updateParentName error: $e');
      return false;
    }
  }

  // ==========================================
  // 4. ส่วนรูปโปรไฟล์ (Profile Image)
  // ==========================================
  Uint8List? _profileImageBytes;

  Uint8List? get profileImageBytes => _profileImageBytes;

  void setProfileImage(Uint8List? bytes) {
    _profileImageBytes = bytes;
    notifyListeners();
  }

  // ==========================================
  // 5. ฟังก์ชันล้างค่า (ใช้ตอน Logout)
  // ==========================================
  void clearUserData() {
    _currentParentName = '';
    _currentParentId = '';
    _profileImageBytes = null;
    // _currentChildId = null;
    notifyListeners();
  }
}
