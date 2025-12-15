import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityHistoryScreen extends StatefulWidget {
  final String gameName;

  const ActivityHistoryScreen({super.key, required this.gameName});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  // Theme Colors
  static const cream = Color(0xFFFFF5CD);
  static const blueTitle = Color(0xFF4DA9FF);
  static const greySubtitle = Color(0xFF9E9E9E);
  static const itemBlue = Color(0xFF90CAF9); // สีฟ้าพื้นหลังวันที่
  static const numberPink = Color(0xFFFF8A80); // สีชมพูวงกลมเลข

  // Mock Data (ข้อมูลสมมติ)
  final List<Map<String, dynamic>> _history = [
    {'id': 1, 'date': '24 JULY 2025', 'time': '01:04 PM', 'score': 100},
    {'id': 2, 'date': '28 JULY 2025', 'time': '10:30 AM', 'score': 80},
    {'id': 3, 'date': '10 AUGUST 2025', 'time': '04:15 PM', 'score': 120},
    {'id': 4, 'date': '14 AUGUST 2025', 'time': '09:00 AM', 'score': 90},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 30, color: Colors.black87),
                  ),
                  Text(
                    widget.gameName, // "PING PONG GAME"
                    style: GoogleFonts.luckiestGuy(fontSize: 24, color: blueTitle),
                  ),
                  const Icon(Icons.share, size: 28, color: Colors.black87),
                ],
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'PLAYING RESULTS',
                style: GoogleFonts.luckiestGuy(fontSize: 20, color: greySubtitle),
              ),

              const SizedBox(height: 20),

              // --- List of Results ---
              Expanded(
                child: ListView.separated(
                  itemCount: _history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _buildHistoryItem(
                      number: item['id'],
                      date: item['date'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem({required int number, required String date}) {
    return Row(
      children: [
        // Number Circle
        Container(
          width: 50, height: 50,
          decoration: const BoxDecoration(
            color: numberPink,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: GoogleFonts.luckiestGuy(fontSize: 24, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        
        // Date Box
        Expanded(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: itemBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: GoogleFonts.luckiestGuy(fontSize: 20, color: Colors.white),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}