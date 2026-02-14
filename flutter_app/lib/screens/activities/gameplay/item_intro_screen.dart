import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yp;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../../providers/user_provider.dart';
import '../../../services/activity_service.dart';
import '../../../models/activity.dart';
import '../../../routes/app_routes.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

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

  // 🎙️ สำหรับอัดเสียง
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  String _recordedFilePath = '';
  BytesBuilder? _webBytesBuilder;
  StreamSubscription<List<int>>? _webAudioSub;
  Uint8List? _webAudioBytes;

  // ⏱️ Stopwatch สำหรับจับเวลาทำกิจกรรม
  final Stopwatch _activityStopwatch = Stopwatch();
  final List<String> _tempAudioFiles = []; // เก็บรายการไฟล์เสียงที่ต้องลบ

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
        autoPlay: false,
        params: const yp.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          origin: 'https://www.youtube-nocookie.com',
        ),
      )..listen((event) {
          // เซ็ตเป็น ready เมื่อ player อยู่ในสถานะ cued, playing, หรือ paused
          if (!_isPlayerReady &&
              (event.playerState == yp.PlayerState.cued ||
                  event.playerState == yp.PlayerState.playing ||
                  event.playerState == yp.PlayerState.paused)) {
            if (mounted) {
              setState(() {
                _isPlayerReady = true;
              });
              debugPrint('✅ YouTube Player Ready');
            }
          }
        });

      // เซ็ตเป็น ready ทันทีถ้า controller สร้างเสร็จแล้ว
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isPlayerReady) {
          setState(() {
            _isPlayerReady = true;
          });
          debugPrint('✅ YouTube Player Ready (timeout)');
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

    // 7. เริ่มจับเวลากิจกรรม
    _activityStopwatch.start();
    debugPrint('⏱️ Activity timer started');
  }

  @override
  void dispose() {
    _ytController?.close(); // ปิด YouTube controller
    _playbackPlayer.dispose(); // ปิด audio player
    _audioRecorder.dispose(); // ปิด audio recorder
    _recordingTimer?.cancel();
    _webAudioSub?.cancel();
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
  void _playSection() async {
    if (_ytController == null) {
      debugPrint('❌ Play Section: YouTube controller is null');
      return;
    }

    if (!_isPlayerReady) {
      debugPrint('❌ Play Section: Player not ready yet');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.itemintro_videoLoading)),
      );
      return;
    }

    if (_rawSegments.isEmpty || current > totalSegments) {
      debugPrint('❌ Play Section: No segments or invalid current index');
      return;
    }

    final currentSegment = _rawSegments[current - 1] as Map<String, dynamic>;
    final start = (currentSegment['start'] as num?)?.toDouble();
    final end = (currentSegment['end'] as num?)?.toDouble();

    if (start == null || end == null) {
      debugPrint('❌ Play Section: Missing start/end time in segment data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.itemintro_timingIncomplete)),
      );
      return;
    }

    debugPrint('▶️ Playing section: ${start}s - ${end}s (+0.7s buffer)');
    final durationMs = ((end - start + 0.7) * 1000)
        .toInt(); // ✅ เพิ่ม 0.7 วินาทีให้เล่นยาวขึ้น

    try {
      await _ytController!.seekTo(seconds: start, allowSeekAhead: true);
      await _ytController!.playVideo();

      Timer(Duration(milliseconds: durationMs), () {
        if (mounted && _ytController != null) {
          _ytController!.pauseVideo();
          debugPrint('⏸️ Section playback ended');
        }
      });
    } catch (e) {
      debugPrint('❌ Play Section Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.itemintro_videoPlayError(e.toString()))),
        );
      }
    }
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
        SnackBar(content: Text(AppLocalizations.of(context)!.itemintro_playbackFailed)),
      );
      setState(() => _isPlaybackPlaying = false);
    }
  }

  // ----------------------------------------------------
  // 3. EVENT HANDLERS
  // ----------------------------------------------------

  Future<void> _handleRecord() async {
    if (_childId == null || _rawSegments.isEmpty) return;

    if (_isRecording) {
      // หยุดการอัด
      await _stopRecording();
    } else {
      // เริ่มการอัด
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // ขอ permission
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.itemintro_micPermission)),
        );
      }
      return;
    }

    try {
      if (kIsWeb) {
        // Web: ใช้ stream
        _webBytesBuilder = BytesBuilder(copy: false);
        final stream = await _audioRecorder.startStream(
          const RecordConfig(encoder: AudioEncoder.pcm16bits),
        );
        _webAudioSub = stream.listen((chunk) {
          _webBytesBuilder?.add(chunk);
        });
      } else {
        // Mobile/Desktop: บันทึกเป็นไฟล์ temp (จะลบหลังเสร็จกิจกรรม)
        final tempDir = await getTemporaryDirectory();
        _recordedFilePath =
            '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _recordedFilePath,
        );

        // เก็บ path ไว้ลบภายหลัง
        _tempAudioFiles.add(_recordedFilePath);
        debugPrint('📝 Added temp audio file: $_recordedFilePath');
      }

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // เริ่ม timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      });

      debugPrint('🎙️ Recording started');
    } catch (e) {
      debugPrint('❌ Recording start error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.itemintro_recordStartError(e.toString()))),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      state = 'processing';
    });

    // ตรวจสอบระยะเวลาที่อัด
    if (_recordingDuration.inSeconds < 1) {
      debugPrint('⚠️ Recording too short: ${_recordingDuration.inSeconds}s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.itemintro_recordTooShort)),
        );
        setState(() => state = 'idle');
      }
      return;
    }

    // แสดง loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.common_processing),
              const SizedBox(height: 10),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              Text(
                'ระยะเวลา: ${_recordingDuration.inSeconds} วินาที',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    try {
      Map<String, dynamic> result;

      if (kIsWeb) {
        // Web: ประมวลผล bytes
        await _webAudioSub?.cancel();
        _webAudioSub = null;
        final pcm = _webBytesBuilder?.toBytes();
        if (pcm == null || pcm.isEmpty) {
          throw Exception('ไม่มีข้อมูลเสียงที่บันทึก');
        }
        if (pcm.length < 8000) {
          // น้อยกว่า ~0.5 วินาทีที่ 16kHz
          throw Exception('ข้อมูลเสียงสั้นเกินไป');
        }
        _webAudioBytes = _pcm16ToWav(pcm, sampleRate: 44100, channels: 1);
        debugPrint('📦 Web audio size: ${_webAudioBytes!.length} bytes');
        result = await _activityService.evaluateAudioBytes(
          audioBytes: _webAudioBytes!,
          originalText: _getCurrentSegmentText(),
          filename: 'recording.wav',
        );
        _webBytesBuilder = null;
      } else {
        // Mobile/Desktop: ส่งไฟล์
        final audioFile = File(_recordedFilePath);
        if (!await audioFile.exists()) {
          throw Exception('ไม่พบไฟล์เสียงที่บันทึก');
        }
        final fileSize = await audioFile.length();
        if (fileSize < 1000) {
          throw Exception('ไฟล์เสียงมีขนาดเล็กเกินไป (${fileSize} bytes)');
        }
        debugPrint('📦 Audio file size: $fileSize bytes');
        result = await _activityService.evaluateAudio(
          audioFile: audioFile,
          originalText: _getCurrentSegmentText(),
        );
      }

      if (mounted) Navigator.pop(context); // ปิด loading dialog

      final int score = result['score'] as int? ?? 0;
      final String recognizedText = result['text'] as String? ?? 'N/A';

      if (mounted) {
        setState(() {
          _segmentResults[current - 1] = SegmentResult(
            id: _currentSegmentResult.id,
            text: _currentSegmentResult.text,
            maxScore: score,
            recognizedText: recognizedText,
            audioUrl: kIsWeb ? '' : _recordedFilePath,
          );

          state = 'reviewed';
          point = score;
        });

        // แสดง feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.itemintro_evalResult(score, recognizedText)),
            backgroundColor: score >= 70 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint(
          '✅ Recording processed: $score% (recognized: "$recognizedText")');
    } catch (e) {
      if (mounted) Navigator.pop(context); // ปิด loading dialog
      debugPrint('❌ Recording processing error: $e');
      if (mounted) {
        String errorMessage = 'เกิดข้อผิดพลาด';
        if (e.toString().contains('ไม่มีข้อมูลเสียง') ||
            e.toString().contains('สั้นเกินไป') ||
            e.toString().contains('ไม่พบไฟล์')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else if (e.toString().contains('Failed host lookup') ||
            e.toString().contains('SocketException')) {
          errorMessage = 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
        } else {
          errorMessage = 'เกิดข้อผิดพลาด: ${e.toString().substring(0, 50)}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => state = 'idle');
      }
    }
  }

  // Helper: Convert PCM16 to WAV format (for Web)
  Uint8List _pcm16ToWav(Uint8List pcmData,
      {required int sampleRate, required int channels}) {
    final int byteRate = sampleRate * channels * 2;
    final int blockAlign = channels * 2;
    final int subchunk2Size = pcmData.lengthInBytes;
    final int chunkSize = 36 + subchunk2Size;

    final bytes = BytesBuilder();
    bytes.add(_ascii('RIFF'));
    bytes.add(_le32(chunkSize));
    bytes.add(_ascii('WAVE'));
    bytes.add(_ascii('fmt '));
    bytes.add(_le32(16));
    bytes.add(_le16(1));
    bytes.add(_le16(channels));
    bytes.add(_le32(sampleRate));
    bytes.add(_le32(byteRate));
    bytes.add(_le16(blockAlign));
    bytes.add(_le16(16));
    bytes.add(_ascii('data'));
    bytes.add(_le32(subchunk2Size));
    bytes.add(pcmData);

    return bytes.toBytes();
  }

  Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);
  Uint8List _le16(int value) =>
      Uint8List.fromList([value & 0xFF, (value >> 8) & 0xFF]);
  Uint8List _le32(int value) => Uint8List.fromList([
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ]);

  // ลบไฟล์เสียงชั่วคราวทั้งหมด (เรียกหลังเสร็จกิจกรรม)
  Future<void> _cleanupAudioFiles() async {
    if (kIsWeb) {
      debugPrint('🌐 Web platform - no audio files to cleanup');
      return;
    }

    int deletedCount = 0;
    for (final filePath in _tempAudioFiles) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          deletedCount++;
          debugPrint('🗑️ Deleted temp audio: $filePath');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to delete $filePath: $e');
      }
    }
    _tempAudioFiles.clear();
    debugPrint('✅ Cleanup complete: $deletedCount file(s) deleted');
  }

  Future<void> _handleFinishQuest() async {
    if (_childId == null) return;

    // หยุดจับเวลา
    _activityStopwatch.stop();
    final timeSpentSeconds = _activityStopwatch.elapsed.inSeconds;
    debugPrint('⏱️ Activity completed in $timeSpentSeconds seconds');

    try {
      final result = await _activityService.finalizeQuest(
        childId: _childId!,
        activityId: widget.activity.id,
        segmentResults: _segmentResults,
        activityMaxScore: widget.activity.maxScore,
        timeSpent: timeSpentSeconds, // ส่งเวลาที่ใช้
      );

      // ลบไฟล์เสียงชั่วคราว (privacy-first: เก็บเฉพาะ scores + text)
      await _cleanupAudioFiles();

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.result,
        arguments: {
          'activityName': widget.activity.name,
          'totalScore': result['calculatedScore'] as int? ?? 0,
          'scoreEarned': result['scoreEarned'] as int? ?? 0,
          'timeSpend': timeSpentSeconds,
          'activityObject': widget.activity,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.itemintro_questError(e.toString()))),
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

    final titleStyle = GoogleFonts.luckiestGuy(
      color: sky,
      fontSize: 22,
      height: 1.05,
      letterSpacing: .3,
    );

    final hasVideo = _ytController != null && _youtubeVideoId.isNotEmpty;

    return _buildScaffold(
      context,
      titleStyle: titleStyle,
      videoWidget: hasVideo
          ? yp.YoutubePlayer(controller: _ytController!)
          : Center(
              child: Text(
                AppLocalizations.of(context)!.itemintro_Videonotavailable,
                style: GoogleFonts.luckiestGuy(color: Colors.white),
              ),
            ),
    );
  }

  // แยก Scaffold ออกมาให้เรียกใช้ได้ทั้งกรณีมี/ไม่มี YouTube player
  Widget _buildScaffold(
    BuildContext context, {
    required TextStyle titleStyle,
    required Widget videoWidget,
  }) {
    // ✅ Calculate current values inside this method so they're always fresh
    final currentSegmentResult = _currentSegmentResult;
    final currentText = _getCurrentSegmentText();

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                          AppLocalizations.of(context)!.itemintro_segmentOf(current, totalSegments),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
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
                  ],
                ),
              ),
            ),
            // Sticky bottom navigation
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: cream,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _bottomBtn(
                      label: AppLocalizations.of(context)!.itemintro_previous,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$completedSegmentsCount/$totalSegments',
                          style: GoogleFonts.luckiestGuy(fontSize: 14),
                        ),
                        Text(
                          AppLocalizations.of(context)!.common_done,
                          style: TextStyle(
                            fontSize: 10,
                            color: deepGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bottomBtn(
                      label: current == totalSegments ? AppLocalizations.of(context)!.itemintro_finish : AppLocalizations.of(context)!.itemintro_next,
                      bg: nextBlue,
                      fg: Colors.white,
                      onTap: () {
                        if (current < totalSegments) {
                          setState(() {
                            current++;
                            final newSegmentResult =
                                _segmentResults[current - 1];
                            state = newSegmentResult.maxScore > 0
                                ? 'reviewed'
                                : 'idle';
                          });
                          debugPrint(
                              '➡️ Moved to segment $current/${totalSegments}');
                        } else {
                          _handleFinishQuest();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _recordButton({required bool isReviewed}) {
    final Color bg = _isRecording
        ? const Color(0xFFE53935)
        : greenPill;

    return Expanded(
      child: InkWell(
        onTap: _handleRecord,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                const Icon(Icons.mic, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${_recordingDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordingDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.luckiestGuy(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ] else
                Text(
                  AppLocalizations.of(context)!.itemintro_record,
                  style: GoogleFonts.luckiestGuy(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
            ],
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
            '${AppLocalizations.of(context)!.itemintro_speak}: ${text.toUpperCase()}',
            style: GoogleFonts.luckiestGuy(fontSize: 15, color: deepGrey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _pillButton(
                AppLocalizations.of(context)!.itemintro_playsection,
                bluePill,
                onTap: _isPlayerReady && _rawSegments.isNotEmpty
                    ? _playSection
                    : null,
              ),
              const SizedBox(width: 10),
              _recordButton(isReviewed: isReviewed),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppLocalizations.of(context)!.itemintro_point}: ${score ?? 0}%',
                style: GoogleFonts.luckiestGuy(
                  fontSize: 13,
                  color: deepGrey,
                ),
              ),
              Text(
                '${AppLocalizations.of(context)!.itemintro_completed}: $completedSegmentsCount/$totalSegments',
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
    final String recognizedTextDisplay = result.recognizedText?.trim() ?? "N/A";

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
                            ? AppLocalizations.of(context)!.itemintro_pausePlayback
                            : AppLocalizations.of(context)!.itemintro_listenRecording,
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
                      AppLocalizations.of(context)!.itemintro_recordToPlayback,
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
