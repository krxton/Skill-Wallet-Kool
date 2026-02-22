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
import '../../../utils/activity_l10n.dart';
import '../../../widgets/sticky_bottom_button.dart';

class PhysicalDetailScreen extends StatefulWidget {
  final Activity activity;
  final List<String> extraChildIds;
  const PhysicalDetailScreen({
    super.key,
    required this.activity,
    this.extraChildIds = const [],
  });

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

  final Map<String, int> _childScores = {};
  bool _isSubmitting = false;
  bool _initialized = false;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint('⏱️ Physical Activity initialized');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final childId = context.read<UserProvider>().currentChildId;
      if (childId != null) _childScores[childId] = 0;
      for (final id in widget.extraChildIds) {
        _childScores.putIfAbsent(id, () => 0);
      }
    }
  }

  @override
  void dispose() {
    _activityStopwatch.stop();
    _uiUpdateTimer?.cancel();
    _descriptionController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .calculate_failedPickFile(e.toString()))));
      }
    }
  }

  // 🆕 Dialog เลือก Camera หรือ Gallery
  Future<ImageSource> _showSourceDialog() async {
    return await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.common_selectSource,
                style: AppTextStyles.heading(18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Palette.success),
                  title: Text(AppLocalizations.of(context)!.common_camera,
                      style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: Text(AppLocalizations.of(context)!.common_gallery,
                      style: AppTextStyles.body(14)),
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
            content:
                Text(AppLocalizations.of(context)!.physical_snackNoEvidence)));
      }
      return;
    }
    final allChildIds = <String>{childId!, ...widget.extraChildIds}.toList();
    final bool allScoresValid = allChildIds.every((cid) {
      final s = _childScores[cid] ?? 0;
      return s > 0 && s <= widget.activity.maxScore;
    });
    if (!allScoresValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .physical_snackInvalidScore(widget.activity.maxScore))));
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
          '📊 Sending to ${allChildIds.length} children, timeSpent: $timeSpentSeconds');

      final results = await Future.wait(
        allChildIds.map((cid) => _activityService.finalizeQuest(
              childId: cid,
              activityId: widget.activity.id,
              segmentResults: [],
              activityMaxScore: widget.activity.maxScore,
              evidence: evidencePayload,
              parentScore: _childScores[cid] ?? 0,
              timeSpent: timeSpentSeconds,
            )),
        eagerError: false,
      );

      debugPrint('✅ Submitted for ${results.length} children');

      if (mounted) {
        final currentScore = _childScores[childId] ?? 0;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: {
            'activityName': widget.activity.name,
            'totalScore':
                ((currentScore / widget.activity.maxScore) * 100).round(),
            'scoreEarned': currentScore,
            'timeSpend': timeSpentSeconds,
            'activityObject': widget.activity,
            'evidenceImagePath': _imagePath,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!
                .physical_snackSubmitError(e.toString()))));
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
      return Center(child: Icon(icon, size: 50, color: Palette.sky));
    }
    // ignore: deprecated_member_use
    return Icon(Icons.add, size: 50, color: Palette.deepGrey.withOpacity(0.5));
  }

  // ── Score Section: แสดงคะแนนแยกต่อเด็กแต่ละคน ──
  Widget _buildScoreSection() {
    final userProvider = context.read<UserProvider>();
    final currentChildId = userProvider.currentChildId ?? '';
    final allIds = <String>{currentChildId, ...widget.extraChildIds}
        .where((id) => id.isNotEmpty)
        .toList();

    return Column(
      children: allIds.map((childId) {
        final name = _getChildName(userProvider.children, childId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildChildScoreRow(childId, name),
        );
      }).toList(),
    );
  }

  Widget _buildChildScoreRow(String childId, String childName) {
    final score = _childScores[childId] ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Palette.sky,
            child: Text(
              childName.isNotEmpty ? childName[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(childName, style: AppTextStyles.body(14))),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.red, size: 20),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () => setState(() {
              _childScores[childId] = (score > 0) ? score - 1 : 0;
            }),
          ),
          GestureDetector(
            onTap: () => _showChildScoreDialog(childId, childName),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '$score / ${widget.activity.maxScore}',
                style: AppTextStyles.heading(20, color: Palette.deepGrey),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Palette.success, size: 20),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () => setState(() {
              _childScores[childId] = (score < widget.activity.maxScore)
                  ? score + 1
                  : widget.activity.maxScore;
            }),
          ),
        ],
      ),
    );
  }

  void _showChildScoreDialog(String childId, String childName) {
    final tempController = TextEditingController(
      text: (_childScores[childId] ?? 0).toString(),
    );
    tempController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: tempController.text.length,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(childName, style: AppTextStyles.heading(16)),
        content: TextField(
          controller: tempController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!
                .physical_dialogEnterScoreHint(widget.activity.maxScore),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            _updateChildScore(childId, value);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel,
                style: AppTextStyles.body(14, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _updateChildScore(childId, tempController.text);
              Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.common_ok,
                style: AppTextStyles.heading(16, color: Palette.success)),
          ),
        ],
      ),
    ).then((_) => tempController.dispose());
  }

  void _updateChildScore(String childId, String value) {
    final score = int.tryParse(value);
    if (score != null && score >= 0 && score <= widget.activity.maxScore) {
      setState(() => _childScores[childId] = score);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .physical_snackInvalidInput(widget.activity.maxScore))));
    }
  }

  String _getChildName(List<Map<String, dynamic>> children, String childId) {
    for (final item in children) {
      final child = item['child'] as Map<String, dynamic>?;
      if (child != null && child['child_id']?.toString() == childId) {
        return child['name_surname']?.toString() ?? '?';
      }
    }
    return '?';
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
        title: Text(
            ActivityL10n.localizedActivityType(
                context, widget.activity.category),
            style: AppTextStyles.heading(20, color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TIME DISPLAY (ย้ายมาไว้บนสุด)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
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
                        _isPlaying
                            ? AppLocalizations.of(context)!.physical_stopBtn
                            : AppLocalizations.of(context)!.physical_startBtn,
                        style: AppTextStyles.heading(20, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isPlaying ? Palette.pink : Palette.success,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. SCORE CONTROL (per child)
                  Text(AppLocalizations.of(context)!.physical_medalsScoreLabel,
                      style: AppTextStyles.heading(18, color: Palette.pink)),
                  _buildScoreSection(),

                  const SizedBox(height: 20),

                  // 4. DIARY (Notes)
                  Text(AppLocalizations.of(context)!.physical_diaryLabel,
                      style: AppTextStyles.heading(18, color: Palette.pink)),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: _descriptionController, // 🆕 ผูก Controller
                      decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.physical_diaryHint,
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
                              style: AppTextStyles.heading(18,
                                  color: Colors.black54),
                            ),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: () =>
                                  _handleMediaSelection(isVideo: false),
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
                                            borderRadius:
                                                BorderRadius.circular(18),
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
                                                    color: Colors.white,
                                                    size: 16),
                                                onPressed: () => setState(
                                                    () => _imagePath = null),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 28,
                                                  minHeight: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_photo_alternate,
                                              size: 40, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .common_addImage,
                                            style: AppTextStyles.body(12,
                                                color: Colors.grey),
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
                              style: AppTextStyles.heading(18,
                                  color: Colors.black54),
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
                                                    size: 50,
                                                    color: Palette.success),
                                                const SizedBox(height: 8),
                                                Text(
                                                  AppLocalizations.of(context)!
                                                      .common_videoAdded,
                                                  style: AppTextStyles.label(12,
                                                      color: Palette.success),
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
                                                    color: Colors.white,
                                                    size: 16),
                                                onPressed: () => setState(
                                                    () => _videoPath = null),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 28,
                                                  minHeight: 28,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_circle_outline,
                                              size: 40, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          Text(
                                            AppLocalizations.of(context)!
                                                .common_addVideo,
                                            style: AppTextStyles.body(12,
                                                color: Colors.grey),
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
                ],
              ),
            ),
          ),
          // 7. FINISH BUTTON (sticky bottom)
          StickyBottomButton(
            onPressed:
                isEvidenceAttached && !_isSubmitting ? _handleSubmit : null,
            label: _isSubmitting
                ? AppLocalizations.of(context)!.common_submitting
                : AppLocalizations.of(context)!.common_finish,
            color: Palette.success,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }
}
