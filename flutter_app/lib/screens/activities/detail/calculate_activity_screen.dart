// lib/screens/activities/detail/calculate_activity_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final Map<int, String?> _userAnswers = {};
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
    _activityStopwatch.stop();
    _uiUpdateTimer?.cancel();
    setState(() => _phase = _Phase.answering);
  }

  void _resetTimer() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('เริ่มใหม่?', style: AppTextStyles.heading(18)),
        content: Text('เวลาและคำตอบจะถูกรีเซ็ต',
            style: AppTextStyles.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: AppTextStyles.body(14)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _activityStopwatch.stop();
              _uiUpdateTimer?.cancel();
              _activityStopwatch.reset();
              setState(() {
                _phase = _Phase.ready;
                _userAnswers.clear();
                _answerStatus.clear();
                for (int i = 0; i < _segmentResults.length; i++) {
                  _segmentResults[i].maxScore = 0;
                }
              });
            },
            child: Text('เริ่มใหม่',
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
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<ImageSource> _showSourceDialog() async {
    return await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Select Source', style: AppTextStyles.heading(18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Palette.success),
                  title: Text('Camera', style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Palette.lightBlue),
                  title: Text('Gallery', style: AppTextStyles.body(14)),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ) ??
        ImageSource.gallery;
  }

  // ── Answers ────────────────────────────────────────────

  List<int> _extractNumbers(String text) {
    final matches = RegExp(r'\d+').allMatches(text);
    return matches.map((m) => int.parse(m.group(0)!)).toList();
  }

  void _showAnswerDialog(int index) {
    final segment = _segments[index];
    final solutionAnswer = segment['answer']?.toString() ?? '';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Palette.cream,
        title: Row(
          children: [
            Icon(Icons.edit_note, color: Palette.sky, size: 28),
            const SizedBox(width: 10),
            Text('Answer #${index + 1}',
                style: AppTextStyles.heading(20, color: Palette.sky)),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            hintStyle: AppTextStyles.body(14, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Palette.sky),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Palette.sky, width: 2),
            ),
          ),
          style: AppTextStyles.body(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: AppTextStyles.heading(14, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final userInput = controller.text.trim();
              if (userInput.isEmpty) return;
              Navigator.pop(ctx);

              final userNumbers = _extractNumbers(userInput);
              final solutionNumbers = _extractNumbers(solutionAnswer);

              final isCorrect = userNumbers.isNotEmpty &&
                  solutionNumbers.isNotEmpty &&
                  userNumbers.join(',') == solutionNumbers.join(',');

              setState(() {
                _userAnswers[index] = userInput;
                _answerStatus[index] = isCorrect;
                _segmentResults[index].maxScore =
                    isCorrect ? (_originalScores[index] ?? 100) : 0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.sky,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('SUBMIT',
                style: AppTextStyles.heading(14, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAnswerHint(int index) {
    final segment = _segments[index];
    final answer = segment['answer']?.toString() ?? 'ไม่มีเฉลย';
    final question = segment['question']?.toString() ??
        segment['text']?.toString() ??
        'คำถามข้อ ${index + 1}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Palette.cream,
        title: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Text('เฉลยข้อ ${index + 1}',
                style: GoogleFonts.itim(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Palette.sky)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คำถาม:',
                style: GoogleFonts.itim(
                    fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(question,
                style:
                    GoogleFonts.itim(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Palette.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Palette.success, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Palette.success, size: 20),
                      const SizedBox(width: 8),
                      Text('คำตอบ:',
                          style: GoogleFonts.itim(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Palette.success)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(answer,
                      style: GoogleFonts.itim(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('ปิด', style: GoogleFonts.itim(fontSize: 16, color: Palette.sky)),
          ),
        ],
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;

    if (childId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child ID not found. Please login again.')),
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
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing activity: $e')),
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
          widget.activity.name,
          style: GoogleFonts.luckiestGuy(
            fontSize: 24,
            color: Palette.sky,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: _segments.isEmpty
          ? Center(
              child: Text('No questions available',
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
                          Text('HOW TO PLAY',
                              style: AppTextStyles.heading(
                                  18, color: Palette.deepGrey)),
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
                              style: AppTextStyles.heading(
                                  24, color: Palette.sky),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Timer controls ──
                        _buildTimerControls(),
                        const SizedBox(height: 20),

                        // ── Questions (only visible in answering phase) ──
                        if (_phase == _Phase.answering) ...[
                          Text('QUESTIONS',
                              style: AppTextStyles.heading(
                                  24, color: Palette.sky)),
                          const SizedBox(height: 10),
                          ..._buildQuestionCards(),
                          const SizedBox(height: 30),

                          // Evidence
                          Text('EVIDENCE',
                              style: AppTextStyles.heading(
                                  20, color: Palette.error)),
                          const SizedBox(height: 15),
                          _buildEvidenceSection(),
                          const SizedBox(height: 20),
                        ],

                        // ── Ready phase message ──
                        if (_phase == _Phase.ready)
                          _buildReadyMessage(),

                        // ── Running phase message ──
                        if (_phase == _Phase.running)
                          _buildRunningMessage(),
                      ],
                    ),
                  ),
                ),
                // FINISH button (only in answering phase)
                if (_phase == _Phase.answering)
                  StickyBottomButton(
                    onPressed: _handleSubmit,
                    label: 'FINISH',
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
            label: Text('START',
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
              label: Text('RESTART',
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
              label: Text('FINISH',
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
          Text('กดปุ่ม START เพื่อเริ่มจับเวลา',
              style: AppTextStyles.body(16, color: Palette.sky),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('คำถามจะปรากฏหลังจากจบการจับเวลา',
              style: AppTextStyles.body(13, color: Palette.deepGrey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRunningMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Palette.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.timer, size: 48, color: Palette.warning),
          const SizedBox(height: 12),
          Text('กำลังจับเวลา...',
              style: AppTextStyles.heading(18, color: Palette.warning)),
          const SizedBox(height: 4),
          Text('กด FINISH เมื่อทำกิจกรรมเสร็จ เพื่อตอบคำถาม',
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
          'Question ${index + 1}';
      final status = _answerStatus[index];
      final userAnswer = _userAnswers[index];

      Color cardColor;
      Color borderColor;
      IconData statusIcon;
      Color statusIconColor;
      if (status == true) {
        cardColor = const Color(0xFFE8F5E9);
        borderColor = Palette.success;
        statusIcon = Icons.check_circle;
        statusIconColor = Palette.success;
      } else if (status == false) {
        cardColor = const Color(0xFFFFEBEE);
        borderColor = Colors.red.shade300;
        statusIcon = Icons.cancel;
        statusIconColor = Colors.red.shade400;
      } else {
        cardColor = Colors.white;
        borderColor = Palette.sky.withValues(alpha: 0.3);
        statusIcon = Icons.help_outline;
        statusIconColor = Colors.grey;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Palette.sky,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Question ${index + 1}',
                      style:
                          AppTextStyles.heading(16, color: Colors.white)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAnswerHint(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_outline,
                          color: Colors.amber, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(question,
                  style: AppTextStyles.body(15, color: Colors.black87)),
            ),
            if (userAnswer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: status == true
                        ? Palette.success.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusIconColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Your answer: $userAnswer',
                            style: AppTextStyles.label(13,
                                color: statusIconColor)),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAnswerDialog(index),
                  icon: Icon(
                      status == null ? Icons.edit : Icons.refresh,
                      size: 18),
                  label: Text(
                      status == null ? 'ANSWER' : 'ANSWER AGAIN',
                      style: AppTextStyles.heading(14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == null
                        ? Palette.sky
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
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
        Text('DIARY / NOTES',
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
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              hintText: 'Write your notes here...',
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
        Text('IMAGE', style: AppTextStyles.heading(18, color: Colors.black54)),
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
                          child: Image.file(File(_imagePath!),
                              fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                            onPressed: () =>
                                setState(() => _imagePath = null),
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
                      Text('Add Image',
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
        Text('VIDEO', style: AppTextStyles.heading(18, color: Colors.black54)),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam,
                                size: 50, color: Palette.success),
                            const SizedBox(height: 8),
                            Text('Video Added',
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
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                            onPressed: () =>
                                setState(() => _videoPath = null),
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
                      Text('Add Video',
                          style: AppTextStyles.body(12, color: Colors.grey)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
