import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import '../../services/child_service.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';
import 'daily_activity_screen.dart';

class ActivityHistoryScreen extends StatefulWidget {
  final String gameName; // category name
  final String? childId;

  const ActivityHistoryScreen({
    super.key,
    required this.gameName,
    this.childId,
  });

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final ChildService _childService = ChildService();
  bool _isLoading = true;

  // เก็บข้อมูลแบบ group by date
  // key = date string, value = list of activity records
  Map<String, List<Map<String, dynamic>>> _groupedByDate = {};

  @override
  void initState() {
    super.initState();
    _loadActivityHistory();
  }

  Future<void> _loadActivityHistory() async {
    if (widget.childId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // ดึงประวัติกิจกรรมทั้งหมดของเด็ก
      final history = await _childService.getActivityHistory(widget.childId!);

      // กรองเฉพาะ category ที่ต้องการ
      final filteredHistory = history.where((record) {
        final category = record['activity']?['category'] as String?;
        return category == widget.gameName;
      }).toList();

      // Group by date - ใช้ yyyy-MM-dd เป็น key เพื่อง่ายต่อการ sort
      Map<String, List<Map<String, dynamic>>> grouped = {};
      Map<String, String> dateKeyToDisplay = {}; // เก็บ display format

      for (var record in filteredHistory) {
        final createdAt = record['created_at'] as String?;
        if (createdAt != null) {
          final date = DateTime.tryParse(createdAt);
          if (date != null) {
            // ใช้ yyyy-MM-dd เป็น key (sort ง่าย)
            final sortKey = DateFormat('yyyy-MM-dd').format(date);
            // เก็บ display format แยก
            final displayDate =
                DateFormat('dd MMM yyyy').format(date).toUpperCase();

            dateKeyToDisplay[sortKey] = displayDate;
            grouped.putIfAbsent(sortKey, () => []);
            grouped[sortKey]!.add(record);
          }
        }
      }

      // Sort dates descending (newest first) - ใช้ string comparison ได้เลยเพราะ format yyyy-MM-dd
      final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      // สร้าง map ใหม่ด้วย display key
      Map<String, List<Map<String, dynamic>>> sortedGrouped = {};
      for (var sortKey in sortedKeys) {
        final displayKey = dateKeyToDisplay[sortKey]!;
        sortedGrouped[displayKey] = grouped[sortKey]!;
      }

      setState(() {
        _groupedByDate = sortedGrouped;
        _isLoading = false;
      });

      debugPrint(
          '📊 Loaded ${filteredHistory.length} records for ${widget.gameName}');
      debugPrint('📊 Grouped into ${_groupedByDate.length} dates');
    } catch (e) {
      debugPrint('❌ Error loading activity history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                      widget.gameName,
                      style: AppTextStyles.body(24,
                          color: Palette.blueChip,
                          weight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              AppLocalizations.of(context)!.activityhistory_selectDate,
              style: AppTextStyles.body(18, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Date List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Palette.blueChip))
                  : _groupedByDate.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadActivityHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _groupedByDate.length,
                            itemBuilder: (context, index) {
                              final dateKey =
                                  _groupedByDate.keys.elementAt(index);
                              final records = _groupedByDate[dateKey]!;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DailyActivityScreen(
                                        date: dateKey,
                                        records: records,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  height: 70,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: Palette.softShadow,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              color: Palette.error),
                                          const SizedBox(width: 15),
                                          Text(
                                            dateKey,
                                            style: AppTextStyles.body(18,
                                                color: Colors.black87,
                                                weight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      // Badge แสดงจำนวนครั้ง
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Palette.lightBlue,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.activityhistory_times(records.length),
                                          style: AppTextStyles.body(14,
                                              color: Colors.white,
                                              weight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.activityhistory_noHistory,
            style: AppTextStyles.body(20, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.activityhistory_inCategory(widget.gameName),
            style: AppTextStyles.body(16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
