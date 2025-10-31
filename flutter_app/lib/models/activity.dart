// lib/models/activity.dart

class Activity {
  final String id;
  final String name;
  final String category;
  final String content;
  final String difficulty;
  final int maxScore;
  final String? description;
  final String? videoUrl; // จาก Prisma Schema

  // 🆕 ฟิลด์เสริมที่ได้จากการประมวลผล (OEmbed API)
  final String? thumbnailUrl;
  final String? tiktokHtmlContent;

  Activity({
    required this.id,
    required this.name,
    required this.category,
    required this.content,
    required this.difficulty,
    required this.maxScore,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.tiktokHtmlContent,
  });

  // Factory constructor สำหรับแปลง JSON ที่มาจาก API
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
      difficulty: json['difficulty'] as String,
      maxScore: json['maxScore'] as int,
      description: json['description'] as String?,
      videoUrl: json['videoUrl'] as String?,

      // Mapping ฟิลด์เสริมที่ถูกเพิ่มเข้าไปใน Service
      thumbnailUrl: json['thumbnailUrl'] as String?,
      tiktokHtmlContent: json['tiktokHtmlContent'] as String?,
    );
  }

  // 🆕 Method สำหรับแปลง Object กลับเป็น Map (ใช้ในการผสานข้อมูล)
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

      // ฟิลด์เสริม
      'thumbnailUrl': thumbnailUrl,
      'tiktokHtmlContent': tiktokHtmlContent,
    };
  }
}
