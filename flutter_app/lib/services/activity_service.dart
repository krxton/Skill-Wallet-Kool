// lib/services/activity_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/activity.dart';
import 'api_service.dart';
import 'package:collection/collection.dart';

// 🆕 Interface สำหรับผลลัพธ์ของแต่ละ Segment (ต้องอยู่ที่นี่หรือไฟล์ที่ถูก import)
class SegmentResult {
  final String id;
  final String text;
  int maxScore; // Accuracy Score (0-100)
  String? recognizedText;
  String? audioUrl; // URL หรือ Path ของไฟล์เสียงที่บันทึก

  SegmentResult(
      {required this.id,
      required this.text,
      this.maxScore = 0,
      this.recognizedText,
      this.audioUrl});

  // แปลงเป็น JSON สำหรับส่งไป Backend
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'maxScore': maxScore,
        'recognizedText': recognizedText,
        'audioUrl': audioUrl,
      };
}

class ActivityService {
  final ApiService _apiService = ApiService();
  // 🛑 แก้ไข: การประกาศ Static Const
  static const String _oEmbedEndpoint = 'https://www.tiktok.com/oembed?url=';

  final String API_BASE_URL = 'http://192.168.1.58:3000/api';

  // ----------------------------------------------------
  // 1. HELPER FUNCTIONS
  // ----------------------------------------------------

  // 1.1 Helper Function: ดึง OEmbed Data จาก TikTok API
  Future<Map<String, dynamic>> _fetchTikTokOEmbedData(String videoUrl) async {
    final cleanUrl = videoUrl.split('?').first;
    // 🛑 แก้ไข: เรียกใช้ ActivityService._oEmbedEndpoint
    final oEmbedUrl = Uri.parse(
        '${ActivityService._oEmbedEndpoint}$cleanUrl&maxwidth=600&maxheight=800');

    final response = await http.get(oEmbedUrl);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint('TikTok OEmbed Error: ${response.statusCode}');
      throw Exception('Failed to load TikTok OEmbed data.');
    }
  }

  // 1.2 Helper Function: ดึง Activity ทั้งหมดจาก Backend
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

  // ----------------------------------------------------
  // 2. DATA FETCHING (Home Screen)
  // ----------------------------------------------------

  /// 2.1 ดึง Physical Activity Clip (สำหรับส่วน CLIP VDO หลัก)
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

  /// 2.2 ดึง Popular Activities (แก้ไขให้ประมวลผล OEmbed)
  Future<List<Activity>> fetchPopularActivities(String childId) async {
    try {
      final allActivities = await _fetchAllActivities();

      // 1. ทำ Logic 'Popular' อย่างง่าย: คืนค่า 3 รายการแรก
      final popularList = allActivities.take(3).toList();

      // 2. สร้าง List ของ Future สำหรับประมวลผล OEmbed
      final List<Future<Activity>> processedActivitiesFutures =
          popularList.map((activity) async {
        // 🆕 ตรวจสอบว่ากิจกรรมนี้เป็น 'ด้านร่างกาย' และมี videoUrl
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

  Future<Map<String, dynamic>?> fetchDirectVideoUrl(String videoUrl) async {
    try {
      // 1. สร้าง Path สำหรับเรียก Backend Endpoint
      final path = '/get-direct-url?url=${Uri.encodeComponent(videoUrl)}';

      // 2. เรียกใช้เมธอด get() ที่คืนค่า dynamic
      final response = await _apiService.get(path);

      // 3. 🆕 ตรวจสอบ Type และคีย์อย่างเข้มงวด
      if (response is Map<String, dynamic> &&
          response.containsKey('directUrl')) {
        return response; // คืนค่า Map { directUrl: "...", duration: 123 }
      }

      // หาก Backend คืนค่าเป็น String หรือ Map ที่ไม่มีคีย์ directUrl
      debugPrint('Direct URL Fetch Error: Unexpected response format.');

      return null;
    } catch (e) {
      debugPrint('Error fetching direct URL from Backend: $e');
      return null;
    }
  }

  // ----------------------------------------------------
  // 3. AI EVALUATION AND QUEST COMPLETION
  // ----------------------------------------------------

  /// 3.1 ส่งไฟล์เสียงไปประเมิน AI (เทียบเท่า /api/evaluate)
  Future<Map<String, dynamic>> evaluateAudio({
    required File audioFile,
    required String originalText,
  }) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$API_BASE_URL/evaluate'));

      request.files.add(await http.MultipartFile.fromPath(
        'file', // Key ต้องตรงกับ Backend
        audioFile.path,
      ));
      request.fields['text'] = originalText;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'AI Evaluation Failed (${response.statusCode}): ${errorBody['error'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('AI Evaluation Error: $e');
      throw Exception('Failed to send audio for evaluation: $e');
    }
  }

  /// 3.2 คำนวณคะแนนรวมและส่ง Payload ไปบันทึกใน CMS
  Future<Map<String, dynamic>> finalizeQuest({
    required String childId,
    required String activityId,
    required List<SegmentResult> segmentResults,
    required int activityMaxScore,
  }) async {
    final numSections = segmentResults.length;

    // --- 1. คำนวณค่าเฉลี่ยความถูกต้อง (ตาม Logic Web App) ---
    double totalAccuracy = 0.0;
    for (var res in segmentResults) {
      totalAccuracy += res.maxScore;
    }
    final averageAccuracy =
        numSections > 0 ? (totalAccuracy / numSections) : 0.0;

    // --- 2. คำนวณคะแนนที่ได้รับ ---
    final scoreEarned = (activityMaxScore * (averageAccuracy / 100)).floor();

    // --- 3. สร้าง Payload ---
    final payload = {
      'activityId': activityId,
      'totalScoreEarned': scoreEarned,
      'segmentResults': segmentResults.map((r) => r.toJson()).toList(),
    };

    try {
      // 4. ส่ง POST Request
      final res = await _apiService.post('/complete-quest', payload);

      // ส่งคะแนนที่คำนวณแล้วกลับไปให้ ItemIntroScreen
      res['scoreEarned'] = scoreEarned; // คะแนนดิบ (85)
      res['calculatedScore'] = averageAccuracy.round(); // % (85%)

      return res;
    } catch (e) {
      debugPrint('Finalize Quest Error: $e');
      throw Exception('Failed to finalize quest and save record.');
    }
  }
}
