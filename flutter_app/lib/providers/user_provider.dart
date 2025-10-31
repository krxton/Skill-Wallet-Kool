// lib/providers/user_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // import เพื่อเข้าถึง ChangeNotifier

class UserProvider with ChangeNotifier {
  // 1. ตัวแปรเก็บสถานะ (Private Fields)
  String? _currentParentId;
  String? _currentChildId;

  // 🆕 Hardcode ID ทดสอบใน Constructor
  UserProvider() {
    // ⚠️ HARDCODED TEST IDs (ใช้สำหรับการทดสอบเท่านั้น)
    _currentParentId = 'PR2';
    _currentChildId = 'CH2';
  }

  // 2. Getters
  String? get currentParentId => _currentParentId;
  String? get currentChildId => _currentChildId;
  bool get isAuthenticated => _currentParentId != null;

  // 3. ฟังก์ชันสำหรับกำหนดค่า (ใช้เมื่อ Login/Register จริง)
  void setParentAndChild(String parentId, String childId) {
    _currentParentId = parentId;
    _currentChildId = childId;
    notifyListeners();
  }

  // 4. ฟังก์ชันสำหรับอัปเดตคะแนน (Placeholder)
  Future<void> updateChildScore(String childId) async {
    // ... logic การเรียก API อัปเดตคะแนน
  }
}
