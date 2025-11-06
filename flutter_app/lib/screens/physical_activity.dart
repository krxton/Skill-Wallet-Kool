// lib/screens/physical_activity.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';

import '../models/activity.dart';
import '../providers/user_provider.dart';
import '../services/activity_service.dart';
import '../routes/app_routes.dart';

class Palette {
  static const cream = Color(0xFFFFF5CD);
  static const red = Color(0xFFEA5B6F);
  static const green = Color(0xFF66BB6A);
  static const greyCard = Color(0xFFEDEFF3);
  static const deepGrey = Color(0xFF5D5D5D);
  static const bluePill = Color(0xFF78BDF1);
}

// ⚠️ Note: SegmentResult class must be defined in activity_service.dart

class PhysicalActivityScreen extends StatefulWidget {
  final Activity activity;
  const PhysicalActivityScreen({super.key, required this.activity});

  @override
  State<PhysicalActivityScreen> createState() => _PhysicalActivityScreenState();
}

class _PhysicalActivityScreenState extends State<PhysicalActivityScreen> {
  // ----------------------------------------------------
  // 1. STATE & SERVICES
  // ----------------------------------------------------

  static const cream = Color(0xFFFFF5CD);
  static const deepGrey = Color(0xFF5D5D5D);
  static const startGreen = Color(0xFF66BB6A);
  static const finishPink = Color(0xFFEA5B6F);

  final ActivityService _activityService = ActivityService();

  String? _videoPath;
  String? _imagePath;

  bool _isPlaying = false;
  int _timeSpentSeconds = 0;
  Timer? _timer;

  int _parentScore = 0;
  bool _isSubmitting = false;
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController(); // 🆕 Controller สำหรับ Diary

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scoreController.dispose();
    _descriptionController.dispose(); // 🆕 Dispose controller
    super.dispose();
  }

  // ----------------------------------------------------
  // 2. LOGIC HANDLERS
  // ----------------------------------------------------

  void _handleStart() {
    if (_isPlaying) return;

    _timeSpentSeconds = 0;
    _isPlaying = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeSpentSeconds++;
        });
      }
    });
    setState(() {});
  }

  void _handleFinish() {
    _timer?.cancel();
    _isPlaying = false;
    setState(() {});
  }

  // 🆕 Logic: เลือก Video/Image และเก็บ Path อย่างอิสระ
  Future<void> _handleMediaSelection({required bool isVideo}) async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (isVideo) {
        // เลือก Video
        pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      } else {
        // เลือก Image
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      }

      if (pickedFile != null) {
        final String path = pickedFile.path;

        setState(() {
          if (isVideo) {
            _videoPath = path;
          } else {
            _imagePath = path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
      }
    }
  }

  // 🆕 Logic: การส่งหลักฐานและคะแนน
  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;

    final bool isEvidenceAttached = _videoPath != null || _imagePath != null;

    if (!isEvidenceAttached) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please attach video or image evidence.')));
      }
      return;
    }
    if (_parentScore <= 0 || _parentScore > widget.activity.maxScore) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Please set a valid score (1 to ${widget.activity.maxScore}).')));
      }
      return;
    }

    _handleFinish();
    setState(() => _isSubmitting = true);

    // 1. ดึงค่า description
    final String description = _descriptionController.text.trim();

    // 2. Payload สำหรับ ActivityRecord (ส่ง Local Path + Description แยก)
    final evidencePayload = {
      'videoPathLocal': _videoPath,
      'imagePathLocal': _imagePath,
      'status': 'Pending Approval',
      'description':
          description.isNotEmpty ? description : null, // ✅ ส่ง description
    };

    try {
      // 🆕 Debug: ดูว่าส่งอะไรไป
      // print('📊 Sending parentScore: $_parentScore');
      // print('📦 Evidence payload: $evidencePayload');

      // ignore: unused_local_variable
      final response = await _activityService.finalizeQuest(
        childId: childId!,
        activityId: widget.activity.id,
        segmentResults: [],
        activityMaxScore: widget.activity.maxScore,
        evidence: evidencePayload,
        parentScore: _parentScore, // ✅ ส่ง parentScore แยกต่างหาก
      );

      // print('✅ Submit Response: $response');

      if (mounted) {
        // 2. 🚀 แสดง Popup ว่าเสร็จแล้ว
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Submission Complete!',
                      style: GoogleFonts.luckiestGuy()),
                  content: Text(
                      'Your evidence has been submitted for approval.',
                      style: GoogleFonts.openSans()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.home,
                          (route) => route.isFirst), // 🆕 กลับไปหน้า Home
                      child: Text('OK',
                          style: GoogleFonts.luckiestGuy(color: Colors.blue)),
                    ),
                  ],
                ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isSubmitting = false);
      if (!mounted) {
        Navigator.pushNamedAndRemoveUntil(
            // ignore: use_build_context_synchronously
            context,
            AppRoutes.home,
            (route) => route.isFirst);
      }
    }
  }

  // 🆕 Helper: แสดงภาพตัวอย่างหลักฐาน
  Widget _buildEvidencePreview(
      {required String? path, required IconData icon}) {
    if (path != null && File(path).existsSync()) {
      if (path.toLowerCase().endsWith('.jpg') ||
          path.toLowerCase().endsWith('.png') ||
          path.toLowerCase().endsWith('.jpeg')) {
        return Image.file(File(path), fit: BoxFit.cover);
      }
      // สำหรับวิดีโอ (แสดงไอคอน)
      return Center(
          child: Icon(icon, size: 50, color: const Color(0xFF0D92F4)));
    }
    // ignore: deprecated_member_use
    return Icon(Icons.add, size: 50, color: deepGrey.withOpacity(0.5));
  }

  // 🆕 Helper: Build Score Control
  Widget _buildScoreControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.red),
            onPressed: () {
              setState(() {
                _parentScore = (_parentScore > 0) ? _parentScore - 1 : 0;
                _scoreController.text = _parentScore.toString();
              });
            },
          ),
          // 🆕 ทำให้กดแล้วกรอกตัวเลขได้
          Expanded(
            child: GestureDetector(
              onTap: () {
                _scoreController.text = _parentScore.toString();
                _showScoreInputDialog();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$_parentScore / ${widget.activity.maxScore}',
                  style: GoogleFonts.luckiestGuy(fontSize: 24, color: deepGrey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: startGreen),
            onPressed: () {
              setState(() {
                _parentScore = (_parentScore < widget.activity.maxScore)
                    ? _parentScore + 1
                    : widget.activity.maxScore;
                _scoreController.text = _parentScore.toString();
              });
            },
          ),
        ],
      ),
    );
  }

  // 🆕 Dialog สำหรับกรอกคะแนนโดยตรง
  void _showScoreInputDialog() {
    _scoreController.text = _parentScore.toString();
    _scoreController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _scoreController.text.length,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Score', style: GoogleFonts.luckiestGuy()),
        content: TextField(
          controller: _scoreController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter score (1-${widget.activity.maxScore})',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _updateScoreFromInput(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: GoogleFonts.openSans(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _updateScoreFromInput(_scoreController.text);
              Navigator.pop(context);
            },
            child:
                Text('OK', style: GoogleFonts.luckiestGuy(color: startGreen)),
          ),
        ],
      ),
    );
  }

  // 🆕 Helper: อัพเดทคะแนนจาก Input
  void _updateScoreFromInput(String value) {
    final int? newScore = int.tryParse(value);
    if (newScore != null &&
        newScore >= 0 &&
        newScore <= widget.activity.maxScore) {
      setState(() {
        _parentScore = newScore;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Please enter a valid score (0-${widget.activity.maxScore})')),
      );
    }
  }

  // ----------------------------------------------------
  // 3. BUILD METHOD (UI)
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final mm = two(_timeSpentSeconds ~/ 60), ss = two(_timeSpentSeconds % 60);
    final bool isEvidenceAttached = _videoPath != null || _imagePath != null;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.activity.name.toUpperCase(),
            style: GoogleFonts.luckiestGuy(color: deepGrey)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ปุ่ม START / ADD PHOTO
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : (_isPlaying ? _handleFinish : _handleStart),
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'STOP' : 'START',
                        style: GoogleFonts.luckiestGuy(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? finishPink : startGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ปุ่ม ADD PHOTO
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleMediaSelection(isVideo: false),
                    icon: const Icon(Icons.add_a_photo),
                    label: Text('TAKE PHOTO',
                        style: GoogleFonts.luckiestGuy(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      // ignore: deprecated_member_use
                      backgroundColor: deepGrey.withOpacity(0.1),
                      foregroundColor: deepGrey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. PLAYER / GAME RESULTS HEADER
            Center(
                child: Text('',
                    style: GoogleFonts.luckiestGuy(
                        fontSize: 32, color: deepGrey))),

            // 3. SCORE CONTROL
            Text('MEDALS / SCORE',
                style:
                    GoogleFonts.luckiestGuy(fontSize: 18, color: finishPink)),
            _buildScoreControl(),

            const SizedBox(height: 20),

            // 4. DIARY (Notes)
            Text('DIARY',
                style:
                    GoogleFonts.luckiestGuy(fontSize: 18, color: finishPink)),
            Container(
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: _descriptionController, // 🆕 ผูก Controller
                decoration: const InputDecoration(
                    hintText: 'Enter notes here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(10)),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 20),

            // 5. IMAGE EVIDENCE Preview
            Text('IMAGE EVIDENCE',
                style:
                    GoogleFonts.luckiestGuy(fontSize: 18, color: finishPink)),
            GestureDetector(
              onTap: _isSubmitting
                  ? null
                  : () => _handleMediaSelection(isVideo: false),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child:
                    _buildEvidencePreview(path: _imagePath, icon: Icons.image),
              ),
            ),
            const SizedBox(height: 20),

            // 6. VIDEO EVIDENCE Preview
            Text('VIDEO EVIDENCE',
                style:
                    GoogleFonts.luckiestGuy(fontSize: 18, color: finishPink)),
            GestureDetector(
              onTap: _isSubmitting
                  ? null
                  : () => _handleMediaSelection(isVideo: true),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: _buildEvidencePreview(
                    path: _videoPath, icon: Icons.videocam),
              ),
            ),
            const SizedBox(height: 20),

            // 7. TIME DISPLAY
            Text('TIME',
                style:
                    GoogleFonts.luckiestGuy(fontSize: 18, color: finishPink)),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text('$mm:$ss',
                    style: GoogleFonts.openSans(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D92F4))),
              ),
            ),
            const SizedBox(height: 40),

            // 8. FINISH BUTTON (Submit)
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed:
                    isEvidenceAttached && !_isSubmitting ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(backgroundColor: startGreen),
                child: Text(_isSubmitting ? 'Submitting...' : 'FINISH',
                    style: GoogleFonts.luckiestGuy(
                        fontSize: 24, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
