// lib/screens/record_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
  // Web-only recording buffer
  BytesBuilder? _webBytesBuilder;
  StreamSubscription<List<int>>? _webAudioSub;
  Uint8List? _webAudioBytes; // stores WAV bytes after conversion

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
    // Web no path provider usage. We will stream bytes in-memory.
    if (kIsWeb) {
      // Initialize original text from arguments post-frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
        setState(() {
          _originalText = args['originalText'] as String? ?? 'Error: Text Missing';
        });
      });
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
      if (kIsWeb) {
        // Finalize bytes buffer
        await _webAudioSub?.cancel();
        _webAudioSub = null;
        final pcm = _webBytesBuilder?.toBytes();
        // Convert raw PCM16 to WAV container (mono, 44.1kHz)
        if (pcm != null && pcm.isNotEmpty) {
          _webAudioBytes = _pcm16ToWav(pcm, sampleRate: 44100, channels: 1);
        } else {
          _webAudioBytes = null;
        }
        _webBytesBuilder = null;
      }
      setState(() {
        recording = false;
        _hasRecorded = true;
      });
    } else {
      // 🟢 START
      try {
        if (kIsWeb) {
          try {
            // Start streaming PCM/AAC bytes depending on browser support
            _webBytesBuilder = BytesBuilder(copy: false);
            final stream = await _audioRecorder.startStream(
              const RecordConfig(encoder: AudioEncoder.pcm16bits),
            );
            _webAudioSub = stream.listen((chunk) {
              _webBytesBuilder?.add(chunk);
            });
          } catch (e) {
            debugPrint('Web startStream not supported: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recording stream not supported in this browser.')),
              );
            }
            setState(() {
              recording = false;
              _hasRecorded = false;
            });
            return;
          }
        } else {
          if (_tempFilePath.isEmpty) return;
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: _tempFilePath, // ✅ mobile/desktop เท่านั้น
          );
        }

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
    if (!_hasRecorded || recording) return;
    if (!kIsWeb && _tempFilePath.isEmpty) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
      return;
    }

    try {
      if (kIsWeb) {
        if (_webAudioBytes == null || _webAudioBytes!.isEmpty) return;
        await _audioPlayer.play(BytesSource(_webAudioBytes!));
      } else {
        await _audioPlayer.play(DeviceFileSource(_tempFilePath));
      }
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
    // Stop recording if active

    if (recording) {
      await _toggle();
    }

    if (kIsWeb) {
      // Validate web bytes
      if (_webAudioBytes == null || _webAudioBytes!.lengthInBytes < 1000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No valid audio recorded.')),
          );
        }
        return;
      }
    } else {
      final audioFile = File(_tempFilePath);
      if (!await audioFile.exists() || await audioFile.length() < 1000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No valid audio recorded.')),
          );
        }
        return;
      }
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
      if (kIsWeb) {
        // Evaluate using bytes on web
        final result = await _activityService.evaluateAudioBytes(
          audioBytes: _webAudioBytes!,
          originalText: _originalText,
          filename: 'recording.wav',
        );

        if (mounted) Navigator.pop(context);
        if (mounted) {
          Navigator.pop(context, {
            'score': result['score'] as int? ?? 0,
            'recognizedText': result['text'] as String? ?? 'Evaluation Error',
            'audioUrl': '',
          });
        }
      } else {
        final audioFile = File(_tempFilePath);
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

  // Build simple WAV (RIFF) header for PCM16 LE
  Uint8List _pcm16ToWav(Uint8List pcmData, {required int sampleRate, required int channels}) {
    final int byteRate = sampleRate * channels * 2; // 16-bit
    final int blockAlign = channels * 2;
    final int subchunk2Size = pcmData.lengthInBytes;
    final int chunkSize = 36 + subchunk2Size;

    final bytes = BytesBuilder();
    // RIFF header
    bytes.add(_ascii('RIFF'));
    bytes.add(_le32(chunkSize));
    bytes.add(_ascii('WAVE'));
    // fmt chunk
    bytes.add(_ascii('fmt '));
    bytes.add(_le32(16)); // PCM
    bytes.add(_le16(1)); // audio format PCM
    bytes.add(_le16(channels));
    bytes.add(_le32(sampleRate));
    bytes.add(_le32(byteRate));
    bytes.add(_le16(blockAlign));
    bytes.add(_le16(16)); // bits per sample
    // data chunk
    bytes.add(_ascii('data'));
    bytes.add(_le32(subchunk2Size));
    bytes.add(pcmData);

    return bytes.toBytes();
  }

  Uint8List _ascii(String s) => Uint8List.fromList(s.codeUnits);
  Uint8List _le16(int value) => Uint8List.fromList([value & 0xFF, (value >> 8) & 0xFF]);
  Uint8List _le32(int value) => Uint8List.fromList([
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ]);

  @override
  void dispose() {
    _t?.cancel();
    _webAudioSub?.cancel();
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

    // On web, show provided original text (recording supported via stream)
    final displayOriginalText = args['originalText'] as String? ?? _originalText;

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
