import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  // 3.1 อัปเดตชื่อใน Supabase (parent.name_surname)
  // ==========================================
  Future<bool> updateParentName(String name) async {
    try {
      final supabase = Supabase.instance.client;

      // ค้นหา row ของผู้ปกครองปัจจุบัน (อาศัย RLS จำกัดให้เห็นเฉพาะของตัวเอง)
      final parentRow =
          await supabase.from('parent').select('id').maybeSingle();

      if (parentRow == null || parentRow['id'] == null) {
        return false;
      }

      final parentId = parentRow['id'];

      // อัปเดตชื่อในตาราง parent
      await supabase
          .from('parent')
          .update({'name_surname': name}).eq('id', parentId);

      // อัปเดตค่าใน Provider ด้วย
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
  // 5. ฟังก์ชันล้างค่า (แก้ Error: clearUserData)
  // ==========================================
  void clearUserData() {
    _currentParentName = 'PARENT2';
    _profileImageBytes = null;
    // _currentChildId = null; // ถ้าต้องการล้าง ID ด้วยให้เอา comment ออก
    // _currentParentId = null;
    notifyListeners();
  }
}
