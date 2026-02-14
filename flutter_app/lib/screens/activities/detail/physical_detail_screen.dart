// lib/screens/activities/detail/physical_detail_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/activity.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/activity_service.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/palette.dart';
import '../../../l10n/app_localizations.dart';

class PhysicalDetailScreen extends StatefulWidget {
  final Activity activity;
  const PhysicalDetailScreen({super.key, required this.activity});

  @override
  State<PhysicalDetailScreen> createState() => _PhysicalDetailScreenState();
}

class _PhysicalDetailScreenState extends State<PhysicalDetailScreen> {
  // ----------------------------------------------------
  // 1. STATE & SERVICES
  // ----------------------------------------------------

  final ActivityService _activityService = ActivityService();

  String? _videoPath;
  String? _imagePath;

  // ⏱️ เปลี่ยนจาก Timer เป็น Stopwatch (แม่นยำกว่า)
  final Stopwatch _activityStopwatch = Stopwatch();
  Timer? _uiUpdateTimer; // Timer สำหรับอัพเดท UI เท่านั้น
  bool _isPlaying = false;

  int _parentScore = 0;
  bool _isSubmitting = false;
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController(); // 🆕 Controller สำหรับ Diary

  @override
  void initState() {
    super.initState();
    debugPrint('⏱️ Physical Activity initialized');
  }

  @override
  void dispose() {
    _activityStopwatch.stop();
    _uiUpdateTimer?.cancel();
    _scoreController.dispose();
    _descriptionController.dispose(); // 🆕 Dispose controller
    super.dispose();
  }

  // ----------------------------------------------------
  // 2. LOGIC HANDLERS
  // ----------------------------------------------------

  void _handleStart() {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
    });

    // เริ่ม Stopwatch
    _activityStopwatch.reset();
    _activityStopwatch.start();

    // เริ่ม Timer เพื่ออัพเดท UI ทุกวินาที
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isPlaying) {
        setState(() {}); // บังคับให้ rebuild เพื่ออัพเดทเวลา
      }
    });

    debugPrint('⏱️ Stopwatch started');
  }

  void _handleFinish() {
    _activityStopwatch.stop();
    _uiUpdateTimer?.cancel();

    setState(() {
      _isPlaying = false;
    });

    debugPrint(
        '⏱️ Stopwatch stopped at ${_activityStopwatch.elapsed.inSeconds}s');
  }

  // 🆕 Logic: เลือก Video/Image จาก Camera หรือ Gallery
  Future<void> _handleMediaSelection(
      {required bool isVideo, ImageSource? source}) async {
    try {
      // ถ้าไม่ระบุ source ให้เลือก
      ImageSource selectedSource = source ?? await _showSourceDialog();

      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (isVideo) {
        // เลือก/ถ่าย Video
        pickedFile = await picker.pickVideo(source: selectedSource);
      } else {
        // เลือก/ถ่าย Image
        pickedFile = await picker.pickImage(source: selectedSource);
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
        debugPrint('📸 ${isVideo ? 'Video' : 'Image'} selected: $path');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.calculate_failedPickFile(e.toString()))));
      }
    }
  }

  // 🆕 Dialog เลือก Camera หรือ Gallery
  Future<ImageSource> _showSourceDialog() async {
    return await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.common_selectSource, style: AppTextStyles.heading(18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Palette.success),
                  title: Text(AppLocalizations.of(context)!.common_camera, style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.common_gallery, style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ) ??
        ImageSource.gallery; // default
  }

  // 🆕 Logic: การส่งหลักฐานและคะแนน
  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;

    final bool isEvidenceAttached = _videoPath != null || _imagePath != null;

    if (!isEvidenceAttached) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.physical_snackNoEvidence)));
      }
      return;
    }
    if (_parentScore <= 0 || _parentScore > widget.activity.maxScore) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.physical_snackInvalidScore(widget.activity.maxScore))));
      }
      return;
    }

    // หยุดจับเวลา
    _handleFinish();
    final timeSpentSeconds = _activityStopwatch.elapsed.inSeconds;
    debugPrint('⏱️ Physical activity completed in $timeSpentSeconds seconds');

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
      debugPrint(
          '📊 Sending parentScore: $_parentScore, timeSpent: $timeSpentSeconds');
      debugPrint('📦 Evidence payload: $evidencePayload');

      // ignore: unused_local_variable
      final response = await _activityService.finalizeQuest(
        childId: childId!,
        activityId: widget.activity.id,
        segmentResults: [],
        activityMaxScore: widget.activity.maxScore,
        evidence: evidencePayload,
        parentScore: _parentScore, // ✅ ส่ง parentScore แยกต่างหาก
        timeSpent: timeSpentSeconds, // ⏱️ ส่งเวลาที่ใช้
      );

      // print('✅ Submit Response: $response');

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: {
            'activityName': widget.activity.name,
            'totalScore': ((_parentScore / widget.activity.maxScore) * 100).round(),
            'scoreEarned': _parentScore,
            'timeSpend': timeSpentSeconds,
            'activityObject': widget.activity,
            'evidenceImagePath': _imagePath,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.physical_snackSubmitError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          child: Icon(icon, size: 50, color: Palette.sky));
    }
    // ignore: deprecated_member_use
    return Icon(Icons.add, size: 50, color: Palette.deepGrey.withOpacity(0.5));
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
                  style: AppTextStyles.heading(24, color: Palette.deepGrey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Palette.success),
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
        title: Text(AppLocalizations.of(context)!.physical_dialogEnterScoreTitle, style: AppTextStyles.heading(18)),
        content: TextField(
          controller: _scoreController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.physical_dialogEnterScoreHint(widget.activity.maxScore),
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
                Text(AppLocalizations.of(context)!.common_cancel, style: AppTextStyles.body(14, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _updateScoreFromInput(_scoreController.text);
              Navigator.pop(context);
            },
            child:
                Text(AppLocalizations.of(context)!.common_ok, style: AppTextStyles.heading(16, color: Palette.success)),
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
                AppLocalizations.of(context)!.physical_snackInvalidInput(widget.activity.maxScore))),
      );
    }
  }

  // ----------------------------------------------------
  // 3. BUILD METHOD (UI)
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // แสดงเวลาจาก Stopwatch
    String two(int n) => n.toString().padLeft(2, '0');
    final int elapsedSeconds = _activityStopwatch.elapsed.inSeconds;
    final mm = two(elapsedSeconds ~/ 60), ss = two(elapsedSeconds % 60);
    final bool isEvidenceAttached = _videoPath != null || _imagePath != null;

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Palette.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.activity.name.toUpperCase(),
            style: AppTextStyles.heading(20, color: Palette.deepGrey)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TIME DISPLAY (ย้ายมาไว้บนสุด)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$mm:$ss',
                  style: AppTextStyles.heading(28, color: Palette.sky),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. START/STOP BUTTON
            Center(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : (_isPlaying ? _handleFinish : _handleStart),
                icon: Icon(
                  _isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  _isPlaying ? AppLocalizations.of(context)!.physical_stopBtn : AppLocalizations.of(context)!.physical_startBtn,
                  style: AppTextStyles.heading(20, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPlaying ? Palette.pink : Palette.success,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. SCORE CONTROL
            Text(AppLocalizations.of(context)!.physical_medalsScoreLabel,
                style:
                    AppTextStyles.heading(18, color: Palette.pink)),
            _buildScoreControl(),

            const SizedBox(height: 20),

            // 4. DIARY (Notes)
            Text(AppLocalizations.of(context)!.physical_diaryLabel,
                style:
                    AppTextStyles.heading(18, color: Palette.pink)),
            Container(
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                controller: _descriptionController, // 🆕 ผูก Controller
                decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.physical_diaryHint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(10)),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 20),

            // Image
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.common_image,
                        style: AppTextStyles.heading(18, color: Colors.black54),
                      ),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: () => _handleMediaSelection(isVideo: false),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _imagePath != null
                                  ? Palette.success
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: _imagePath != null && !kIsWeb
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: Image.file(
                                          File(_imagePath!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                          onPressed: () =>
                                              setState(() => _imagePath = null),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate,
                                        size: 40, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)!.common_addImage,
                                      style: AppTextStyles.body(12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Video
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.common_video,
                        style: AppTextStyles.heading(18, color: Colors.black54),
                      ),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: () => _handleMediaSelection(isVideo: true),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _videoPath != null
                                  ? Palette.success
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: _videoPath != null
                              ? Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.videocam,
                                              size: 50, color: Palette.success),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppLocalizations.of(context)!.common_videoAdded,
                                            style: AppTextStyles.label(12, color: Palette.success),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white, size: 16),
                                          onPressed: () =>
                                              setState(() => _videoPath = null),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 28,
                                            minHeight: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_circle_outline,
                                        size: 40, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)!.common_addVideo,
                                      style: AppTextStyles.body(12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 7. FINISH BUTTON (Submit)
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed:
                    isEvidenceAttached && !_isSubmitting ? _handleSubmit : null,
                style: ElevatedButton.styleFrom(backgroundColor: Palette.success),
                child: Text(_isSubmitting ? AppLocalizations.of(context)!.common_submitting : AppLocalizations.of(context)!.common_finish,
                    style: AppTextStyles.heading(24, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
