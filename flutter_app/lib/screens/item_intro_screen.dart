// lib/screens/item_intro_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:audioplayers/audioplayers.dart'; // 🆕 สำหรับเล่นเสียงที่บันทึก

import '../providers/user_provider.dart';
import '../services/activity_service.dart';
import '../services/youtube_service.dart'; // 🆕
import '../models/activity.dart';
import '../routes/app_routes.dart';

class YoutubePlayer {
  static String? convertUrlToId(String url, {bool trimWhitespaces = true}) {
    if (!url.contains("http") && (url.length == 11)) return url;
    if (trimWhitespaces) url = url.trim();
    if (url.isEmpty) return null;
    for (var exp in [
      RegExp(
          r"^https?\:\/\/(?:www\.|m\.)?youtube\.com\/watch\?.*v=([a-zA-Z0-9_\-]+).*$"),
      RegExp(
          r"^https?\:\/\/(?:www\.|m\.)?youtube\.com\/v\/([a-zA-Z0-9_\-]+).*$"),
      RegExp(r"^https?\:\/\/(?:www\.|m\.)?youtu\.be\/([a-zA-Z0-9_\-]+).*$"),
      RegExp(
          r"^https?\:\/\/(?:www\.|m\.)?youtube\.com\/embed\/([a-zA-Z0-9_\-]+).*$"),
    ]) {
      Match? match = exp.firstMatch(url);
      if (match != null && match.groupCount >= 1) return match.group(1);
    }
    return null;
  }
}

// ⚠️ Note: SegmentResult class must be defined in activity_service.dart

class ItemIntroScreen extends StatefulWidget {
  final Activity activity;
  const ItemIntroScreen({super.key, required this.activity});

  @override
  State<ItemIntroScreen> createState() => _ItemIntroScreenState();
}

class _ItemIntroScreenState extends State<ItemIntroScreen> {
  // ----------------------------------------------------
  // 1. CONSTANTS & STATE
  // ----------------------------------------------------

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

  Player? _player;
  VideoController? _videoController;
  final AudioPlayer _playbackPlayer =
      AudioPlayer(); // 🆕 Player สำหรับฟังเสียงตัวเอง

  String _youtubeVideoId = ''; // ID จาก URL

  late List<dynamic> _rawSegments;
  late final int totalSegments;

  String state = 'idle';
  int current = 1;
  int point = 0;

  late List<SegmentResult> _segmentResults;

  final ActivityService _activityService = ActivityService();
  String? _childId;
  bool _isPlayerReady = false;
  bool _isVideoLoading = true;
  String? _videoError;
  bool _isPlaybackPlaying = false; // 🆕 สถานะ Playback

  @override
  void initState() {
    super.initState();

    // 1. เตรียม Segment Data
    _rawSegments = (widget.activity.segments as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .where((segment) {
          final text = (segment['text'] as String?)?.trim() ?? '';
          return text.isNotEmpty && text != '[Music]';
        }).toList() ??
        [];
    totalSegments = _rawSegments.length;

    // 2. ตั้งค่า Segment Results
    _segmentResults = _rawSegments.asMap().entries.map((entry) {
      final segment = entry.value as Map<String, dynamic>;
      return SegmentResult(
          id: segment['id'] as String? ?? 'seg_${entry.key}',
          text: segment['text'] as String? ?? 'Placeholder',
          maxScore: 0);
    }).toList();

    // 3. กำหนด YouTube Video ID
    if (widget.activity.videoUrl != null) {
      _youtubeVideoId =
          YoutubePlayer.convertUrlToId(widget.activity.videoUrl!) ?? '';
    }

    // 4. โหลด User ID และ Direct URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _childId = context.read<UserProvider>().currentChildId;
      if (_youtubeVideoId.isNotEmpty) {
        _initializeVideo();
      }
    });

    // 🆕 Listener เมื่อไฟล์เสียงเล่นจบ
    _playbackPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isPlaybackPlaying = false);
      }
    });
  }

  // 🆕 NEW: โหลด Direct URL และ Initialize Player
  Future<void> _initializeVideo() async {
    setState(() => _isVideoLoading = true);

    try {
      final directUrl = await YouTubeService.getDirectVideoUrl(_youtubeVideoId);

      if (directUrl != null && mounted) {
        _player = Player();
        _videoController = VideoController(_player!);

        await _player!.open(Media(directUrl));

        setState(() {
          _videoError = null;
          _isVideoLoading = false;
          _isPlayerReady = true;
        });
      } else if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = 'ไม่สามารถโหลด URL วิดีโอโดยตรงได้';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = 'Video Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _playbackPlayer.dispose(); // 🆕 ต้อง dispose playback player
    super.dispose();
  }

  // ----------------------------------------------------
  // 2. HELPERS (Logic)
  // ----------------------------------------------------

  SegmentResult get _currentSegmentResult {
    if (current > 0 && current <= totalSegments) {
      return _segmentResults[current - 1];
    }
    return SegmentResult(id: '', text: 'Error', maxScore: 0);
  }

  int get completedSegmentsCount =>
      _segmentResults.where((r) => r.maxScore > 0).length;

  String _getCurrentSegmentText() {
    if (_rawSegments.isEmpty || current > totalSegments)
      return 'Activity Content Missing.';
    return (_rawSegments[current - 1] as Map<String, dynamic>)['text']
            as String? ??
        'Text not found.';
  }

  // 🆕 Logic การเล่น Section ด้วย media_kit.seekTo()
  void _playSection() {
    if (_player == null || !_isPlayerReady) return;
    if (_rawSegments.isEmpty || current > totalSegments) return;

    final currentSegment = _rawSegments[current - 1] as Map<String, dynamic>;
    final start = (currentSegment['start'] as num?)?.toDouble();
    final end = (currentSegment['end'] as num?)?.toDouble();

    if (start != null && end != null) {
      _player!.seek(Duration(milliseconds: (start * 1000).toInt()));
      _player!.play();

      final duration = (end * 1000).toInt() - (start * 1000).toInt();
      Timer(Duration(milliseconds: duration), () {
        if (mounted && _player != null) {
          _player!.pause();
        }
      });
    }
  }

  // 🆕 Logic สำหรับ Playback เสียงที่บันทึก
  void _playOwnRecording(String? audioPath) async {
    if (audioPath == null || audioPath.isEmpty) return;

    if (_isPlaybackPlaying) {
      await _playbackPlayer.pause();
      setState(() => _isPlaybackPlaying = false);
      return;
    }

    try {
      // 1. เล่นไฟล์เสียงจาก Local Path
      await _playbackPlayer.play(DeviceFileSource(audioPath));
      setState(() => _isPlaybackPlaying = true);
    } catch (e) {
      debugPrint('Self-Playback Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play back recording.')));
      setState(() => _isPlaybackPlaying = false);
    }
  }

  // ----------------------------------------------------
  // 3. EVENT HANDLERS
  // ----------------------------------------------------

  Future<void> _handleRecord() async {
    if (_childId == null || _rawSegments.isEmpty) return;

    setState(() => state = 'processing');
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.record,
      arguments: {
        'originalText': _getCurrentSegmentText(),
        'segmentId': _currentSegmentResult.id,
      },
    );

    if (result != null && mounted) {
      final Map<String, dynamic> data = result as Map<String, dynamic>;
      final int score = data['score'] as int? ?? 0;
      final String recognizedText = data['recognizedText'] as String? ?? 'N/A';
      final String audioUrl = data['audioUrl'] as String? ?? '';

      setState(() {
        _segmentResults[current - 1] = SegmentResult(
          id: _currentSegmentResult.id,
          text: _currentSegmentResult.text,
          maxScore: score,
          recognizedText: recognizedText,
          audioUrl: audioUrl,
        );

        this.state = 'reviewed';
        this.point = score;
      });
    }
  }

  Future<void> _handleFinishQuest() async {
    if (_childId == null) return;

    // ⚠️ Logic การนำทางที่ถูกแก้ไข (กด Next/Finish ได้เสมอ)

    try {
      final result = await _activityService.finalizeQuest(
        childId: _childId!,
        activityId: widget.activity.id,
        segmentResults: _segmentResults,
        activityMaxScore: widget.activity.maxScore,
      );

      // 2. นำทางไป Result Screen
      Navigator.pushReplacementNamed(context, AppRoutes.result, arguments: {
        'activityName': widget.activity.name,
        'totalScore': result['calculatedScore'] as int? ?? 0,
        'timeSpend': 120,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing quest: ${e.toString()}')));
    }
  }

  // ----------------------------------------------------
  // 4. BUILD METHOD (UI)
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_rawSegments.isEmpty) {
      return Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
            backgroundColor: cream,
            elevation: 0,
            leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: () => Navigator.pop(context))),
        body: Center(
            child: Text('Error: No segments found for ${widget.activity.name}.',
                style: GoogleFonts.luckiestGuy(fontSize: 20))),
      );
    }

    final isCurrentSegmentCompleted = _currentSegmentResult.maxScore > 0;
    final currentText = _getCurrentSegmentText();
    final currentSegmentResult = _currentSegmentResult;

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
          widget.activity.name.toUpperCase(),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🆕 Video Player ด้วย media_kit
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.black, // สีพื้นหลังสำหรับวิดีโอ
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _isVideoLoading
                      ? Center(child: CircularProgressIndicator(color: sky))
                      : _videoError != null
                          ? Center(
                              child: Text('Video Error: $_videoError',
                                  style: GoogleFonts.luckiestGuy(
                                      color: Colors.white)))
                          : _isPlayerReady && _videoController != null
                              ? Video(
                                  controller:
                                      _videoController!) // 🆕 แสดง Video
                              : Center(
                                  child: Text('Video not available',
                                      style: GoogleFonts.luckiestGuy(
                                          color: Colors.white))),
                ),
              ),

              const SizedBox(height: 8),

              // Caption
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Segment $current of $totalSegments',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ปุ่ม Cast / AirPlay (Placeholder)
              Row(
                children: [
                  _pillButton('CAST TO TV', lilac,
                      textDark: true, onTap: () {}),
                  const SizedBox(width: 10),
                  _pillButton('AIRPLAY', sunshine,
                      textDark: true, onTap: () {}),
                ],
              ),
              const SizedBox(height: 14),

              // การ์ดเนื้อหา (Segment Controls)
              _contentCard(
                text: currentText,
                score: currentSegmentResult.maxScore,
                recognizedText: currentSegmentResult.recognizedText,
              ),
              const SizedBox(height: 10),

              // การ์ดสถานะ
              _statusCard(currentSegmentResult), // 🆕 ถูกอัปเดตแล้ว
              const SizedBox(height: 20),

              // หน้า
              Center(
                child: Text(
                  '$current / $totalSegments',
                  style: GoogleFonts.luckiestGuy(fontSize: 16, color: deepGrey),
                ),
              ),
              const SizedBox(height: 10),

              // ปุ่มล่าง (Navigation)
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
                                this.state = 'idle';
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
                      '$completedSegmentsCount/$totalSegments',
                      style: GoogleFonts.luckiestGuy(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 🛑 Logic การนำทางที่ถูกแก้ไข (กด Next/Finish ได้เสมอ)
                  Expanded(
                    child: _bottomBtn(
                      label: current == totalSegments ? 'FINISH >' : 'NEXT >',
                      bg: nextBlue,
                      fg: Colors.white,
                      onTap: () {
                        if (current < totalSegments) {
                          setState(() {
                            current++;
                            this.state = _currentSegmentResult.maxScore > 0
                                ? 'reviewed'
                                : 'idle';
                          });
                        } else {
                          _handleFinishQuest();
                        }
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

  // ----------------------------------------------------
  // 5. HELPER WIDGETS
  // ----------------------------------------------------

  Widget _pillButton(String text, Color bg,
      {bool textDark = false, VoidCallback? onTap}) {
    final Color actualBg = onTap == null ? bg.withOpacity(0.6) : bg;

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

  Widget _contentCard(
      {required String text, int? score, String? recognizedText}) {
    final isReviewed = score != null && score > 0;
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
            'SPEAK: ${text.toUpperCase()}',
            style: GoogleFonts.luckiestGuy(fontSize: 15, color: deepGrey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pillButton('PLAY SECTION', bluePill,
                  onTap: _isPlayerReady && _rawSegments.isNotEmpty
                      ? _playSection
                      : null),
              const SizedBox(width: 10),
              _pillButton(
                'RECORD',
                isReviewed ? greenPill : const Color(0xFFE7686B),
                onTap: _handleRecord,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('POINT: ${score ?? 0}%',
                  style:
                      GoogleFonts.luckiestGuy(fontSize: 13, color: deepGrey)),
              Text('COMPLETED: $completedSegmentsCount/$totalSegments',
                  style:
                      GoogleFonts.luckiestGuy(fontSize: 13, color: deepGrey)),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: progressTrack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isReviewed
                ? FractionallySizedBox(
                    widthFactor: score! / 100,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: greenPill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _statusCard(SegmentResult result) {
    // 🆕 แสดงผลเต็ม (ไม่ต้องย่อ)
    final String recognizedTextDisplay = result.recognizedText?.trim() ?? "N/A";

    final statusText = switch (state) {
      'processing' => 'STATUS: AI PROCESSING…',
      // 🆕 แก้ไข: แสดง recognizedText เต็ม
      'reviewed' =>
        'STATUS AI: "${recognizedTextDisplay}" ✅ CORRECTNESS : ${result.maxScore}%',
      'finished' => 'STATUS: ALL SEGMENTS COMPLETED ✅',
      _ =>
        'STATUS: Ready to record Segment $current ${!_isPlayerReady ? '(Player Loading)' : ''}',
    };

    final bool isRecordingAvailable =
        result.audioUrl != null && result.audioUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: greyCard,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. สถานะ (แสดงผลเต็มบรรทัด)
          Text(
            statusText,
            // ⚠️ Warning: TextStyle ภายใน GoogleFonts.luckiestGuy อาจมีปัญหาการ wrap
            style: TextStyle(
              fontFamily: GoogleFonts.luckiestGuy().fontFamily,
              fontSize: 12,
              color: deepGrey,
            ),
          ),
          const SizedBox(height: 10),
          // 2. 🆕 ปุ่มฟังเสียงตัวเองซ้ำ
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: isRecordingAvailable ? Colors.white : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: isRecordingAvailable
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up, size: 20, color: deepGrey),
                      const SizedBox(width: 8),
                      Text(
                          _isPlaybackPlaying
                              ? 'PAUSE PLAYBACK...'
                              : 'LISTEN TO YOUR RECORDING',
                          style: GoogleFonts.luckiestGuy(
                              fontSize: 13, color: deepGrey)),
                      const SizedBox(width: 10),
                      // 🆕 ปุ่ม Playback
                      IconButton(
                        icon: Icon(
                            _isPlaybackPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: sky,
                            size: 28),
                        onPressed: () => _playOwnRecording(result.audioUrl),
                      ),
                    ],
                  )
                : Center(
                    child: Text('Record to enable playback',
                        style: GoogleFonts.openSans(
                            fontSize: 12, color: deepGrey.withOpacity(0.5))),
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
    final Color actualBg = onTap == null ? bg.withOpacity(0.6) : bg;

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
