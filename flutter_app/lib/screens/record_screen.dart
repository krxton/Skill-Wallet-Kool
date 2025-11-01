// lib/screens/record_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // สำหรับ Path ชั่วคราว
import 'package:record/record.dart'; // สำหรับบันทึกเสียง
import 'package:google_fonts/google_fonts.dart';
import '../services/activity_service.dart'; // สำหรับประเมิน AI

// ⚠️ Note: สมมติว่า Palette Class ถูกกำหนดค่าสีไว้แล้ว

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ActivityService _activityService = ActivityService();

  bool recording = false;
  Duration elapsed = Duration.zero;
  Timer? _t;
  String _tempFilePath = ''; // Path ไฟล์เสียงที่บันทึก
  String _originalText = 'Loading...'; // ข้อความที่ต้องพูด

  @override
  void initState() {
    super.initState();
    _prepareRecording();
  }

  Future<void> _prepareRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (hasPermission) {
      // 1. กำหนด Path ไฟล์ชั่วคราว
      final tempDir = await getTemporaryDirectory();
      _tempFilePath =
          '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 2. ดึง Arguments (originalText)
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
            const SnackBar(content: Text('Microphone permission denied.')));
      }
    }
  }

  // 1. 🟢 แก้ Error: กำหนด Future<void> สำหรับ async function ที่ไม่คืนค่า
  Future<void> _toggle() async {
    if (_originalText.startsWith('Error') ||
        _originalText.startsWith('Microphone')) {
      return;
    }

    if (recording) {
      // 🟢 STOP RECORDING
      _t?.cancel();
      await _audioRecorder.stop();
      setState(() => recording = false);
    } else {
      // 🟢 START RECORDING
      if (_tempFilePath.isEmpty) return;

      try {
        // ใช้ RecordConfig และ AudioEncoder.aacLc
        await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: _tempFilePath);

        setState(() {
          recording = true;
          elapsed = Duration.zero;
        });
        _t = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => elapsed += const Duration(seconds: 1));
        });
      } catch (e) {
        debugPrint('Recording Start Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Recording failed.')));
        }
        setState(() => recording = false);
      }
    }
  }

  // 2. 🟢 เมธอด FINISH ที่เรียก AI
  Future<void> _finish() async {
    if (recording) {
      // ถ้ายังอัดอยู่ให้หยุดก่อน
      await _toggle();
    }

    final audioFile = File(_tempFilePath);
    if (!await audioFile.exists() || await audioFile.length() < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No valid audio recorded.')));
      return;
    }

    // แสดงสถานะกำลังประเมิน
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
              )));
    }

    try {
      // 3. 🟢 เรียก AI Evaluation API
      final result = await _activityService.evaluateAudio(
        audioFile: audioFile,
        originalText: _originalText,
      );

      // 4. ลบไฟล์ชั่วคราว
      await audioFile.delete();

      // 5. ปิด Loading Dialog
      if (mounted) Navigator.pop(context);

      // 6. ส่งผลลัพธ์กลับไปยัง ItemIntroScreen
      if (mounted) {
        Navigator.pop(context, {
          'score': result['score'] as int? ?? 0,
          'recognizedText': result['text'] as String? ?? 'Evaluation Error',
          'audioUrl': _tempFilePath, // ส่ง path ไฟล์เสียงกลับไปด้วย
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('AI Error: ${e.toString()}'),
        ));
        // ถ้าเกิด Error ให้ส่งคะแนน 0 กลับไป
        Navigator.pop(context,
            {'score': 0, 'recognizedText': 'API Error', 'audioUrl': ''});
      }
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(elapsed.inMinutes % 60), ss = two(elapsed.inSeconds % 60);

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    final displayOriginalText =
        args['originalText'] as String? ?? _originalText;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CD), // Palette.cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5CD),
        leading: const BackButton(color: Colors.black87),
        elevation: 0,
        title: Text('RECORD',
            style: GoogleFonts.luckiestGuy(color: Colors.black87)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // แสดงข้อความ Segment ที่ต้องพูด
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEFF3), // Palette.greyCard
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(displayOriginalText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 24),
            Text('$mm:$ss',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ปุ่ม Record/Stop
                IconButton(
                  iconSize: 56,
                  color: recording ? Colors.red : Colors.black87,
                  onPressed: (displayOriginalText.startsWith('Error') ||
                          displayOriginalText.startsWith('Microphone'))
                      ? null
                      : _toggle,
                  icon: Icon(recording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_rounded),
                ),
                const SizedBox(width: 24),
                // ปุ่ม Play (Placeholder)
                IconButton(
                  iconSize: 56,
                  onPressed: () {},
                  icon: const Icon(Icons.play_circle_outline),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF77C58C)), // Palette.green
                onPressed: (recording || elapsed == Duration.zero)
                    ? null
                    : _finish, // ห้ามกด FINISH ขณะอัด หรือถ้ายังไม่ได้อัดเลย
                child: Text('FINISH',
                    style: GoogleFonts.luckiestGuy(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
