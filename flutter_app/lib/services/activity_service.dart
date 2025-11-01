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
      final List<dynamic> responseList = await _apiService.getArray(
        path: '/activities',
        queryParameters: {},
      );

      return responseList
          .map((json) => Activity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load ALL activities from backend: $e');
    }
  }

  /// 2. ดึง Physical Activity Clip (สำหรับส่วน CLIP VDO)
  Future<Activity?> fetchPhysicalActivityClip(String childId) async {
    try {
      final allActivities = await _fetchAllActivities();

      // 2.1 กรองข้อมูลใน Flutter: หา 'ด้านร่างกาย' ที่มี videoUrl
      final physicalActivity = allActivities.firstWhereOrNull(
        (a) => a.category == 'ด้านร่างกาย' && a.videoUrl != null,
      );

      if (physicalActivity != null && physicalActivity.videoUrl != null) {
        // 2.2 เรียก OEmbed API
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

  /// 3. ดึง Popular Activities (แก้ไขให้ประมวลผล TikTok URL สำหรับทุกรายการ)
  Future<List<Activity>> fetchPopularActivities(String childId) async {
    try {
      final allActivities = await _fetchAllActivities();

      // 1. ทำ Logic 'Popular' อย่างง่าย: คืนค่า 3 รายการแรก
      final popularList = allActivities.take(3).toList();

      // 2. สร้าง List ของ Future สำหรับประมวลผล OEmbed
      final List<Future<Activity>> processedActivitiesFutures =
          popularList.map((activity) async {
        // 🆕 ตรวจสอบว่ากิจกรรมนี้มี videoUrl หรือไม่ และ Category เป็นวิดีโอที่เราสนใจหรือไม่
        if (activity.videoUrl != null &&
            (activity.category.toUpperCase() == 'ด้านร่างกาย')) {
          try {
            // เรียก OEmbed API
            final oEmbedData = await _fetchTikTokOEmbedData(activity.videoUrl!);

            // ผสานข้อมูล
            final Map<String, dynamic> activityJson = activity.toJson();
            activityJson['thumbnailUrl'] = oEmbedData['thumbnail_url'];
            activityJson['tiktokHtmlContent'] = oEmbedData['html'];

            return Activity.fromJson(activityJson);
          } catch (e) {
            // ถ้า OEmbed ล้มเหลว (เช่น ลิงก์เสีย) ให้คืน Activity เดิม
            debugPrint('OEmbed failed for ${activity.name}: $e');
          }
        }
        return activity; // คืน Activity เดิม (ถ้าไม่ใช่ Video หรือ OEmbed ล้มเหลว)
      }).toList();

      // 3. รอจนกว่าการประมวลผล OEmbed ทั้งหมดจะเสร็จสิ้น
      final List<Activity> processedActivities =
          await Future.wait(processedActivitiesFutures);

      return processedActivities;
    } catch (e) {
      debugPrint('Error fetching popular activities (C-Side): $e');
      return [];
    }
  }
}
