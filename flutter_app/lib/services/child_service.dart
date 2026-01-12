// lib/services/child_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
      final token = await _storage.getToken();
      if (token == null) return null;

      final user = await _storage.getUser();
      if (user == null) return null;

      final url = Uri.parse("$apiBaseUrl/children");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'parentId': user.id,
          'fullName': fullName,
          if (dob != null) 'dob': dob.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Child.fromJson(data);
      } else {
        print('Add child error: ${response.statusCode} - ${response.body}');
        return null;
      }
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
      final child = await addChild(
        fullName: childData['fullName'] as String,
        dob: childData['dob'] as DateTime?,
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
}
