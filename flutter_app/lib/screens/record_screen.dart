// lib/screens/record_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // 👈 ใช้ kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/activity_service.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ActivityService _activityService = ActivityService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool recording = false;
  bool _isPlaying = false;
  bool _hasRecorded = false;

  Duration elapsed = Duration.zero;
  Timer? _t;
  String _tempFilePath = '';
  String _originalText = 'Loading...';

  // UI Colors
  static const cream = Color(0xFFFFF5CD);
  static const red = Colors.red;
  static const green = Color(0xFF77C58C);
  static const greyCard = Color(0xFFEDEFF3);

  @override
  void initState() {
    super.initState();
    _prepareRecording();

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  Future<void> _prepareRecording() async {
    // ❗ บน Web: ยังไม่รองรับการอัดเสียง (กัน path_provider พัง)
    if (kIsWeb) {
      setState(() {
        _originalText =
            'Error: Recording is not supported on Web.\nPlease use the mobile app to record audio.';
      });
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (hasPermission) {
      // 1) เตรียม path ไฟล์ชั่วคราว (เฉพาะ mobile/desktop)
      final tempDir = await getTemporaryDirectory();
      _tempFilePath =
          '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 2) ดึง originalText จาก arguments
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>? ??
            {};
        setState(() {
          _originalText =
              args['originalText'] as String? ?? 'Error: Text Missing';
        });
      });
    } else {
      setState(() => _originalText = 'Microphone permission denied.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied.')),
        );
      }
    }
  }

  // 🔴 / 🟢 Start / Stop recording
  Future<void> _toggle() async {
    // ถ้าเป็น error text / ไม่มีสิทธิ์ / web ไม่รองรับ → ไม่เริ่มอัด
    if (_originalText.startsWith('Error') ||
        _originalText.startsWith('Microphone')) {
      return;
    }

    if (recording) {
      // 🟥 STOP
      _t?.cancel();
      await _audioRecorder.stop();
      setState(() {
        recording = false;
        _hasRecorded = true;
      });
    } else {
      // 🟢 START
      if (kIsWeb) return; // ป้องกัน web เผลอหลุดมาได้

      if (_tempFilePath.isEmpty) return;

      try {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _tempFilePath, // ✅ mobile/desktop เท่านั้น
        );

        setState(() {
          recording = true;
          _hasRecorded = false;
          elapsed = Duration.zero;
        });

        _t = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => elapsed += const Duration(seconds: 1));
        });
      } catch (e) {
        debugPrint('Recording Start Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording failed.')),
          );
        }
        setState(() => recording = false);
      }
    }
  }

  // ▶️ Playback
  void _playRecording() async {
    if (!_hasRecorded || _tempFilePath.isEmpty || recording) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
      return;
    }

    try {
      await _audioPlayer.play(DeviceFileSource(_tempFilePath));
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('Playback Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play audio.')),
        );
      }
      setState(() => _isPlaying = false);
    }
  }

  // ✅ FINISH → ส่งไฟล์ให้ AI (เฉพาะ mobile/desktop)
  Future<void> _finish() async {
    if (kIsWeb) {
      // กัน user กดอะไรแปลก ๆ บน web
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Recording is not supported on Web. Please use mobile.')),
        );
      }
      return;
    }

    if (recording) {
      await _toggle();
    }

    final audioFile = File(_tempFilePath);
    if (!await audioFile.exists() || await audioFile.length() < 1000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No valid audio recorded.')),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('กำลังประมวลผล AI...'),
              SizedBox(height: 10),
              Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      );
    }

    try {
      final result = await _activityService.evaluateAudio(
        audioFile: audioFile,
        originalText: _originalText,
      );

      if (mounted) Navigator.pop(context); // ปิด dialog

      if (mounted) {
        Navigator.pop(context, {
          'score': result['score'] as int? ?? 0,
          'recognizedText': result['text'] as String? ?? 'Evaluation Error',
          'audioUrl': _tempFilePath,
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ปิด dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Error: ${e.toString()}')),
        );
        Navigator.pop(context, {
          'score': 0,
          'recognizedText': 'API Error',
          'audioUrl': '',
        });
      }
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(elapsed.inMinutes % 60);
    final ss = two(elapsed.inSeconds % 60);

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    // 🆕 บน web: บังคับให้ข้อความเป็น error ชัด ๆ เพื่อปิดปุ่ม Record
    final displayOriginalText = kIsWeb
        ? 'Error: Recording is not supported on Web.\nPlease use the mobile app to record audio.'
        : (args['originalText'] as String? ?? _originalText);

    final bool isReadyToPlay = _hasRecorded && !_isPlaying;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        leading: const BackButton(color: Colors.black87),
        elevation: 0,
        title: Text(
          'RECORD',
          style: GoogleFonts.luckiestGuy(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ข้อความที่ต้องพูด / หรือ error บน web
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: greyCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                displayOriginalText,
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              '$mm:$ss',
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎙 Record / Stop
                IconButton(
                  iconSize: 56,
                  color: recording ? red : Colors.black87,
                  onPressed: (displayOriginalText.startsWith('Error') ||
                          displayOriginalText.startsWith('Microphone'))
                      ? null
                      : _toggle,
                  icon: Icon(
                    recording
                        ? Icons.stop_circle_outlined
                        : Icons.mic_rounded,
                  ),
                ),
                const SizedBox(width: 24),
                // ▶ Playback (เฉพาะเมื่อมีไฟล์)
                IconButton(
                  iconSize: 56,
                  color:
                      isReadyToPlay || _isPlaying ? Colors.blue : Colors.grey,
                  onPressed:
                      isReadyToPlay || _isPlaying ? _playRecording : null,
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ✅ FINISH (ปิดบน web ด้วย เพราะ onPressed จะโชว์ snackBar)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: green),
                onPressed:
                    (recording || !_hasRecorded) ? null : _finish,
                child: Text(
                  'FINISH',
                  style:
                      GoogleFonts.luckiestGuy(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
