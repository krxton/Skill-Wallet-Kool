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

  // 🆕 เพิ่ม fields สำหรับเรียงกิจกรรม
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt, // 🆕
    this.updatedAt, // 🆕
  });

  // ----------------------------------------------------
  // JSON MAPPING (Deserialization)
  // ----------------------------------------------------

  factory Activity.fromJson(Map<String, dynamic> json) {
    dynamic segmentsData = json['segments'];

    // 🟢 Logic จัดการ Double-Encoded JSON String
    if (segmentsData is String) {
      try {
        segmentsData = jsonDecode(segmentsData);
      } catch (e) {
        segmentsData = null;
        debugPrint('Warning: Failed to decode segments JSON string: $e');
      }
    }

    // 4. สร้าง Activity Object
    return Activity(
      id: json['activity_id'] as String,
      name: json['name_activity'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
      difficulty: json['level_activity'] as String,
      maxScore: json['maxscore'] as int,
      description: json['description_activity'] as String?,
      videoUrl: json['videourl'] as String?,
      segments: segmentsData,
      thumbnailUrl: json['thumbnailurl'] as String?,
      tiktokHtmlContent: json['tiktokhtmlcontent'] as String?,

      // 🆕 Parse DateTime จาก JSON
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['update_at'] != null
          ? DateTime.tryParse(json['update_at'] as String)
          : null,
    );
  }

  // ----------------------------------------------------
  // JSON MAPPING (Serialization)
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
      'segments': segments,
      'thumbnailUrl': thumbnailUrl,
      'tiktokHtmlContent': tiktokHtmlContent,

      // 🆕 แปลง DateTime เป็น ISO8601 String
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
