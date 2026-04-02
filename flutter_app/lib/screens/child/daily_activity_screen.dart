import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import 'playing_result_detail_screen.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class DailyActivityScreen extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> records;

  const DailyActivityScreen({
    super.key,
    required this.date,
    required this.records,
  });

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '--:--';
    final dateTime = DateTime.tryParse(createdAt);
    if (dateTime == null) return '--:--';
    return DateFormat('HH:mm').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final sortedRecords = List<Map<String, dynamic>>.from(records)
      ..sort((a, b) {
        final aTime = a['created_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? '';
        return aTime.compareTo(bTime);
      });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      style: AppTextStyles.body(24,
                          color: Palette.blueChip,
                          weight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              AppLocalizations.of(context)!.dailyactivity_playingHistory,
              style: AppTextStyles.body(18, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: sortedRecords.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.dailyactivity_noData,
                        style: AppTextStyles.body(18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: sortedRecords.length,
                      itemBuilder: (context, index) {
                        final record = sortedRecords[index];
                        final pointRaw = record['point'];
                        int score = 0;
                        if (pointRaw is int) {
                          score = pointRaw;
                        } else if (pointRaw is double) {
                          score = pointRaw.toInt();
                        } else if (pointRaw != null) {
                          score =
                              int.tryParse(pointRaw.toString()) ?? 0;
                        }
                        final createdAt =
                            record['created_at'] as String?;
                        final activityName =
                            record['activity']?['name_activity']
                                    as String? ??
                                AppLocalizations.of(context)!
                                    .dailyactivity_activity;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlayingResultDetailScreen(
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
                                // Circle number
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Palette.error,
                                    shape: BoxShape.circle,
                                    boxShadow: Palette.softShadow,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: AppTextStyles.heading(24,
                                        color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 15),

                                // Detail card
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Palette.lightBlue,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      boxShadow: Palette.softShadow,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activityName,
                                          style: AppTextStyles.body(16,
                                              color: Colors.white,
                                              weight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.access_time,
                                                    color: Colors.white70,
                                                    size: 16),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatTime(createdAt),
                                                  style: AppTextStyles
                                                      .body(14,
                                                          color: Colors
                                                              .white70),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.emoji_events,
                                                    color: Colors.yellow,
                                                    size: 20),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '$score',
                                                  style:
                                                      AppTextStyles.heading(
                                                          18,
                                                          color:
                                                              Colors.white),
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
