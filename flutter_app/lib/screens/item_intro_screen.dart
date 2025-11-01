// lib/screens/item_intro_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

class ItemIntroScreen extends StatefulWidget {
  final Activity activity;
  const ItemIntroScreen({super.key, required this.activity});

  @override
  State<ItemIntroScreen> createState() => _ItemIntroScreenState();
}

class _ItemIntroScreenState extends State<ItemIntroScreen> {
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

  // 🆕 เปลี่ยนจาก VideoPlayerController เป็น media_kit
  Player? _player;
  VideoController? _videoController;
  String _youtubeVideoId = '';

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

  @override
  void initState() {
    super.initState();

    _rawSegments =
        (widget.activity.segments as List<dynamic>?)?.where((segment) {
              final text = (segment['text'] as String?)?.trim() ?? '';
              return text.isNotEmpty && text != '[Music]';
            }).toList() ??
            [];
    totalSegments = _rawSegments.length;

    _segmentResults = _rawSegments.asMap().entries.map((entry) {
      final segment = entry.value as Map<String, dynamic>;
      return SegmentResult(
          id: segment['id'] as String? ?? 'seg_${entry.key}',
          text: segment['text'] as String? ?? 'Placeholder',
          maxScore: 0);
    }).toList();

    if (widget.activity.videoUrl != null) {
      _youtubeVideoId =
          YoutubePlayer.convertUrlToId(widget.activity.videoUrl!) ?? '';
    }

    // 🆕 เริ่มโหลดวิดีโอ
    if (_youtubeVideoId.isNotEmpty) {
      _initializeVideo();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _childId = context.read<UserProvider>().currentChildId;
    });
  }

  // 🆕 ฟังก์ชันโหลดวิดีโอ
  Future<void> _initializeVideo() async {
    setState(() => _isVideoLoading = true);

    try {
      // เรียก API Backend ดึง Direct URL
      final directUrl = await YouTubeService.getDirectVideoUrl(_youtubeVideoId);

      if (directUrl != null && mounted) {
        // สร้าง Player
        _player = Player();
        _videoController = VideoController(_player!);

        // เปิดวิดีโอ
        await _player!.open(Media(directUrl));

        setState(() {
          _isVideoLoading = false;
          _isPlayerReady = true;
        });
      } else {
        setState(() {
          _isVideoLoading = false;
          _videoError = 'ไม่สามารถโหลดวิดีโอได้';
        });
      }
    } catch (e) {
      setState(() {
        _isVideoLoading = false;
        _videoError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

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

  // 🆕 ฟังก์ชันเล่น Section ด้วย media_kit
  void _playSection() {
    if (_player == null || !_isPlayerReady) return;
    if (_rawSegments.isEmpty || current > totalSegments) return;

    final currentSegment = _rawSegments[current - 1] as Map<String, dynamic>;
    final start = (currentSegment['start'] as num?)?.toDouble();
    final end = (currentSegment['end'] as num?)?.toDouble();

    if (start != null && end != null) {
      // Seek ไปยังเวลาเริ่มต้น
      _player!.seek(Duration(milliseconds: (start * 1000).toInt()));
      _player!.play();

      // หยุดเมื่อถึงเวลาสิ้นสุด
      final durationMs = ((end - start) * 1000).toInt();
      Timer(Duration(milliseconds: durationMs), () {
        if (mounted && _player != null) {
          _player!.pause();
        }
      });
    }
  }

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

    if (completedSegmentsCount < totalSegments) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please complete all segments before finishing.')));
      return;
    }

    try {
      final result = await _activityService.finalizeQuest(
        childId: _childId!,
        activityId: widget.activity.id,
        segmentResults: _segmentResults,
        activityMaxScore: widget.activity.maxScore,
      );

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
              if (_youtubeVideoId.isNotEmpty)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _isVideoLoading
                        ? Center(child: CircularProgressIndicator(color: sky))
                        : _videoError != null
                            ? Center(
                                child: Text(_videoError!,
                                    style: GoogleFonts.luckiestGuy(
                                        color: Colors.white)))
                            : _videoController != null
                                ? Video(controller: _videoController!)
                                : Center(
                                    child: Text('Video not available',
                                        style: GoogleFonts.luckiestGuy(
                                            color: Colors.white))),
                  ),
                )
              else
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                      child: Text('No video available',
                          style: GoogleFonts.luckiestGuy(fontSize: 16))),
                ),

              const SizedBox(height: 8),

              Center(
                child: Text('TAP TO PLAY/PAUSE',
                    style:
                        GoogleFonts.luckiestGuy(fontSize: 11, color: deepGrey)),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cast, size: 28, color: deepGrey.withOpacity(0.5)),
                  const SizedBox(width: 16),
                  Icon(Icons.airplay,
                      size: 28, color: deepGrey.withOpacity(0.5)),
                ],
              ),
              const SizedBox(height: 14),

              _contentCard(
                  text: currentText,
                  score: currentSegmentResult.maxScore,
                  recognizedText: currentSegmentResult.recognizedText),
              const SizedBox(height: 10),

              _statusCard(currentSegmentResult),
              const SizedBox(height: 20),

              Center(
                  child: Text('PAGE $current OF $totalSegments',
                      style: GoogleFonts.luckiestGuy(
                          fontSize: 13, color: deepGrey))),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                      child: _bottomBtn(
                          label: 'PREVIOUS',
                          bg: prevGrey,
                          fg: Colors.white,
                          onTap: current > 1
                              ? () => setState(() => current--)
                              : null)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _bottomBtn(
                          label: current < totalSegments ? 'NEXT' : 'FINISH',
                          bg: nextBlue,
                          fg: Colors.white,
                          onTap: current < totalSegments
                              ? () => setState(() => current++)
                              : _handleFinishQuest)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              color: actualBg, borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: Text(text,
              style: GoogleFonts.luckiestGuy(
                  color: textDark ? Colors.black : Colors.white, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _contentCard(
      {required String text, int? score, String? recognizedText}) {
    final isReviewed = score != null && score > 0;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SPEAK: ${text.toUpperCase()}',
              style: GoogleFonts.luckiestGuy(fontSize: 15, color: deepGrey)),
          const SizedBox(height: 10),
          Row(
            children: [
              _pillButton('PLAY SECTION', bluePill,
                  onTap: _isPlayerReady && _rawSegments.isNotEmpty
                      ? _playSection
                      : null),
              const SizedBox(width: 10),
              _pillButton(
                  'RECORD', isReviewed ? greenPill : const Color(0xFFE7686B),
                  onTap: _handleRecord),
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
          Container(
            height: 16,
            decoration: BoxDecoration(
                color: progressTrack, borderRadius: BorderRadius.circular(12)),
            child: isReviewed
                ? FractionallySizedBox(
                    widthFactor: score! / 100,
                    alignment: Alignment.centerLeft,
                    child: Container(
                        decoration: BoxDecoration(
                            color: greenPill,
                            borderRadius: BorderRadius.circular(12))))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _statusCard(SegmentResult result) {
    final statusText = switch (state) {
      'processing' => 'STATUS: AI PROCESSING…',
      'reviewed' =>
        'STATUS AI: "${result.recognizedText ?? "N/A"}" ✅ CORRECTNESS : ${result.maxScore}%',
      'finished' => 'STATUS: ALL SEGMENTS COMPLETED ✅',
      _ =>
        'STATUS: Ready to record Segment $current ${!_isPlayerReady ? '(Player Loading)' : ''}',
    };

    return Container(
      decoration: BoxDecoration(
          color: greyCard, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(statusText,
              style: TextStyle(
                  fontFamily: GoogleFonts.luckiestGuy().fontFamily,
                  fontSize: 12,
                  color: deepGrey)),
          const SizedBox(height: 10),
          Container(
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(
                'Audio Playback Controls Placeholder (Recording ID: ${result.audioUrl?.split('/').last ?? "N/A"})',
                style: GoogleFonts.openSans(fontSize: 12, color: deepGrey)),
          ),
        ],
      ),
    );
  }

  Widget _bottomBtn(
      {required String label,
      required Color bg,
      required Color fg,
      VoidCallback? onTap}) {
    final Color actualBg = onTap == null ? bg.withOpacity(0.6) : bg;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            color: actualBg, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.luckiestGuy(color: fg, fontSize: 15)),
      ),
    );
  }
}
