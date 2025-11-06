// lib/providers/user_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // import เพื่อเข้าถึง ChangeNotifier

class UserProvider with ChangeNotifier {
  // 1. ตัวแปรเก็บสถานะ (Private Fields)
  String? _currentParentId;
  String? _currentChildId;
  String? _currentParentName;
  String? _currentChildName;

  // 🆕 Hardcode ID และชื่อทดสอบใน Constructor
  UserProvider() {
    // ⚠️ HARDCODED TEST DATA (ใช้สำหรับการทดสอบเท่านั้น)
    _currentParentId = 'PR2';
    _currentChildId = 'CH2';
    _currentParentName = 'Parent2'; // ⬅️ ชื่อผู้ปกครองทดสอบ
    _currentChildName = 'Child2'; // ⬅️ ชื่อเด็กทดสอบ
  }

  // 2. Getters
  String? get currentParentId => _currentParentId;
  String? get currentChildId => _currentChildId;
  String? get currentParentName => _currentParentName;
  String? get currentChildName => _currentChildName;
  bool get isAuthenticated => _currentParentId != null;

  // 3. ฟังก์ชันสำหรับกำหนดค่า (ใช้เมื่อ Login/Register จริง)
  void setParentAndChild(
    String parentId,
    String childId, {
    String? parentName,
    String? childName,
  }) {
    _currentParentId = parentId;
    _currentChildId = childId;
    _currentParentName = parentName;
    _currentChildName = childName;
    notifyListeners();
  }

  // 4. ฟังก์ชันสำหรับอัปเดตเฉพาะชื่อ (Optional - กรณีต้องการเปลี่ยนชื่อแยก)
  void updateNames({String? parentName, String? childName}) {
    if (parentName != null) _currentParentName = parentName;
    if (childName != null) _currentChildName = childName;
    notifyListeners();
  }

  // 5. ฟังก์ชันสำหรับ Logout
  void logout() {
    _currentParentId = null;
    _currentChildId = null;
    _currentParentName = null;
    _currentChildName = null;
    notifyListeners();
  }

  // 6. ฟังก์ชันสำหรับอัปเดตคะแนน (Placeholder)
  Future<void> updateChildScore(String childId) async {
    // ... logic การเรียก API อัปเดตคะแนน
  }
}
