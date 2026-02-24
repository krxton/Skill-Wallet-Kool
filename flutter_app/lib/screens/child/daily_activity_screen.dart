import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'playing_result_detail_screen.dart';

class DailyActivityScreen extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> records;

  const DailyActivityScreen({
    super.key,
    required this.date,
    required this.records,
  });

  static const cream = Color(0xFFFFF5CD);
  static const skyBlue = Color(0xFF5AB2FF);
  static const itemBlue = Color(0xFF90CAF9);
  static const numberPink = Color(0xFFFF8A80);

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '--:--';
    final dateTime = DateTime.tryParse(createdAt);
    if (dateTime == null) return '--:--';
    return DateFormat('HH:mm').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    // Sort records by time (oldest first for that day)
    final sortedRecords = List<Map<String, dynamic>>.from(records)
      ..sort((a, b) {
        final aTime = a['created_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? '';
        return aTime.compareTo(bTime);
      });

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        size: 35, color: Colors.black87),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      date,
                      style: GoogleFonts.itim(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: skyBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              AppLocalizations.of(context)!.dailyactivity_playingHistory,
              style: GoogleFonts.itim(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // List of sessions
            Expanded(
              child: sortedRecords.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.dailyactivity_noData,
                        style:
                            GoogleFonts.itim(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: sortedRecords.length,
                      itemBuilder: (context, index) {
                        final record = sortedRecords[index];
                        // point อาจเป็น Decimal จาก Supabase
                        final pointRaw = record['point'];
                        int score = 0;
                        if (pointRaw is int) {
                          score = pointRaw;
                        } else if (pointRaw is double) {
                          score = pointRaw.toInt();
                        } else if (pointRaw != null) {
                          score = int.tryParse(pointRaw.toString()) ?? 0;
                        }
                        final createdAt = record['created_at'] as String?;
                        final activityName =
                            record['activity']?['name_activity'] as String? ??
                                AppLocalizations.of(context)!.dailyactivity_activity;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayingResultDetailScreen(
                                  record: record,
                                  sessionNumber: index + 1,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            child: Row(
                              children: [
                                // วงกลมตัวเลข
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: numberPink,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.luckiestGuy(
                                        fontSize: 24, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 15),

                                // กล่องรายละเอียด
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: itemBlue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ชื่อกิจกรรม
                                        Text(
                                          activityName,
                                          style: GoogleFonts.itim(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // เวลาและคะแนน
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time,
                                                    color: Colors.white70,
                                                    size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatTime(createdAt),
                                                  style: GoogleFonts.itim(
                                                    fontSize: 14,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.emoji_events,
                                                    color: Colors.yellow,
                                                    size: 20),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '$score',
                                                  style:
                                                      GoogleFonts.luckiestGuy(
                                                          fontSize: 18,
                                                          color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
