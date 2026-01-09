import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  // ==========================================
  // 1. ส่วนข้อมูล ID (Child/Parent ID)
  // ==========================================
  String? _currentChildId = 'CHILD_001';
  String? _currentParentId = 'PARENT_001';

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
  String? _currentParentName = 'PARENT2';

  String? get currentParentName => _currentParentName;

  void setParentName(String name) {
    _currentParentName = name;
    notifyListeners();
  }

  // ==========================================
  // 3. ส่วนรูปโปรไฟล์ (Profile Image)
  // ==========================================
  Uint8List? _profileImageBytes;

  Uint8List? get profileImageBytes => _profileImageBytes;

  void setProfileImage(Uint8List? bytes) {
    _profileImageBytes = bytes;
    notifyListeners();
  }

  // ==========================================
  // 4. ฟังก์ชันล้างค่า (แก้ Error: clearUserData)
  // ==========================================
  void clearUserData() {
    _currentParentName = 'PARENT2';
    _profileImageBytes = null;
    // _currentChildId = null; // ถ้าต้องการล้าง ID ด้วยให้เอา comment ออก
    // _currentParentId = null;
    notifyListeners();
  }
}
