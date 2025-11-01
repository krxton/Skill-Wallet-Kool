// lib/models/activity.dart

import 'dart:convert'; // 🆕 จำเป็นสำหรับการใช้ jsonDecode
import 'package:flutter/foundation.dart'; // สำหรับ debugPrint

class Activity {
  final String id;
  final String name;
  final String category;
  final String content;
  final String difficulty;
  final int maxScore;
  final String? description;
  final String? videoUrl;

  // segments: ใช้ dynamic เพื่อรองรับ List<Map<String, dynamic>> ที่ถูก decode แล้ว
  final dynamic segments;

  final String? thumbnailUrl;
  final String? tiktokHtmlContent;

  // ----------------------------------------------------
  // CONSTRUCTOR
  // ----------------------------------------------------

  Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.content,
    required this.difficulty,
    required this.maxScore,
    this.description,
    this.videoUrl,
    this.segments,
    this.thumbnailUrl,
    this.tiktokHtmlContent,
  });

  // ----------------------------------------------------
  // JSON MAPPING (Deserialization)
  // ----------------------------------------------------

  factory Activity.fromJson(Map<String, dynamic> json) {
    dynamic segmentsData = json['segments'];

    // 🟢 Logic จัดการ Double-Encoded JSON String (แก้ปัญหา 'type String is not a subtype of List')
    // ตรวจสอบว่า segments ที่ได้มาเป็น String หรือไม่
    if (segmentsData is String) {
      try {
        // ทำการ Decode JSON string เป็น List<dynamic>
        segmentsData = jsonDecode(segmentsData);
      } catch (e) {
        // หาก Decode ล้มเหลว ให้ตั้งค่าเป็น null หรือ List ว่าง
        segmentsData = null;
        debugPrint('Warning: Failed to decode segments JSON string: $e');
      }
    }

    // 4. สร้าง Activity Object
    return Activity(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
      difficulty: json['difficulty'] as String,
      maxScore: json['maxScore'] as int,
      description: json['description'] as String?,
      videoUrl: json['videoUrl'] as String?,

      // ใช้อันที่ถูก Decode แล้ว (ตอนนี้ควรเป็น List<Map> หรือ null)
      segments: segmentsData,

      thumbnailUrl: json['thumbnailUrl'] as String?,
      tiktokHtmlContent: json['tiktokHtmlContent'] as String?,
    );
  }

  // ----------------------------------------------------
  // JSON MAPPING (Serialization - ใช้ในการส่งกลับใน ActivityService)
  // ----------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'content': content,
      'difficulty': difficulty,
      'maxScore': maxScore,
      'description': description,
      'videoUrl': videoUrl,

      // segments จะถูกส่งกลับเป็น List/Map ที่ถูก Parse แล้ว
      'segments': segments,

      'thumbnailUrl': thumbnailUrl,
      'tiktokHtmlContent': tiktokHtmlContent,
    };
  }
}
