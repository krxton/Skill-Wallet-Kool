// lib/services/api_service.dart (ฉบับปรับปรุง)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // 1. Base URL
  // static const String _baseUrl = 'http://192.168.1.58:3000/api';
  static const String _baseUrl = 'http://127.0.0.1:3000/api';

  // 2. Headers Getter
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // 1. ฟังก์ชัน GET หลัก: คืนค่าเป็น Future<dynamic>
  // (สามารถเป็น Map หรือ List ก็ได้)
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    Uri uri = Uri.parse('$_baseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      Map<String, String> stringQueryParameters = queryParameters.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      uri = uri.replace(queryParameters: stringQueryParameters);
    }

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      if (response.body.isEmpty) return {};
      // ⚠️ คืนค่าเป็น dynamic
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Failed to load data: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        }
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  // 2. เมธอด getArray: สำหรับดึงข้อมูลที่เป็น List โดยเฉพาะ
  Future<List<dynamic>> getArray({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final dynamic responseData =
        await get(path, queryParameters: queryParameters);

    // ✅ Case 1: Response ทั้งก้อนเป็น List
    if (responseData is List) {
      return responseData;
    }

    // ✅ Case 2: Response เป็น Map แต่ List อยู่ในคีย์ 'data'
    if (responseData is Map &&
        responseData.containsKey('data') &&
        responseData['data'] is List) {
      return responseData['data'] as List<dynamic>;
    }

    // หากไม่ใช่รูปแบบที่คาดหวัง ให้คืนค่า List ว่าง
    debugPrint('API getArray: Unexpected response format. Path: $path');
    return [];
  }

  // 3. เมธอด getActivitiesResponse: สำหรับดึงข้อมูลที่เป็น Map โดยเฉพาะ
  Future<Map<String, dynamic>> getActivitiesResponse({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final dynamic responseData =
        await get(path, queryParameters: queryParameters);

    // ✅ ตรวจสอบว่าเป็น Map ก่อน Cast
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    // ⚠️ ถ้าไม่ใช่ Map (เช่น เป็น List) ให้ throw Error เพื่อจัดการใน Service
    throw Exception(
        'API Error: Expected Map response, but received List/null.');
  }

  // 4. ฟังก์ชัน POST (ไม่มีการเปลี่ยนแปลง)
  Future<Map<String, dynamic>> post(String path, dynamic body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      String errorMessage = 'Failed to process request: ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('error')) {
            errorMessage = errorBody['error'];
          }
        }
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
  }

  // *************************************************************
  // * 5. เมธอดใหม่สำหรับ ActivityService (แก้ไข Error เก่า) *
  // *************************************************************
  Future<Map<String, dynamic>> getActivityById({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    final dynamic responseData =
        await get(path, queryParameters: queryParameters);

    // ✅ ตรวจสอบว่าเป็น Map ก่อน Cast
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    // ⚠️ ถ้าไม่ใช่ Map (เช่น เป็น List) ให้ throw Error เพื่อจัดการใน Service
    throw Exception(
        'API Error: Expected Map response for activity, but received List/null.');
  }
}
