// lib/screens/item_intro_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemIntroScreen extends StatefulWidget {
  const ItemIntroScreen({super.key});

  @override
  State<ItemIntroScreen> createState() => _ItemIntroScreenState();
}

class _ItemIntroScreenState extends State<ItemIntroScreen> {
  // ===== Design System (สี/ฟอนต์) =====
  static const cream = Color(0xFFFFF5CD);
  static const sky = Color(0xFF0D92F4);
  static const lilac = Color(0xFFC68AF6);
  static const sunshine = Color(0xFFF0C44D);
  static const bluePill = Color(0xFF78BDF1);
  static const greenPill = Color(0xFF77C58C);
  static const greyCard = Color(0xFFEDEFF3);
  static const deepGrey = Color(0xFF5D5D5D);
  static const progressTrack = Color(0xFFE9E0C7);
  static const nextBlue = Color(0xFF1487FF);
  static const prevGrey = Color(0xFFD6D5D3);

  String state = 'idle';
  int current = 1;
  int completed = 0;
  int point = 0;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.luckiestGuy(
      color: sky,
      fontSize: 22,
      height: 1.05,
      letterSpacing: .3,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'TALE OF PETER RABBIT\n& BENJAMIN BUNNY',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView( // ✅ แก้ overflow
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // วิดีโอ
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.play_circle_fill,
                    size: 70, color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 8),

              // Caption
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Then he hopped around a corner.',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ปุ่ม Cast / AirPlay
              Row(
                children: [
                  _pillButton('CAST TO TV', lilac, textDark: true, onTap: () {}),
                  const SizedBox(width: 10),
                  _pillButton('AIRPLAY', sunshine, textDark: true, onTap: () {}),
                ],
              ),
              const SizedBox(height: 14),

              // การ์ดเนื้อหา
              _contentCard(),
              const SizedBox(height: 10),

              // การ์ดสถานะ
              _statusCard(),
              const SizedBox(height: 20),

              // หน้า
              Center(
                child: Text(
                  '${current.toString()} / 10',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 16,
                    color: deepGrey,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ปุ่มล่าง
              Row(
                children: [
                  Expanded(
                    child: _bottomBtn(
                      label: '< PREVIOUS',
                      bg: prevGrey,
                      fg: deepGrey,
                      onTap: current > 1
                          ? () => setState(() {
                                current--;
                              })
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '$completed/10',
                      style: GoogleFonts.luckiestGuy(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bottomBtn(
                      label: state == 'finished' ? 'FINISH >' : 'NEXT >',
                      bg: nextBlue,
                      fg: Colors.white,
                      onTap: () {
                        setState(() {
                          if (current < 10) {
                            current++;
                          } else {
                            state = 'finished';
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillButton(String text, Color bg,
      {bool textDark = false, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.luckiestGuy(
              color: textDark ? Colors.black : Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _contentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state == 'reviewed'
                ? 'SPEAK: I LOVE YOU'
                : 'SPEAK: THEN HE HOPED AROUND A CORNER',
            style: GoogleFonts.luckiestGuy(fontSize: 15, color: deepGrey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pillButton('PLAY SECTION', bluePill, onTap: () {}),
              const SizedBox(width: 10),
              _pillButton(
                'RECORD',
                state == 'reviewed' ? greenPill : const Color(0xFFE7686B),
                onTap: () {
                  setState(() => state = 'processing');
                  Future.delayed(const Duration(seconds: 1), () {
                    if (!mounted) return;
                    setState(() {
                      state = 'reviewed';
                      point = 100;
                      completed = 10;
                    });
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('POINT: $point%',
                  style: GoogleFonts.luckiestGuy(fontSize: 13, color: deepGrey)),
              Text('COMPLETED: $completed/10',
                  style: GoogleFonts.luckiestGuy(fontSize: 13, color: deepGrey)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: progressTrack,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final statusText = switch (state) {
      'processing' => 'STATUS: AI PROCESSING…',
      'reviewed' => 'STATUS AI: “I LOVE YOU”  CORRECTNESS : 100%',
      'finished' => 'STATUS: COMPLETED ✅',
      _ => 'STATUS: AI “THEN” CORRECTNESS : 0%',
    };

    return Container(
      decoration: BoxDecoration(
        color: greyCard,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontSize: 12,
              color: deepGrey,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.play_arrow_rounded, size: 24),
                const SizedBox(width: 6),
                Text('0:00 / 0:00',
                    style: GoogleFonts.luckiestGuy(
                        color: deepGrey, fontSize: 13)),
                const Spacer(),
                const Icon(Icons.volume_up, size: 20),
                const SizedBox(width: 4),
                const Icon(Icons.more_horiz, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBtn({
    required String label,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
  }) {
    final Color actualBg =
        onTap == null ? bg.withValues(alpha: 0.6) : bg;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: actualBg,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.luckiestGuy(color: fg, fontSize: 15),
        ),
      ),
    );
  }
}
