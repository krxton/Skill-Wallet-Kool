import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PlayingResultDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  final int sessionNumber;

  const PlayingResultDetailScreen({
    super.key,
    required this.record,
    required this.sessionNumber,
  });

  static const cream = Color(0xFFFFF5CD);
  static const skyBlue = Color(0xFF5AB2FF);
  static const redText = Color(0xFFFF8A8A);

  String _formatDate(String? createdAt) {
    if (createdAt == null) return '--';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return '--';
    return DateFormat('dd MMM yyyy').format(date.toLocal()).toUpperCase();
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds == 0) return '--:--:--';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลจาก record (handle Decimal from Supabase)
    final pointRaw = record['point'];
    int score = 0;
    if (pointRaw is int) {
      score = pointRaw;
    } else if (pointRaw is double) {
      score = pointRaw.toInt();
    } else if (pointRaw != null) {
      score = int.tryParse(pointRaw.toString()) ?? 0;
    }

    final timeRaw = record['time_spent'];
    int timespent = 0;
    if (timeRaw is int) {
      timespent = timeRaw;
    } else if (timeRaw is double) {
      timespent = timeRaw.toInt();
    } else if (timeRaw != null) {
      timespent = int.tryParse(timeRaw.toString()) ?? 0;
    }

    final createdAt = record['created_at'] as String?;
    final activityName = record['activity']?['name_activity'] as String? ?? 'กิจกรรม';
    final maxScore = record['activity']?['maxscore'];
    int maxScoreInt = 0;
    if (maxScore is int) {
      maxScoreInt = maxScore;
    } else if (maxScore is double) {
      maxScoreInt = maxScore.toInt();
    } else if (maxScore != null) {
      maxScoreInt = int.tryParse(maxScore.toString()) ?? 0;
    }

    // ดึง evidence (อาจเป็น Map หรือ JSON string)
    Map<String, dynamic>? evidence;
    if (record['evidence'] is Map) {
      evidence = record['evidence'] as Map<String, dynamic>;
    }

    final diary = evidence?['description'] as String? ?? '';
    final imagePath = evidence?['imagePathLocal'] as String?;
    final videoPath = evidence?['videoPathLocal'] as String?;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        size: 35, color: Colors.black87),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ผลการเล่น',
                          style: GoogleFonts.itim(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: skyBlue,
                          ),
                        ),
                        Text(
                          '${_formatDate(createdAt)} | ครั้งที่ $sessionNumber',
                          style: GoogleFonts.itim(
                              fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ชื่อกิจกรรม
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: skyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: skyBlue, width: 2),
                ),
                child: Text(
                  activityName,
                  style: GoogleFonts.itim(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: skyBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 25),

              // 1. Medals Section
              Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Colors.orange, size: 35),
                  const SizedBox(width: 10),
                  Text(
                    'คะแนนที่ได้',
                    style: GoogleFonts.itim(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Text(
                      maxScoreInt > 0 ? '$score/$maxScoreInt' : '$score',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 24, color: Colors.black87),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 25),

              // 2. Diary Section
              Text(
                'บันทึก',
                style: GoogleFonts.itim(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: redText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diary.isNotEmpty ? diary : 'ไม่มีบันทึก',
                  style: GoogleFonts.itim(
                    fontSize: 16,
                    color: diary.isNotEmpty ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 3. Image Section
              Text(
                'รูปภาพ',
                style: GoogleFonts.itim(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: redText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildImageWidget(imagePath),
              ),
              const SizedBox(height: 25),

              // 4. Video Section (if exists)
              if (videoPath != null && videoPath.isNotEmpty) ...[
                Text(
                  'วิดีโอ',
                  style: GoogleFonts.itim(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: redText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'มีวิดีโอแนบ',
                          style: GoogleFonts.itim(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
              ],

              // 5. Time Section
              Center(
                child: Column(
                  children: [
                    Text(
                      'เวลาที่ใช้',
                      style: GoogleFonts.itim(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: redText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _formatTime(timespent),
                        style: GoogleFonts.luckiestGuy(
                            fontSize: 24, color: skyBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imagePath) {
    // ถ้ามี local path และไฟล์ยังอยู่
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
          ),
        );
      }
    }

    // ถ้าไม่มีรูป
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'ไม่มีรูปภาพ',
            style: GoogleFonts.itim(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
