// lib/screens/item_intro_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yp;

import '../providers/user_provider.dart';
import '../services/activity_service.dart';
import '../models/activity.dart';
import '../routes/app_routes.dart';

/// Helper แยกเฉพาะไว้แปลง URL -> YouTube ID
/// (ตั้งชื่อว่า YoutubeUrlHelper เพื่อไม่ให้ชนกับ widget YoutubePlayer ของ package)
class YoutubeUrlHelper {
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

  // 🎥 YouTube controller (ใช้ package youtube_player_iframe)
  yp.YoutubePlayerController? _ytController;

  // 🔊 สำหรับเล่นเสียงที่บันทึกเอง
  final ap.AudioPlayer _playbackPlayer = ap.AudioPlayer();

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
  bool _isPlaybackPlaying = false; // สถานะ Playback

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
        maxScore: 0,
      );
    }).toList();

    // 3. กำหนด YouTube Video ID
    if (widget.activity.videoUrl != null) {
      _youtubeVideoId =
          YoutubeUrlHelper.convertUrlToId(widget.activity.videoUrl!) ?? '';
    }

    // 4. สร้าง YouTube controller ถ้ามี videoId
    if (_youtubeVideoId.isNotEmpty) {
      _ytController = yp.YoutubePlayerController.fromVideoId(
        videoId: _youtubeVideoId,
        autoPlay: false, // ✅ autoPlay อยู่ตรงนี้ (constructor) ไม่ใช่ใน params แล้ว
        params: const yp.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
        ),
      )..listen((event) {
          // ✅ PlayerState.ready ไม่มีแล้ว ใช้ PlayerState.cued แทน
          if (!_isPlayerReady && event.playerState == yp.PlayerState.cued) {
            if (mounted) {
              setState(() {
                _isPlayerReady = true;
              });
            }
          }
        });
    }

    // 5. โหลด childId
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _childId = context.read<UserProvider>().currentChildId;
    });

    // 6. Listener เมื่อไฟล์เสียงเล่นจบ
    _playbackPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isPlaybackPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _ytController?.close(); // ปิด YouTube controller
    _playbackPlayer.dispose(); // ปิด audio player
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
    if (_rawSegments.isEmpty || current > totalSegments) {
      return 'Activity Content Missing.';
    }
    return (_rawSegments[current - 1] as Map<String, dynamic>)['text']
            as String? ??
        'Text not found.';
  }

  // 🔊 เล่น Section ด้วย youtube_player_iframe: seekTo + playVideo + pauseVideo
  void _playSection() {
    if (_ytController == null || !_isPlayerReady) return;
    if (_rawSegments.isEmpty || current > totalSegments) return;

    final currentSegment = _rawSegments[current - 1] as Map<String, dynamic>;
    final start = (currentSegment['start'] as num?)?.toDouble();
    final end = (currentSegment['end'] as num?)?.toDouble();

    if (start == null || end == null) return;

    final durationMs = ((end - start) * 1000).toInt();

    _ytController!.seekTo(seconds: start, allowSeekAhead: true);
    _ytController!.playVideo();

    Timer(Duration(milliseconds: durationMs), () {
      if (mounted && _ytController != null) {
        _ytController!.pauseVideo();
      }
    });
  }

  // 🔊 Playback เสียงที่บันทึกเอง
  void _playOwnRecording(String? audioPath) async {
    if (audioPath == null || audioPath.isEmpty) return;

    if (_isPlaybackPlaying) {
      await _playbackPlayer.pause();
      setState(() => _isPlaybackPlaying = false);
      return;
    }

    try {
      await _playbackPlayer.play(ap.DeviceFileSource(audioPath));
      setState(() => _isPlaybackPlaying = true);
    } catch (e) {
      debugPrint('Self-Playback Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to play back recording.')),
      );
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

        state = 'reviewed';
        point = score;
      });
    }
  }

  Future<void> _handleFinishQuest() async {
    if (_childId == null) return;

    try {
      final result = await _activityService.finalizeQuest(
        childId: _childId!,
        activityId: widget.activity.id,
        segmentResults: _segmentResults,
        activityMaxScore: widget.activity.maxScore,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: {
          'activityName': widget.activity.name,
          'totalScore': result['calculatedScore'] as int? ?? 0,
          'scoreEarned': result['scoreEarned'] as int? ?? 0,
          'timeSpend': 120,
          'activityObject': widget.activity,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing quest: ${e.toString()}')),
      );
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Error: No segments found for ${widget.activity.name}.',
            style: GoogleFonts.luckiestGuy(fontSize: 20),
          ),
        ),
      );
    }

    final currentSegmentResult = _currentSegmentResult;
    final currentText = _getCurrentSegmentText();

    final titleStyle = GoogleFonts.luckiestGuy(
      color: sky,
      fontSize: 22,
      height: 1.05,
      letterSpacing: .3,
    );

    final hasVideo = _ytController != null && _youtubeVideoId.isNotEmpty;

    if (hasVideo) {
      return yp.YoutubePlayerScaffold(
        controller: _ytController!,
        aspectRatio: 16 / 9,
        builder: (context, player) {
          return _buildScaffold(
            context,
            titleStyle: titleStyle,
            currentSegmentResult: currentSegmentResult,
            currentText: currentText,
            videoWidget: player,
          );
        },
      );
    }

    // กรณีไม่มีวิดีโอ (หรือ videoUrl ว่าง) ก็แสดง Scaffold ปกติ
    return _buildScaffold(
      context,
      titleStyle: titleStyle,
      currentSegmentResult: currentSegmentResult,
      currentText: currentText,
      videoWidget: Center(
        child: Text(
          'Video not available',
          style: GoogleFonts.luckiestGuy(color: Colors.white),
        ),
      ),
    );
  }

  // แยก Scaffold ออกมาให้เรียกใช้ได้ทั้งกรณีมี/ไม่มี YouTube player
  Widget _buildScaffold(
    BuildContext context, {
    required TextStyle titleStyle,
    required SegmentResult currentSegmentResult,
    required String currentText,
    required Widget videoWidget,
  }) {
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
              // 🎥 Video Player
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: videoWidget,
                ),
              ),
              const SizedBox(height: 8),

              // Caption segment
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
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ปุ่ม Cast / AirPlay (ยังเป็น placeholder)
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
              ),
              const SizedBox(height: 10),

              // การ์ดสถานะ
              _statusCard(currentSegmentResult),
              const SizedBox(height: 20),

              // หน้าปัจจุบัน
              Center(
                child: Text(
                  '$current / $totalSegments',
                  style: GoogleFonts.luckiestGuy(
                    fontSize: 16,
                    color: deepGrey,
                  ),
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
                                state = 'idle';
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
                  Expanded(
                    child: _bottomBtn(
                      label: current == totalSegments ? 'FINISH >' : 'NEXT >',
                      bg: nextBlue,
                      fg: Colors.white,
                      onTap: () {
                        if (current < totalSegments) {
                          setState(() {
                            current++;
                            state = _currentSegmentResult.maxScore > 0
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
            color: actualBg,
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

  Widget _contentCard({required String text, int? score}) {
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
              _pillButton(
                'PLAY SECTION',
                bluePill,
                onTap: _isPlayerReady && _rawSegments.isNotEmpty
                    ? _playSection
                    : null,
              ),
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
              Text(
                'POINT: ${score ?? 0}%',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 13,
                  color: deepGrey,
                ),
              ),
              Text(
                'COMPLETED: $completedSegmentsCount/$totalSegments',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 13,
                  color: deepGrey,
                ),
              ),
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
                    widthFactor: (score ?? 0) / 100,
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
    final String recognizedTextDisplay =
        result.recognizedText?.trim() ?? "N/A";

    final statusText = switch (state) {
      'processing' => 'STATUS: AI PROCESSING…',
      'reviewed' =>
        'STATUS AI: "$recognizedTextDisplay" ✅ CORRECTNESS : ${result.maxScore}%',
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
                          fontSize: 13,
                          color: deepGrey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(
                          _isPlaybackPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: sky,
                          size: 28,
                        ),
                        onPressed: () => _playOwnRecording(result.audioUrl),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'Record to enable playback',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: deepGrey.withOpacity(0.5),
                      ),
                    ),
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
