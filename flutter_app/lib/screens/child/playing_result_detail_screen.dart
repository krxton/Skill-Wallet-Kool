import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayingResultDetailScreen extends StatelessWidget {
  final int sessionNumber;
  final String date;
  final int medals;

  const PlayingResultDetailScreen({
    super.key,
    required this.sessionNumber,
    required this.date,
    required this.medals,
  });

  static const cream = Color(0xFFFFF5CD);
  static const skyBlue = Color(0xFF5AB2FF);
  static const redText = Color(0xFFFF8A8A);

  @override
  Widget build(BuildContext context) {
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
                          'PLAYING RESULT',
                          style: GoogleFonts.luckiestGuy(
                              fontSize: 24, color: skyBlue),
                        ),
                        Text(
                          '$date | TIME $sessionNumber',
                          style: GoogleFonts.luckiestGuy(
                              fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 1. Medals Section
              Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Colors.orange, size: 35),
                  const SizedBox(width: 10),
                  Text(
                    'MEDALS',
                    style: GoogleFonts.luckiestGuy(
                        fontSize: 24, color: Colors.orange),
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
                      '$medals',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 24, color: Colors.black87),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 25),

              // 2. Diary Section
              Text(
                'DIARY',
                style: GoogleFonts.luckiestGuy(fontSize: 22, color: redText),
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
                  "Today I learned about addition! It was fun but a little bit hard at the end.",
                  style:
                      GoogleFonts.nunito(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 25),

              // 3. Image Section
              Text(
                'IMAGE',
                style: GoogleFonts.luckiestGuy(fontSize: 22, color: redText),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://picsum.photos/400/300'), // รูปตัวอย่าง
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 4. Time Section
              Center(
                child: Column(
                  children: [
                    Text(
                      'TIME USED',
                      style:
                          GoogleFonts.luckiestGuy(fontSize: 20, color: redText),
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
                        '00:15:30', // เวลาที่ใช้
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
}
