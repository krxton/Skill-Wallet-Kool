// lib/screens/activities/detail/calculate_activity_screen.dart

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
import '../../../widgets/info_badges.dart';
import '../../../widgets/sticky_bottom_button.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';
import '../../../utils/activity_l10n.dart';

/// Activity phases
enum _Phase { ready, running, answering }

class CalculateActivityScreen extends StatefulWidget {
  static const String routeName = '/calculate_activity';

  final Activity activity;

  const CalculateActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  State<CalculateActivityScreen> createState() =>
      _CalculateActivityScreenState();
}

class _CalculateActivityScreenState extends State<CalculateActivityScreen> {
  final ActivityService _activityService = ActivityService();

  // Phase
  _Phase _phase = _Phase.ready;

  // Timer
  final Stopwatch _activityStopwatch = Stopwatch();
  Timer? _uiUpdateTimer;

  // Evidence
  String? _videoPath;
  String? _imagePath;
  final TextEditingController _descriptionController = TextEditingController();

  // Segment Results
  final List<SegmentResult> _segmentResults = [];
  List<dynamic> _segments = [];
  final Map<int, int> _originalScores = {};
  final Map<int, bool?> _answerStatus = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  @override
  void dispose() {
    _activityStopwatch.stop();
    _uiUpdateTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadSegments() {
    if (widget.activity.segments != null) {
      if (widget.activity.segments is List) {
        _segments = widget.activity.segments as List;
      } else {
        _segments = [];
      }
    }

    for (int i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      final int scoreFromSegment = segment['score'] as int? ??
          segment['maxScore'] as int? ??
          segment['point'] as int? ??
          100;

      _originalScores[i] = scoreFromSegment;

      _segmentResults.add(SegmentResult(
        id: segment['id']?.toString() ?? '',
        text: segment['question']?.toString() ??
            segment['text']?.toString() ??
            '',
        maxScore: 0,
      ));
    }
  }

  // ── Timer ──────────────────────────────────────────────

  void _startTimer() {
    setState(() => _phase = _Phase.running);
    _activityStopwatch.reset();
    _activityStopwatch.start();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _finishTimer() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.calculate_confirmFinishTitle,
            style: AppTextStyles.heading(18)),
        content: Text(AppLocalizations.of(context)!.calculate_confirmFinishMsg,
            style: AppTextStyles.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel,
                style: AppTextStyles.body(14)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _activityStopwatch.stop();
              _uiUpdateTimer?.cancel();
              setState(() => _phase = _Phase.answering);
            },
            child: Text(AppLocalizations.of(context)!.common_finish,
                style: AppTextStyles.body(14, color: Palette.pink)),
          ),
        ],
      ),
    );
  }

  void _resetTimer() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.calculate_restartTitle,
            style: AppTextStyles.heading(18)),
        content: Text(AppLocalizations.of(context)!.calculate_restartMsg,
            style: AppTextStyles.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.common_cancel,
                style: AppTextStyles.body(14)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _activityStopwatch.stop();
              _uiUpdateTimer?.cancel();
              _activityStopwatch.reset();
              setState(() {
                _phase = _Phase.ready;
                _answerStatus.clear();
                for (int i = 0; i < _segmentResults.length; i++) {
                  _segmentResults[i].maxScore = 0;
                }
              });
            },
            child: Text(AppLocalizations.of(context)!.calculate_restartBtn,
                style: AppTextStyles.body(14, color: Palette.pink)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ── Media ──────────────────────────────────────────────

  Future<void> _handleMediaSelection({required bool isVideo}) async {
    try {
      final ImageSource source = await _showSourceDialog();
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      if (isVideo) {
        pickedFile = await picker.pickVideo(source: source);
      } else {
        pickedFile = await picker.pickImage(source: source);
      }

      if (pickedFile != null) {
        setState(() {
          if (isVideo) {
            _videoPath = pickedFile!.path;
          } else {
            _imagePath = pickedFile!.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .calculate_failedPickFile(e.toString()))),
        );
      }
    }
  }

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
                  leading: Icon(Icons.photo_library, color: Palette.lightBlue),
                  title: Text(AppLocalizations.of(context)!.common_gallery,
                      style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ) ??
        ImageSource.gallery;
  }

  // ── Submit ─────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;

    if (childId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.calculate_childIdNotFound)),
        );
      }
      return;
    }

    final timeSpentSeconds = _activityStopwatch.elapsed.inSeconds;
    setState(() => _isSubmitting = true);

    final evidencePayload = {
      'videoPathLocal': _videoPath,
      'imagePathLocal': _imagePath,
      'status': 'Pending Approval',
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    };

    try {
      final response = await _activityService.finalizeQuest(
        childId: childId,
        activityId: widget.activity.id,
        segmentResults: _segmentResults,
        activityMaxScore: widget.activity.maxScore,
        evidence: evidencePayload,
        timeSpent: timeSpentSeconds,
        useDirectScore: true,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.result,
          arguments: {
            'activityName': widget.activity.name,
            'totalScore': response['calculatedScore'] as int? ?? 0,
            'scoreEarned': response['scoreEarned'] as int? ?? 0,
            'timeSpend': timeSpentSeconds,
            'activityObject': widget.activity,
            'evidenceImagePath': _imagePath,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .calculate_errorCompleting(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final elapsedSeconds = _activityStopwatch.elapsed.inSeconds;

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          ActivityL10n.localizedActivityType(context, widget.activity.category),
          style: AppTextStyles.heading(24, color: Colors.black),
        ),
      ),
      body: _segments.isEmpty
          ? Center(
              child: Text(AppLocalizations.of(context)!.calculate_noQuestions,
                  style: AppTextStyles.heading(20, color: Colors.grey)),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoBadges(activity: widget.activity),
                        const SizedBox(height: 16),

                        // ── Content / Instructions ──
                        if (widget.activity.content.isNotEmpty) ...[
                          Text(
                              AppLocalizations.of(context)!
                                  .calculate_descriptionLabel,
                              style: AppTextStyles.heading(18,
                                  color: Palette.deepGrey)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(widget.activity.content,
                                style: AppTextStyles.body(14)),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Timer ──
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _formatTime(elapsedSeconds),
                              style:
                                  AppTextStyles.heading(24, color: Palette.sky),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Timer controls ──
                        _buildTimerControls(),
                        const SizedBox(height: 20),

                        // ── Questions (visible during running & answering) ──
                        if (_phase == _Phase.running ||
                            _phase == _Phase.answering) ...[
                          Text(AppLocalizations.of(context)!.common_questions,
                              style: AppTextStyles.heading(24,
                                  color: Palette.sky)),
                          const SizedBox(height: 10),
                          ..._buildQuestionCards(),
                          const SizedBox(height: 30),
                        ],

                        // ── Evidence (only in answering phase) ──
                        if (_phase == _Phase.answering) ...[
                          Text(AppLocalizations.of(context)!.common_evidence,
                              style: AppTextStyles.heading(20,
                                  color: Palette.error)),
                          const SizedBox(height: 15),
                          _buildEvidenceSection(),
                          const SizedBox(height: 20),
                        ],

                        // ── Ready phase message ──
                        if (_phase == _Phase.ready) _buildReadyMessage(),
                      ],
                    ),
                  ),
                ),
                // FINISH button (only in answering phase)
                if (_phase == _Phase.answering)
                  StickyBottomButton(
                    onPressed: _handleSubmit,
                    label: AppLocalizations.of(context)!.common_finish,
                    color: Palette.success,
                    isLoading: _isSubmitting,
                  ),
              ],
            ),
    );
  }

  // ── Timer controls by phase ───────────────────────────

  Widget _buildTimerControls() {
    switch (_phase) {
      case _Phase.ready:
        return Center(
          child: ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(AppLocalizations.of(context)!.common_start,
                style: AppTextStyles.heading(20, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.success,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        );

      case _Phase.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _resetTimer,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.common_restart,
                  style: AppTextStyles.heading(16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.warning,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _finishTimer,
              icon: const Icon(Icons.stop, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.common_finish,
                  style: AppTextStyles.heading(16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.pink,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        );

      case _Phase.answering:
        return const SizedBox.shrink();
    }
  }

  // ── Phase messages ────────────────────────────────────

  Widget _buildReadyMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Palette.sky.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.sky.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.play_circle_outline, size: 48, color: Palette.sky),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.calculate_pressStart,
              style: AppTextStyles.body(16, color: Palette.sky),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.calculate_questionsAfterTimer,
              style: AppTextStyles.body(13, color: Palette.deepGrey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Question cards ────────────────────────────────────

  List<Widget> _buildQuestionCards() {
    return List.generate(_segments.length, (index) {
      final segment = _segments[index];
      final question = segment['question']?.toString() ??
          segment['text']?.toString() ??
          AppLocalizations.of(context)!.calculate_solutionTitle(index + 1);
      final answer = segment['answer']?.toString() ?? '';
      final solution = segment['solution']?.toString() ?? '';
      final status = _answerStatus[index];

      Color cardColor;
      Color borderColor;
      IconData statusIcon;
      if (status == true) {
        cardColor = const Color(0xFFE8F5E9);
        borderColor = Palette.success;
        statusIcon = Icons.check_circle;
      } else if (status == false) {
        cardColor = const Color(0xFFFFEBEE);
        borderColor = Colors.red.shade300;
        statusIcon = Icons.cancel;
      } else {
        cardColor = Colors.white;
        borderColor = Palette.sky.withValues(alpha: 0.3);
        statusIcon = Icons.help_outline;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with question number + status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: status == true
                    ? Palette.success
                    : status == false
                        ? Colors.red.shade400
                        : Palette.sky,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        AppLocalizations.of(context)!
                            .calculate_solutionTitle(index + 1),
                        style: AppTextStyles.heading(16, color: Colors.white)),
                  ),
                ],
              ),
            ),

            // Question text — larger, prominent
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              decoration: BoxDecoration(
                color: Palette.sky.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Palette.sky.withValues(alpha: 0.15)),
              ),
              child: Text(question,
                  style: AppTextStyles.body(17, color: Colors.black87)),
            ),

            // Answering phase: show answer + solution + correct/incorrect buttons
            if (_phase == _Phase.answering) ...[
              // Answer box
              if (answer.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Palette.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Palette.success.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Palette.success, size: 18),
                            const SizedBox(width: 6),
                            Text(
                                AppLocalizations.of(context)!
                                    .calculate_answerLabel,
                                style: AppTextStyles.label(13,
                                    color: Palette.success)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(answer,
                            style: AppTextStyles.body(15,
                                weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

              // Solution box
              if (solution.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Palette.sky.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text(
                                AppLocalizations.of(context)!
                                    .calculate_solutionLabel,
                                style: AppTextStyles.label(13,
                                    color: Palette.sky)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(solution, style: AppTextStyles.body(14)),
                      ],
                    ),
                  ),
                ),

              // Correct / Incorrect toggle buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _answerStatus[index] = true;
                            _segmentResults[index].maxScore =
                                _originalScores[index] ?? 100;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color:
                                status == true ? Palette.success : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Palette.success,
                              width: status == true ? 2.5 : 1.5,
                            ),
                            boxShadow: status == true
                                ? [
                                    BoxShadow(
                                      color: Palette.success
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 22,
                                  color: status == true
                                      ? Colors.white
                                      : Palette.success),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.calculate_correct,
                                style: AppTextStyles.heading(15,
                                    color: status == true
                                        ? Colors.white
                                        : Palette.success),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _answerStatus[index] = false;
                            _segmentResults[index].maxScore = 0;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: status == false
                                ? Colors.red.shade400
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.red.shade400,
                              width: status == false ? 2.5 : 1.5,
                            ),
                            boxShadow: status == false
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel_rounded,
                                  size: 22,
                                  color: status == false
                                      ? Colors.white
                                      : Colors.red.shade400),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!
                                    .calculate_incorrect,
                                style: AppTextStyles.heading(15,
                                    color: status == false
                                        ? Colors.white
                                        : Colors.red.shade400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    });
  }

  // ── Evidence section ──────────────────────────────────

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.calculate_diaryNotes,
            style: AppTextStyles.heading(18, color: Colors.black54)),
        const SizedBox(height: 5),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              hintText: AppLocalizations.of(context)!.calculate_writeNotes,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildImagePicker()),
            const SizedBox(width: 10),
            Expanded(child: _buildVideoPicker()),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.common_image,
            style: AppTextStyles.heading(18, color: Colors.black54)),
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
                color:
                    _imagePath != null ? Palette.success : Colors.grey.shade300,
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
                          child:
                              Image.file(File(_imagePath!), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                            onPressed: () => setState(() => _imagePath = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
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
                      Text(AppLocalizations.of(context)!.common_addImage,
                          style: AppTextStyles.body(12, color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.common_video,
            style: AppTextStyles.heading(18, color: Colors.black54)),
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
                color:
                    _videoPath != null ? Palette.success : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: _videoPath != null
                ? Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam,
                                size: 50, color: Palette.success),
                            const SizedBox(height: 8),
                            Text(
                                AppLocalizations.of(context)!.common_videoAdded,
                                style: AppTextStyles.label(12,
                                    color: Palette.success)),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                            onPressed: () => setState(() => _videoPath = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
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
                      Text(AppLocalizations.of(context)!.common_addVideo,
                          style: AppTextStyles.body(12, color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
