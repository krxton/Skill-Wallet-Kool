// lib/services/child_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/child_model.dart';
import 'storage_service.dart';

class ChildService {
  final StorageService _storage = StorageService();

  String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000/api';

  // ✅ Get children for current parent
  Future<List<Child>> getChildren() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return [];

      final user = await _storage.getUser();
      if (user == null) return [];

      final url = Uri.parse("$apiBaseUrl/children?parentId=${user.id}");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data
            .map((json) => Child.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Get children error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Get children exception: $e');
      return [];
    }
  }

  // ✅ Add child
  Future<Child?> addChild({
    required String fullName,
    DateTime? dob,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final insertedChild =
          await supabase.rpc('create_child_and_link', params: {
        'p_name_surname': fullName,
        'p_birthday': dob?.toIso8601String() ?? '',
        'p_wallet': 0,
        'p_relationship': 'Parent & Child'
      });

      return Child.fromJson(insertedChild);

      // final token = await _storage.getToken();
      // if (token == null) return null;

      // final user = await _storage.getUser();
      // if (user == null) return null;

      // final url = Uri.parse("$apiBaseUrl/children");

      // final response = await http.post(
      //   url,
      //   headers: {
      //     "Content-Type": "application/json",
      //     "Authorization": "Bearer $token",
      //   },
      //   body: jsonEncode({
      //     'parentId': user.id,
      //     'fullName': fullName,
      //     if (dob != null) 'dob': dob.toIso8601String(),
      //   }),
      // );

      // if (response.statusCode == 200 || response.statusCode == 201) {
      //   final data = jsonDecode(response.body) as Map<String, dynamic>;
      //   return Child.fromJson(data);
      // } else {
      //   print('Add child error: ${response.statusCode} - ${response.body}');
      //   return null;
      // }
    } catch (e) {
      print('Add child exception: $e');
      return null;
    }
  }

  // ✅ Add multiple children
  Future<List<Child>> addChildren(
      List<Map<String, dynamic>> childrenData) async {
    List<Child> addedChildren = [];

    for (var childData in childrenData) {
      // แก้ไข: Parse String เป็น DateTime ถ้าเป็น String, หรือใช้ DateTime โดยตรงถ้าเป็น DateTime
      DateTime? dob;
      final dobData = childData['dob'];
      if (dobData is String) {
        dob = DateTime.tryParse(dobData);
      } else if (dobData is DateTime) {
        dob = dobData;
      }

      final child = await addChild(
        fullName: childData['fullName'] as String,
        dob: dob,
      );

      if (child != null) {
        addedChildren.add(child);
      }
    }

    return addedChildren;
  }

  // ✅ Update child
  Future<Child?> updateChild({
    required String childId,
    String? fullName,
    DateTime? dob,
  }) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return null;

      final url = Uri.parse("$apiBaseUrl/children/$childId");

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          if (fullName != null) 'fullName': fullName,
          if (dob != null) 'dob': dob.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Child.fromJson(data);
      } else {
        print('Update child error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Update child exception: $e');
      return null;
    }
  }

  // ✅ Delete child
  Future<bool> deleteChild(String childId) async {
    try {
      final token = await _storage.getToken();
      if (token == null) return false;

      final url = Uri.parse("$apiBaseUrl/children/$childId");

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Delete child exception: $e');
      return false;
    }
  }

  // =====================================================
  // ACTIVITY HISTORY (ใช้ตาราง activity_record)
  // =====================================================

  /// ดึงประวัติกิจกรรมของเด็ก
  Future<List<Map<String, dynamic>>> getActivityHistory(String childId) async {
    try {
      final supabase = Supabase.instance.client;

      // ดึงจาก activity_record table
      final response = await supabase
          .from('activity_record')
          .select('''
            *,
            activity:activity_id (
              name_activity,
              category,
              maxscore
            )
          ''')
          .eq('child_id', childId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ getActivityHistory error: $e');
      return [];
    }
  }

  /// ดึงสรุปคะแนนของเด็ก
  Future<Map<String, dynamic>> getChildStats(String childId) async {
    try {
      final supabase = Supabase.instance.client;

      // ดึงข้อมูลเด็ก
      final childData = await supabase
          .from('child')
          .select('wallet, name_surname')
          .eq('child_id', childId)
          .single();

      // ดึงจำนวนกิจกรรมที่ทำ (จาก activity_record)
      final activityCount = await supabase
          .from('activity_record')
          .select('ActivityRecord_id')
          .eq('child_id', childId);

      // wallet อาจเป็น Decimal ใน Supabase
      final walletValue = childData['wallet'];
      int wallet = 0;
      if (walletValue is int) {
        wallet = walletValue;
      } else if (walletValue is double) {
        wallet = walletValue.toInt();
      } else if (walletValue != null) {
        wallet = int.tryParse(walletValue.toString()) ?? 0;
      }

      return {
        'wallet': wallet,
        'name': childData['name_surname'] ?? '',
        'totalActivities': (activityCount as List).length,
      };
    } catch (e) {
      print('❌ getChildStats error: $e');
      return {'wallet': 0, 'name': '', 'totalActivities': 0};
    }
  }

  // =====================================================
  // MEDALS/REWARDS MANAGEMENT (ใช้ตาราง medals + parent_and_medals)
  // =====================================================

  /// ดึง medals ที่ผู้ปกครองสร้าง
  Future<List<Map<String, dynamic>>> getMedals(String parentId) async {
    try {
      final supabase = Supabase.instance.client;

      // ดึง medals ผ่าน parent_and_medals
      final response = await supabase
          .from('parent_and_medals')
          .select('''
            *,
            medals:medals_id (
              id,
              name_medals,
              point_medals,
              created_at
            )
          ''')
          .eq('parent_id', parentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ getMedals error: $e');
      return [];
    }
  }

  // Alias for backward compatibility
  Future<List<Map<String, dynamic>>> getRewards(String parentId) async {
    return getMedals(parentId);
  }

  /// เพิ่ม medal ใหม่
  Future<Map<String, dynamic>?> addMedal({
    required String parentId,
    required String name,
    required int cost,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // 1. เพิ่มใน medals table
      final medalResponse = await supabase
          .from('medals')
          .insert({
            'name_medals': name,
            'point_medals': cost,
          })
          .select()
          .single();

      final medalsId = medalResponse['id'];

      // 2. เชื่อมกับ parent ใน parent_and_medals
      await supabase.from('parent_and_medals').insert({
        'parent_id': parentId,
        'medals_id': medalsId,
      });

      print('✅ Medal added: $medalResponse');
      return medalResponse;
    } catch (e) {
      print('❌ addMedal error: $e');
      return null;
    }
  }

  // Alias for backward compatibility
  Future<Map<String, dynamic>?> addReward({
    required String parentId,
    required String name,
    required int cost,
    String? description,
    String? iconName,
  }) async {
    return addMedal(parentId: parentId, name: name, cost: cost);
  }

  /// ลบ medal
  Future<bool> deleteMedal(String medalsId) async {
    try {
      final supabase = Supabase.instance.client;

      // ลบจาก parent_and_medals ก่อน (foreign key)
      await supabase.from('parent_and_medals').delete().eq('medals_id', medalsId);

      // ลบจาก medals
      await supabase.from('medals').delete().eq('id', medalsId);

      return true;
    } catch (e) {
      print('❌ deleteMedal error: $e');
      return false;
    }
  }

  // Alias for backward compatibility
  Future<bool> deleteReward(String rewardId) async {
    return deleteMedal(rewardId);
  }

  /// แลก medal (บันทึกใน redemption table)
  Future<Map<String, dynamic>> redeemMedal({
    required String childId,
    required String medalsId,
    required String parentId,
    required int cost,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // 1. ดึงคะแนนปัจจุบันของเด็ก
      final childResponse = await supabase
          .from('child')
          .select('wallet')
          .eq('child_id', childId)
          .single();

      // แปลง wallet (อาจเป็น Decimal)
      final walletValue = childResponse['wallet'];
      int currentWallet = 0;
      if (walletValue is int) {
        currentWallet = walletValue;
      } else if (walletValue is double) {
        currentWallet = walletValue.toInt();
      } else if (walletValue != null) {
        currentWallet = int.tryParse(walletValue.toString()) ?? 0;
      }

      if (currentWallet < cost) {
        return {
          'success': false,
          'error': 'คะแนนไม่เพียงพอ ต้องการ $cost แต่มีเพียง $currentWallet',
        };
      }

      // 2. หักคะแนน
      final newWallet = currentWallet - cost;
      await supabase
          .from('child')
          .update({'wallet': newWallet})
          .eq('child_id', childId);

      // 3. บันทึกประวัติการแลกใน redemption table
      try {
        await supabase.from('redemption').insert({
          'child_id': childId,
          'medals_id': medalsId,
          'parent_id': parentId,
          'point_for_reward': cost,
          'date_redemption': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('⚠️ Could not save redemption: $e');
      }

      return {
        'success': true,
        'newWallet': newWallet,
        'message': 'แลกของรางวัลสำเร็จ!',
      };
    } catch (e) {
      print('❌ redeemMedal error: $e');
      return {
        'success': false,
        'error': 'เกิดข้อผิดพลาด: $e',
      };
    }
  }

  // Alias for backward compatibility
  Future<Map<String, dynamic>> redeemReward({
    required String childId,
    required String rewardId,
    required String rewardName,
    required int cost,
    String? parentId,
  }) async {
    return redeemMedal(
      childId: childId,
      medalsId: rewardId,
      parentId: parentId ?? '',
      cost: cost,
    );
  }

  /// ดึงประวัติการแลก (จาก redemption table)
  Future<List<Map<String, dynamic>>> getRedemptionHistory(String childId) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('redemption')
          .select('''
            *,
            medals:medals_id (
              name_medals,
              point_medals
            )
          ''')
          .eq('child_id', childId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ getRedemptionHistory error: $e');
      return [];
    }
  }

  /// ดึงประวัติคะแนน (ได้และใช้)
  Future<List<Map<String, dynamic>>> getPointHistory(String childId) async {
    try {
      // รวมประวัติกิจกรรม (ได้คะแนน) และประวัติแลกของ (ใช้คะแนน)
      final activities = await getActivityHistory(childId);
      final redemptions = await getRedemptionHistory(childId);

      List<Map<String, dynamic>> history = [];

      // เพิ่มประวัติกิจกรรม
      for (var activity in activities) {
        final point = activity['point'];
        int pointValue = 0;
        if (point is int) {
          pointValue = point;
        } else if (point is double) {
          pointValue = point.toInt();
        } else if (point != null) {
          pointValue = int.tryParse(point.toString()) ?? 0;
        }

        history.add({
          'type': 'earn',
          'action': activity['activity']?['name_activity'] ?? 'กิจกรรม',
          'point': '+$pointValue',
          'isGain': true,
          'date': activity['created_at'] ?? '',
        });
      }

      // เพิ่มประวัติแลกของ
      for (var redemption in redemptions) {
        final cost = redemption['point_for_reward'];
        int costValue = 0;
        if (cost is int) {
          costValue = cost;
        } else if (cost is double) {
          costValue = cost.toInt();
        } else if (cost != null) {
          costValue = int.tryParse(cost.toString()) ?? 0;
        }

        final medalName = redemption['medals']?['name_medals'] ?? 'ของรางวัล';
        history.add({
          'type': 'spend',
          'action': 'แลก $medalName',
          'point': '-$costValue',
          'isGain': false,
          'date': redemption['created_at'] ?? '',
        });
      }

      // เรียงตามวันที่
      history.sort((a, b) =>
          (b['date'] as String).compareTo(a['date'] as String));

      return history;
    } catch (e) {
      print('❌ getPointHistory error: $e');
      return [];
    }
  }
}
