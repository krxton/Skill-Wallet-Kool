import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. ส่วนข้อมูล ID (Child/Parent ID)
  // ==========================================
  String? _currentChildId; // ไม่ hardcode แล้ว - จะดึงจาก database
  String? _currentParentId;
  List<Map<String, dynamic>> _children = []; // เก็บ children ทั้งหมด

  String? get currentChildId => _currentChildId;
  String? get currentParentId => _currentParentId;
  List<Map<String, dynamic>> get children => _children;

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

  /// 3.1 ดึงข้อมูล Children จาก Database
  Future<void> fetchChildrenData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId != null) {
        // ดึง parent_id ก่อน
        final parentData = await _supabase
            .from('parent')
            .select('parent_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (parentData != null) {
          final parentId = parentData['parent_id'];
          _currentParentId = parentId?.toString();

          // ดึง children ของ parent นี้
          final childrenResponse = await _supabase
              .from('parent_and_child')
              .select('child_id, relationship, child!inner(child_id, name_surname, wallet, birthday)')
              .eq('parent_id', parentId);

          if (childrenResponse.isNotEmpty) {
            _children = List<Map<String, dynamic>>.from(childrenResponse);

            // ตั้งค่า currentChildId เป็นเด็กคนแรก (หรือจะให้ user เลือกก็ได้)
            if (_children.isNotEmpty && _children[0]['child'] != null) {
              _currentChildId = _children[0]['child']['child_id'];
              debugPrint('✅ Child ID set to: $_currentChildId');
            }

            notifyListeners();
          } else {
            debugPrint('⚠️ No children found for parent: $parentId');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ fetchChildrenData error: $e');
    }
  }

  /// 3.2 เพิ่มเด็กใหม่ (ใช้ RPC function เพื่อ bypass RLS)
  Future<bool> addChild({
    required String name,
    required DateTime birthday,
    String? relationship,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('❌ Add child failed: No authenticated user');
        return false;
      }

      // ใช้ RPC function ที่มี SECURITY DEFINER เพื่อ bypass RLS
      final result = await _supabase.rpc('create_child_and_link', params: {
        'p_name_surname': name,
        'p_birthday': birthday.toIso8601String(),
        'p_wallet': 0,
        'p_relationship': relationship ?? 'พ่อ/แม่',
      });

      debugPrint('✅ RPC create_child_and_link result: $result');

      // Refresh children list
      await fetchChildrenData();

      debugPrint('✅ Child added successfully');
      return true;
    } catch (e) {
      debugPrint('❌ addChild error: $e');

      // ตรวจสอบประเภท error
      final errorMsg = e.toString();
      if (errorMsg.contains('row-level security policy')) {
        debugPrint('⚠️ RLS policy blocking insert. Need to update RLS policies in Supabase.');
      } else if (errorMsg.contains('function') && errorMsg.contains('does not exist')) {
        debugPrint('⚠️ RPC function create_child_and_link does not exist in Supabase.');
        debugPrint('📝 กรุณาสร้าง function นี้ใน Supabase SQL Editor:');
        debugPrint('''
CREATE OR REPLACE FUNCTION create_child_and_link(
  p_name_surname TEXT,
  p_birthday TEXT,
  p_wallet INTEGER DEFAULT 0,
  p_relationship TEXT DEFAULT 'พ่อ/แม่'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  v_child_id UUID;
  v_parent_id UUID;
BEGIN
  -- Get parent_id from current user
  SELECT parent_id INTO v_parent_id
  FROM parent
  WHERE user_id = auth.uid();

  IF v_parent_id IS NULL THEN
    RAISE EXCEPTION 'Parent not found for current user';
  END IF;

  -- Insert child
  INSERT INTO child (name_surname, birthday, wallet)
  VALUES (p_name_surname, p_birthday::DATE, p_wallet)
  RETURNING child_id INTO v_child_id;

  -- Link parent and child
  INSERT INTO parent_and_child (parent_id, child_id, relationship)
  VALUES (v_parent_id, v_child_id, p_relationship);

  RETURN json_build_object('child_id', v_child_id, 'success', true);
END;
\$\$;
        ''');
      }

      return false;
    }
  }

  /// 3.3 แก้ไขข้อมูลเด็ก
  Future<bool> updateChild({
    required String childId,
    String? name,
    DateTime? birthday,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name_surname'] = name;
      if (birthday != null) updates['birthday'] = birthday.toIso8601String();

      if (updates.isEmpty) {
        debugPrint('⚠️ No updates provided');
        return false;
      }

      await _supabase.from('child').update(updates).eq('child_id', childId);

      // Refresh children list
      await fetchChildrenData();

      debugPrint('✅ Child updated successfully: $childId');
      return true;
    } catch (e) {
      debugPrint('❌ updateChild error: $e');
      return false;
    }
  }

  /// 3.4 ลบเด็ก
  Future<bool> deleteChild(String childId) async {
    try {
      // 1. ลบจาก parent_and_child table ก่อน (foreign key constraint)
      await _supabase
          .from('parent_and_child')
          .delete()
          .eq('child_id', childId)
          .eq('parent_id', _currentParentId!);

      // 2. ลบจาก child table
      await _supabase.from('child').delete().eq('child_id', childId);

      // 3. ถ้าลบเด็กที่กำลังเลือกอยู่ ให้เคลียร์ currentChildId
      if (_currentChildId == childId) {
        _currentChildId = null;
      }

      // 4. Refresh children list
      await fetchChildrenData();

      debugPrint('✅ Child deleted successfully: $childId');
      return true;
    } catch (e) {
      debugPrint('❌ deleteChild error: $e');
      return false;
    }
  }

  /// 3.5 เลือกเด็กที่จะใช้งาน
  void selectChild(String childId) {
    _currentChildId = childId;
    notifyListeners();
    debugPrint('✅ Child selected: $childId');
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
    _currentChildId = null;
    _children = [];
    _profileImageBytes = null;
    notifyListeners();
  }
}
