// lib/services/activity_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/activity.dart';
import 'api_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// 🆕 Interface สำหรับผลลัพธ์ของแต่ละ Segment
class SegmentResult {
  final String id;
  final String text;
  int maxScore; // Accuracy Score (0-100)
  String? recognizedText;
  String? audioUrl; // URL หรือ Path ของไฟล์เสียงที่บันทึก

  SegmentResult({
    required this.id,
    required this.text,
    this.maxScore = 0,
    this.recognizedText,
    this.audioUrl,
  });

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
  static const String _oEmbedEndpoint = 'https://www.tiktok.com/oembed?url=';

  String get API_BASE_URL =>
      dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000/api';

  // ----------------------------------------------------
  // 1. HELPER FUNCTIONS
  // ----------------------------------------------------

  // 1.1 Helper Function: ดึง OEmbed Data จาก TikTok API
  Future<Map<String, dynamic>> _fetchTikTokOEmbedData(String videoUrl) async {
    final cleanUrl = videoUrl.split('?').first;
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

      // กรองข้อมูลใน Flutter: หา 'ด้านร่างกาย' ที่มี videoUrl
      final physicalActivity = allActivities.firstWhereOrNull(
        (a) => a.category == 'ด้านร่างกาย' && a.videoUrl != null,
      );

      if (physicalActivity != null && physicalActivity.videoUrl != null) {
        // เรียก OEmbed API
        final oEmbedData =
            await _fetchTikTokOEmbedData(physicalActivity.videoUrl!);

        // ผสานข้อมูล
        final Map<String, dynamic> activityJson = physicalActivity.toJson();
        activityJson['thumbnailUrl'] = oEmbedData['thumbnail_url'];
        activityJson['tiktokHtmlContent'] = oEmbedData['html'];

        return Activity.fromJson(activityJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching physical clip: $e');
      return null;
    }
  }

  /// 2.2 ดึง Popular Activities (เรียงตาม roundNumber มากสุด)
  Future<List<Activity>> fetchPopularActivities(String childId) async {
    try {
      // 1. ดึงข้อมูลกิจกรรมทั้งหมด
      final allActivities = await _fetchAllActivities();

      // 2. ดึงข้อมูล Activity Records (รอบการเล่น) จาก Backend
      final records = await _apiService.getArray(
        path: '/activity-records',
        queryParameters: {'childId': childId},
      );

      // 3. สร้าง Map เก็บจำนวนรอบการเล่นของแต่ละ Activity
      final Map<String, int> activityPlayCount = {};

      for (var record in records) {
        final activityId = record['activityId'] as String?;
        if (activityId != null) {
          activityPlayCount[activityId] =
              (activityPlayCount[activityId] ?? 0) + 1;
        }
      }

      // 4. เรียงกิจกรรมตามจำนวนรอบการเล่น (มากสุดก่อน)
      allActivities.sort((a, b) {
        final countA = activityPlayCount[a.id] ?? 0;
        final countB = activityPlayCount[b.id] ?? 0;
        return countB.compareTo(countA); // เรียงจากมากไปน้อย
      });

      // 5. ประมวลผล OEmbed สำหรับกิจกรรมที่มี Video
      final List<Future<Activity>> processedActivitiesFutures =
          allActivities.map((activity) async {
        // TikTok (ด้านร่างกาย)
        if (activity.videoUrl != null &&
            activity.category.toUpperCase() == 'ด้านร่างกาย') {
          try {
            final oEmbedData = await _fetchTikTokOEmbedData(activity.videoUrl!);
            final Map<String, dynamic> activityJson = activity.toJson();
            activityJson['thumbnailUrl'] = oEmbedData['thumbnail_url'];
            activityJson['tiktokHtmlContent'] = oEmbedData['html'];
            return Activity.fromJson(activityJson);
          } catch (e) {
            debugPrint('OEmbed failed for ${activity.name}: $e');
          }
        }
        return activity;
      }).toList();

      final List<Activity> processedActivities =
          await Future.wait(processedActivitiesFutures);

      return processedActivities; // คืนทั้งหมด (ไม่จำกัด 3 รายการ)
    } catch (e) {
      debugPrint('Error fetching popular activities: $e');
      return [];
    }
  }

  /// 2.3 ดึง New Activities (เรียงตาม ID หรือ createdAt)
  Future<List<Activity>> fetchNewActivities(String childId) async {
    try {
      final allActivities = await _fetchAllActivities();

      // เรียงตาม createdAt หรือ ID (CUID)
      allActivities.sort((a, b) {
        // ลองใช้ createdAt ก่อน (ถ้ามี)
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!); // ล่าสุดก่อน
        }
        // ถ้าไม่มี createdAt ให้เรียงตาม ID (CUID ใหม่กว่า = มากกว่า)
        return b.id.compareTo(a.id);
      });

      // ประมวลผล OEmbed
      final List<Future<Activity>> processedActivitiesFutures =
          allActivities.map((activity) async {
        if (activity.videoUrl != null &&
            activity.category.toUpperCase() == 'ด้านร่างกาย') {
          try {
            final oEmbedData = await _fetchTikTokOEmbedData(activity.videoUrl!);
            final Map<String, dynamic> activityJson = activity.toJson();
            activityJson['thumbnailUrl'] = oEmbedData['thumbnail_url'];
            activityJson['tiktokHtmlContent'] = oEmbedData['html'];
            return Activity.fromJson(activityJson);
          } catch (e) {
            debugPrint('OEmbed failed for ${activity.name}: $e');
          }
        }
        return activity;
      }).toList();

      final List<Activity> processedActivities =
          await Future.wait(processedActivitiesFutures);

      return processedActivities; // คืนทั้งหมด
    } catch (e) {
      debugPrint('Error fetching new activities: $e');
      return [];
    }
  }

  // ----------------------------------------------------
  // 3. OTHER SERVICES
  // ----------------------------------------------------

  Future<Map<String, dynamic>?> fetchDirectVideoUrl(String videoUrl) async {
    try {
      final path = '/get-direct-url?url=${Uri.encodeComponent(videoUrl)}';
      final response = await _apiService.get(path);

      if (response is Map<String, dynamic> &&
          response.containsKey('directUrl')) {
        return response;
      }

      debugPrint('Direct URL Fetch Error: Unexpected response format.');
      return null;
    } catch (e) {
      debugPrint('Error fetching direct URL from Backend: $e');
      return null;
    }
  }

  // ----------------------------------------------------
  // 4. AI EVALUATION AND QUEST COMPLETION
  // ----------------------------------------------------

  /// 4.1 ส่งไฟล์เสียงไปประเมิน AI
  Future<Map<String, dynamic>> evaluateAudio({
    required File audioFile,
    required String originalText,
  }) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$API_BASE_URL/evaluate'));

      request.files.add(await http.MultipartFile.fromPath(
        'file',
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

  /// 4.2 คำนวณคะแนนรวมและส่ง Payload ไปบันทึกใน CMS
  Future<Map<String, dynamic>> finalizeQuest({
    required String childId,
    required String activityId,
    required List<SegmentResult> segmentResults,
    required int activityMaxScore,
    Map<String, dynamic>? evidence,
    int? parentScore, // 🆕 รับ parentScore แยกเป็น parameter
  }) async {
    final numSections = segmentResults.length;

    // 1. คำนวณค่าเฉลี่ยความถูกต้อง
    double totalAccuracy = 0.0;
    for (var res in segmentResults) {
      totalAccuracy += res.maxScore;
    }
    final averageAccuracy =
        numSections > 0 ? (totalAccuracy / numSections) : 0.0;

    // 2. คำนวณคะแนนที่ได้รับ
    final scoreEarned = (activityMaxScore * (averageAccuracy / 100)).floor();

    // 🆕 2.1 ใช้ parentScore ถ้ามี (ไม่ต้องดึงจาก evidence อีก)
    final int finalScore = parentScore ?? scoreEarned;

    // 🆕 Debug: ดูว่า payload มีอะไรบ้าง
    print('📊 Service Debug:');
    print('  - parentScore received: $parentScore');
    print('  - finalScore: $finalScore');
    print('  - evidence: $evidence');

    // 3. สร้าง Payload
    final payload = {
      'activityId': activityId,
      'totalScoreEarned': finalScore, // 🆕 ใช้ finalScore แทน scoreEarned
      'segmentResults': segmentResults.map((r) => r.toJson()).toList(),
      'evidence': evidence,
      'parentScore': parentScore, // 🆕 เพิ่ม parentScore ไปด้วย (ถ้ามี)
    };

    print('📦 Payload to Backend: $payload');

    try {
      // 4. ส่ง POST Request
      final res = await _apiService.post('/complete-quest', payload);

      // ส่งคะแนนกลับไป
      res['scoreEarned'] = finalScore; // 🆕 คะแนนที่ใช้จริง
      res['calculatedScore'] =
          parentScore ?? averageAccuracy.round(); // 🆕 % หรือคะแนนจากผู้ปกครอง

      return res;
    } catch (e) {
      debugPrint('Finalize Quest Error: $e');
      throw Exception('Failed to finalize quest and save record.');
    }
  }
}
