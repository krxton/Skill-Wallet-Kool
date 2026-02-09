import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import 'api_service.dart';

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
  // 🔒 Privacy-first: ไม่ส่ง audioUrl (เก็บเฉพาะในเครื่อง)
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'maxScore': maxScore,
        'recognizedText': recognizedText,
        // audioUrl จะไม่ถูกส่งไปเซิร์ฟเวอร์ (เก็บเฉพาะ local)
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
        activityJson['thumbnailurl'] = oEmbedData['thumbnail_url'];
        activityJson['tiktokhtmlcontent'] = oEmbedData['html'];
        return Activity.fromJson(activityJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching physical clip: $e');
      return null;
    }
  }

  /// 2.2 ดึง Popular Activities (เรียงตามจำนวนรอบการเล่น)
  Future<List<Activity>> fetchPopularActivities(
    String childId, {
    String? category, // 'ด้านภาษา', 'ด้านร่างกาย', 'ด้านวิเคราะห์'
    String? level, // 'ง่าย', 'กลาง', 'ยาก'
    String? parentId, // สำหรับ filter visibility
  }) async {
    try {
      final supabase = Supabase.instance.client;
      var query = supabase.from('activity').select();

      // Visibility: is_public=true OR parent_id=currentParent
      if (parentId != null && parentId.isNotEmpty) {
        query = query.or('is_public.eq.true,parent_id.eq.$parentId');
      } else {
        query = query.eq('is_public', true);
      }

      // กรองตาม category ถ้ามี
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // กรองตาม level ถ้ามี
      if (level != null && level.isNotEmpty) {
        query = query.eq('level_activity', level);
      }

      final activityData = await query.order('play_count', ascending: false);
      final activities = activityData.map<Activity>((json) => Activity.fromJson(json)).toList();

      // ✅ ประมวลผล TikTok OEmbed สำหรับกิจกรรมที่มี Video
      final List<Future<Activity>> processedActivitiesFutures =
          activities.map((activity) async {
        // TikTok (ด้านร่างกาย)
        if (activity.videoUrl != null &&
            activity.category == 'ด้านร่างกาย') {
          try {
            debugPrint('🎬 Fetching TikTok OEmbed for: ${activity.name}');
            final oEmbedData = await _fetchTikTokOEmbedData(activity.videoUrl!);

            // ✅ Null-safe: ตรวจสอบว่ามีข้อมูลครบก่อน
            final String? thumbnailUrl = oEmbedData['thumbnail_url'] as String?;
            final String? htmlContent = oEmbedData['html'] as String?;

            debugPrint('  - thumbnail: ${thumbnailUrl != null ? 'OK' : 'NULL'}');
            debugPrint('  - html: ${htmlContent != null ? 'OK (${htmlContent.length} chars)' : 'NULL'}');

            // ถ้ามีข้อมูล html ให้ผสานเข้า activity
            if (htmlContent != null && htmlContent.isNotEmpty) {
              final Map<String, dynamic> activityJson = activity.toJson();
              activityJson['thumbnailurl'] = thumbnailUrl ?? '';
              activityJson['tiktokhtmlcontent'] = htmlContent;
              debugPrint('✅ OEmbed success for ${activity.name}');
              return Activity.fromJson(activityJson);
            } else {
              debugPrint('⚠️ OEmbed returned null/empty html for ${activity.name}');
            }
          } catch (e) {
            debugPrint('❌ OEmbed failed for ${activity.name}: $e');
          }
        }
        return activity;
      }).toList();

      final List<Activity> processedActivities =
          await Future.wait(processedActivitiesFutures);
      return processedActivities;
    } catch (e) {
      debugPrint('Error fetching popular activities: $e');
      return [];
    }
  }

  /// 2.3 ดึง New Activities (เรียงตาม createdAt หรือ id)
  Future<List<Activity>> fetchNewActivities(
    String childId, {
    String? category, // 'ด้านภาษา', 'ด้านร่างกาย', 'ด้านวิเคราะห์'
    String? level, // 'ง่าย', 'กลาง', 'ยาก'
    String? parentId, // สำหรับ filter visibility
  }) async {
    try {
      final supabase = Supabase.instance.client;
      var query = supabase.from('activity').select();

      // Visibility: is_public=true OR parent_id=currentParent
      if (parentId != null && parentId.isNotEmpty) {
        query = query.or('is_public.eq.true,parent_id.eq.$parentId');
      } else {
        query = query.eq('is_public', true);
      }

      // กรองตาม category ถ้ามี
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // กรองตาม level ถ้ามี
      if (level != null && level.isNotEmpty) {
        query = query.eq('level_activity', level);
      }

      final activityData = await query.order('created_at', ascending: false);
      final activities = activityData.map<Activity>((json) => Activity.fromJson(json)).toList();

      // ✅ ประมวลผล TikTok OEmbed สำหรับกิจกรรมที่มี Video
      final List<Future<Activity>> processedActivitiesFutures =
          activities.map((activity) async {
        if (activity.videoUrl != null &&
            activity.category == 'ด้านร่างกาย') {
          try {
            debugPrint('🎬 Fetching TikTok OEmbed for: ${activity.name}');
            final oEmbedData = await _fetchTikTokOEmbedData(activity.videoUrl!);

            // ✅ Null-safe: ตรวจสอบว่ามีข้อมูลครบก่อน
            final String? thumbnailUrl = oEmbedData['thumbnail_url'] as String?;
            final String? htmlContent = oEmbedData['html'] as String?;

            debugPrint('  - thumbnail: ${thumbnailUrl != null ? 'OK' : 'NULL'}');
            debugPrint('  - html: ${htmlContent != null ? 'OK (${htmlContent.length} chars)' : 'NULL'}');

            // ถ้ามีข้อมูล html ให้ผสานเข้า activity
            if (htmlContent != null && htmlContent.isNotEmpty) {
              final Map<String, dynamic> activityJson = activity.toJson();
              activityJson['thumbnailurl'] = thumbnailUrl ?? '';
              activityJson['tiktokhtmlcontent'] = htmlContent;
              debugPrint('✅ OEmbed success for ${activity.name}');
              return Activity.fromJson(activityJson);
            } else {
              debugPrint('⚠️ OEmbed returned null/empty html for ${activity.name}');
            }
          } catch (e) {
            debugPrint('❌ OEmbed failed for ${activity.name}: $e');
          }
        }
        return activity;
      }).toList();

      final List<Activity> processedActivities =
          await Future.wait(processedActivitiesFutures);
      return processedActivities;
    } catch (e) {
      debugPrint('Error fetching new activities: $e');
      return [];
    }
  }

  // ----------------------------------------------------
  // 2.4 ดึง Language Activities (ตามหัวข้อและระดับ)
  // ----------------------------------------------------
  /// ดึง Language Activities กรองตาม topic และ level
  Future<List<Activity>> fetchLanguageActivities({
    String? topic, // 'LISTENING AND SPEAKING' หรือ 'FILL IN THE BLANKS'
    String? level, // 'ง่าย', 'กลาง', 'ยาก'
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // เริ่มต้น query ด้วย category = 'ด้านภาษา'
      var query = supabase
          .from('activity')
          .select()
          .eq('category', 'ด้านภาษา');

      // กรองตาม level ถ้ามี
      if (level != null) {
        query = query.eq('level_activity', level);
      }

      final activities = await query;

      debugPrint('📚 Language Activities Found: ${activities.length}');
      if (activities.isNotEmpty) {
        debugPrint('📋 Sample Activity: ${activities.first}');
      }

      return activities
          .map<Activity>((json) => Activity.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching language activities: $e');
      return [];
    }
  }

  // ----------------------------------------------------
  // 3. OTHER SERVICES
  // ----------------------------------------------------
  /// 3.1 ดึง HTML iframe สำหรับเล่นวิดีโอจาก Backend
  Future<String?> fetchVideoIframeHtml(String videoUrl) async {
    try {
      final path = '/get-direct-url?url=${Uri.encodeComponent(videoUrl)}';
      final response = await _apiService.get(path);
      if (response is Map<String, dynamic> &&
          response.containsKey('iframeHtml')) {
        return response['iframeHtml'] as String?;
      }
      debugPrint('Iframe HTML Fetch Error: Unexpected response format.');
      return null;
    } catch (e) {
      debugPrint('Error fetching iframe HTML from Backend: $e');
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
      final uri = Uri.parse('$API_BASE_URL/evaluate');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
        ),
      );
      request.fields['text'] = originalText;
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Map<String, dynamic>? errorBody;
        try {
          errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          // ignore decode error
        }
        throw Exception(
          'AI Evaluation Failed (${response.statusCode}): '
          '${errorBody?['error'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('AI Evaluation Error: $e');
      throw Exception('Failed to send audio for evaluation: $e');
    }
  }

  /// 4.1b ส่งเสียงจากหน่วยความจำ (Web) ไปประเมิน AI
  Future<Map<String, dynamic>> evaluateAudioBytes({
    required Uint8List audioBytes,
    required String originalText,
    String filename = 'recording.m4a',
  }) async {
    try {
      final uri = Uri.parse('$API_BASE_URL/evaluate');

      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes,
          filename: filename,
          contentType: MediaType('audio', 'mpeg'),
        ),
      );
      request.fields['text'] = originalText;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Map<String, dynamic>? errorBody;
        try {
          errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        throw Exception(
          'AI Evaluation Failed (${response.statusCode}): '
          '${errorBody?['error'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('AI Evaluation (bytes) Error: $e');
      throw Exception('Failed to send audio bytes for evaluation: $e');
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
    int? timeSpent, // ⏱️ เวลาที่ใช้ในการทำกิจกรรม (วินาที)
    bool useDirectScore = false, // 🆕 สำหรับกิจกรรมวิเคราะห์ที่ใช้คะแนนดิบ
  }) async {
    final numSections = segmentResults.length;

    int finalScore;
    int calculatedScore;

    if (useDirectScore) {
      // 🎯 สำหรับกิจกรรมวิเคราะห์: ใช้คะแนนดิบโดยตรง
      double totalScore = 0.0;
      for (var res in segmentResults) {
        totalScore += res.maxScore;
      }
      finalScore = parentScore ?? totalScore.toInt();
      calculatedScore = totalScore.toInt(); // คะแนนดิบ

      print('📊 Service Debug (Direct Score):');
      print('  - Total raw score: $totalScore');
      print('  - Activity maxScore: $activityMaxScore');
      print('  - finalScore: $finalScore');
    } else {
      // 📚 สำหรับกิจกรรมภาษา: คำนวณจาก accuracy percentage
      double totalAccuracy = 0.0;
      for (var res in segmentResults) {
        totalAccuracy += res.maxScore;
      }
      final averageAccuracy =
          numSections > 0 ? (totalAccuracy / numSections) : 0.0;
      final scoreEarned = (activityMaxScore * (averageAccuracy / 100)).floor();

      finalScore = parentScore ?? scoreEarned;
      calculatedScore = parentScore ?? averageAccuracy.round();

      print('📊 Service Debug (Percentage):');
      print('  - Average accuracy: $averageAccuracy%');
      print('  - scoreEarned: $scoreEarned');
      print('  - finalScore: $finalScore');
    }

    print('  - parentScore received: $parentScore');
    print('  - evidence: $evidence');

    // 3. สร้าง Payload
    final payload = {
      'childId': childId,
      'activityId': activityId,
      'totalScoreEarned': finalScore,
      'timeSpent': timeSpent,
      'segmentResults': segmentResults.map((r) => r.toJson()).toList(),
      'evidence': evidence,
      'parentScore': parentScore,
    };
    print('📦 Payload to Backend: $payload');
    try {
      final res = await _apiService.post('/complete-quest', payload);
      res['scoreEarned'] = finalScore;
      res['calculatedScore'] = calculatedScore;
      return res;
    } catch (e) {
      debugPrint('Finalize Quest Error: $e');
      throw Exception('Failed to finalize quest and save record.');
    }
  }

  /// สร้างกิจกรรมใหม่ผ่าน backend API
  Future<Map<String, dynamic>> createActivity({
    required String parentId,
    required String name,
    required String category,
    required String content,
    required String difficulty,
    required int maxScore,
    String? description,
    String? videoUrl,
    List<Map<String, dynamic>>? segments,
    bool isPublic = true,
  }) async {
    final payload = {
      'name': name,
      'category': category,
      'content': content,
      'difficulty': difficulty,
      'maxScore': maxScore,
      'parentId': parentId,
      'isPublic': isPublic,
      if (description != null) 'description': description,
      if (videoUrl != null && videoUrl.isNotEmpty) 'videoUrl': videoUrl,
      if (segments != null) 'segments': segments,
    };
    return _apiService.post('/activities', payload);
  }
}
