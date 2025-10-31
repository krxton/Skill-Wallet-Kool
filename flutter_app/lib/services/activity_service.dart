// lib/services/activity_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/activity.dart';
import 'package:collection/collection.dart';

class ActivityService {
  final ApiService _apiService = ApiService();
  static const String _oEmbedEndpoint = 'https://www.tiktok.com/oembed?url=';

  // 1. Helper Function: ดึง OEmbed Data จาก TikTok API
  Future<Map<String, dynamic>> _fetchTikTokOEmbedData(String videoUrl) async {
    final cleanUrl = videoUrl.split('?').first;
    final oEmbedUrl =
        Uri.parse('$_oEmbedEndpoint$cleanUrl&maxwidth=600&maxheight=800');

    final response = await http.get(oEmbedUrl);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint('TikTok OEmbed Error: ${response.statusCode}');
      throw Exception('Failed to load TikTok OEmbed data.');
    }
  }

  // 🆕 Helper Function: ดึง Activity ทั้งหมดจาก Backend (API Call หลัก)
  Future<List<Activity>> _fetchAllActivities() async {
    try {
      // 🆕 ใช้ getArray ซึ่งถูกแก้ไขแล้วใน ApiService
      final List<dynamic> responseList = await _apiService.getArray(
        path: '/activities',
        queryParameters: {},
      );

      // Map List<dynamic> เป็น List<Activity>
      return responseList
          .map((json) => Activity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // ⚠️ Error นี้ควรจะถูกแก้แล้ว และจะแสดง Error ที่มาจาก getArray แทน
      throw Exception('Failed to load ALL activities from backend: $e');
    }
  }

  /// 2. ดึง Physical Activity Clip (Client-Side Filtering)
  Future<Activity?> fetchPhysicalActivityClip(String childId) async {
    try {
      final allActivities = await _fetchAllActivities();

      // 2.1 กรองข้อมูล: หา 'ด้านร่างกาย' ที่มี videoUrl
      final physicalActivity = allActivities.firstWhereOrNull(
        (a) => a.category == 'ด้านร่างกาย' && a.videoUrl != null,
      );

      if (physicalActivity != null && physicalActivity.videoUrl != null) {
        // 2.2 ถ้าเจอให้เรียก OEmbed API
        final oEmbedData =
            await _fetchTikTokOEmbedData(physicalActivity.videoUrl!);

        // 2.3 ผสานข้อมูล
        final Map<String, dynamic> activityJson = physicalActivity.toJson();
        activityJson['thumbnailUrl'] = oEmbedData['thumbnail_url'];
        activityJson['tiktokHtmlContent'] = oEmbedData['html'];

        return Activity.fromJson(activityJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching physical clip (C-Side): $e');
      return null;
    }
  }

  /// 3. ดึง Popular Activities (Client-Side Filtering)
  Future<List<Activity>> fetchPopularActivities(String childId) async {
    try {
      final allActivities = await _fetchAllActivities();

      // 3.1 Logic 'Popular' อย่างง่าย: คืนค่า 3 รายการแรก
      return allActivities.take(3).toList();
    } catch (e) {
      debugPrint('Error fetching popular activities (C-Side): $e');
      return [];
    }
  }
}
