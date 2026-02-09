// lib/screens/activities/detail/analysis_activity_screen.dart

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

class AnalysisActivityScreen extends StatefulWidget {
  static const String routeName = '/analysis_activity';

  final Activity activity;

  const AnalysisActivityScreen({
    super.key,
    required this.activity,
  });

  @override
  State<AnalysisActivityScreen> createState() => _AnalysisActivityScreenState();
}

class _AnalysisActivityScreenState extends State<AnalysisActivityScreen> {
  final ActivityService _activityService = ActivityService();

  // Timer
  final Stopwatch _activityStopwatch = Stopwatch();
  Timer? _uiUpdateTimer;
  bool _isTimerRunning = false;

  // Evidence
  String? _videoPath;
  String? _imagePath;
  final TextEditingController _descriptionController = TextEditingController();

  // Segment Results (คะแนนแต่ละข้อ)
  final List<SegmentResult> _segmentResults = [];
  List<dynamic> _segments = [];
  final Map<int, int> _originalScores = {}; // เก็บคะแนนเดิมของแต่ละข้อ
  final Map<int, String?> _userAnswers = {}; // เก็บคำตอบที่ผู้ใช้กรอก
  final Map<int, bool?> _answerStatus = {}; // null=ยังไม่ตอบ, true=ถูก, false=ผิด

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
    // Parse segments from activity
    if (widget.activity.segments != null) {
      if (widget.activity.segments is List) {
        _segments = widget.activity.segments as List;
      } else if (widget.activity.segments is String) {
        // If it's a string, it might need parsing
        debugPrint('⚠️ Segments is a string, might need JSON parsing');
        _segments = [];
      } else {
        _segments = [];
      }
    }

    // Initialize segment results and store original scores
    for (int i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      final int scoreFromSegment = segment['score'] as int? ??
          segment['maxScore'] as int? ??
          segment['point'] as int? ??
          100; // Fallback to 100

      // Store original score
      _originalScores[i] = scoreFromSegment;

      // Initialize with 0 score (not answered yet)
      _segmentResults.add(SegmentResult(
        id: segment['id']?.toString() ?? '',
        text: segment['question']?.toString() ??
            segment['text']?.toString() ??
            '',
        maxScore: 0, // Start with 0 (not answered)
      ));
    }

    debugPrint('📊 Loaded ${_segments.length} questions');
    debugPrint('📊 Original scores: $_originalScores');
  }

  void _startTimer() {
    if (_isTimerRunning) return;

    setState(() {
      _isTimerRunning = true;
    });

    _activityStopwatch.start();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isTimerRunning) {
        setState(() {}); // Trigger rebuild for time display
      }
    });

    debugPrint('⏱️ Timer started for analysis activity');
  }

  void _pauseTimer() {
    _activityStopwatch.stop();
    _uiUpdateTimer?.cancel();

    setState(() {
      _isTimerRunning = false;
    });

    debugPrint('⏱️ Timer paused at ${_activityStopwatch.elapsed.inSeconds}s');
  }

  void _stopTimer() {
    _activityStopwatch.stop();
    _uiUpdateTimer?.cancel();

    setState(() {
      _isTimerRunning = false;
    });

    debugPrint('⏱️ Timer stopped at ${_activityStopwatch.elapsed.inSeconds}s');
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

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

  /// Extract all numbers from a string (ignores emojis, symbols, text)
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
            Text(
              'Answer #${index + 1}',
              style: AppTextStyles.heading(20, color: Palette.sky),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
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
          ],
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

              // Compare numbers only
              final userNumbers = _extractNumbers(userInput);
              final solutionNumbers = _extractNumbers(solutionAnswer);

              final isCorrect = userNumbers.isNotEmpty &&
                  solutionNumbers.isNotEmpty &&
                  userNumbers.join(',') == solutionNumbers.join(',');

              setState(() {
                _userAnswers[index] = userInput;
                _answerStatus[index] = isCorrect;
              });

              if (isCorrect) {
                _markQuestionCorrect(index);
              } else {
                _markQuestionIncorrect(index);
              }
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

  void _markQuestionCorrect(int index) {
    // Get original score from stored map
    final int originalScore = _originalScores[index] ?? 100;

    setState(() {
      _segmentResults[index].maxScore =
          originalScore; // Full score from segment
    });
    debugPrint(
        '✅ Question ${index + 1} marked as correct (score: $originalScore)');
  }

  void _markQuestionIncorrect(int index) {
    setState(() {
      _segmentResults[index].maxScore = 0; // No score
    });
    debugPrint('❌ Question ${index + 1} marked as incorrect');
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
            Text(
              'เฉลยข้อ ${index + 1}',
              style: GoogleFonts.itim(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Palette.sky,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คำถาม:',
              style: GoogleFonts.itim(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              question,
              style: GoogleFonts.itim(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
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
                      Icon(Icons.check_circle, color: Palette.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'คำตอบ:',
                        style: GoogleFonts.itim(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Palette.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    answer,
                    style: GoogleFonts.itim(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ปิด',
              style: GoogleFonts.itim(fontSize: 16, color: Palette.sky),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final String? childId = context.read<UserProvider>().currentChildId;

    if (childId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Child ID not found. Please login again.')),
        );
      }
      return;
    }

    // Stop timer
    _stopTimer();
    final timeSpentSeconds = _activityStopwatch.elapsed.inSeconds;

    setState(() => _isSubmitting = true);

    // Prepare evidence payload
    final evidencePayload = {
      'videoPathLocal': _videoPath,
      'imagePathLocal': _imagePath,
      'status': 'Pending Approval',
      'description': _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    };

    try {
      debugPrint('📊 Submitting analysis activity');
      debugPrint('  - Questions answered: ${_segmentResults.length}');
      debugPrint('  - Time spent: $timeSpentSeconds seconds');
      debugPrint('  - Evidence: $evidencePayload');

      final response = await _activityService.finalizeQuest(
        childId: childId,
        activityId: widget.activity.id,
        segmentResults: _segmentResults,
        activityMaxScore: widget.activity.maxScore,
        evidence: evidencePayload,
        timeSpent: timeSpentSeconds,
        useDirectScore: true, // ✅ ใช้คะแนนดิบสำหรับกิจกรรมวิเคราะห์
      );

      if (mounted) {
        // Go directly to result screen
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
      debugPrint('❌ Error submitting activity: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing activity: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
              child: Text(
                'No questions available',
                style:
                    AppTextStyles.heading(20, color: Colors.grey),
              ),
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
                        // Info badges (Category, Difficulty, Max Score) - บนสุด
                        InfoBadges(activity: widget.activity),

                        const SizedBox(height: 16),

                        // Timer display
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
                              style: AppTextStyles.heading(24, color: Palette.sky),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Start/Stop timer button
                        Center(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isTimerRunning ? _pauseTimer : _startTimer,
                            icon: Icon(
                              _isTimerRunning ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isTimerRunning ? 'PAUSE' : 'START',
                              style: AppTextStyles.heading(20, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isTimerRunning ? Colors.orange : Palette.success,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Questions header
                        Text(
                          'QUESTIONS',
                          style: AppTextStyles.heading(24, color: Palette.sky),
                        ),

                        const SizedBox(height: 10),

                        // Questions list
                        ...List.generate(_segments.length, (index) {
                          final segment = _segments[index];
                          final question = segment['question']?.toString() ??
                              segment['text']?.toString() ??
                              'Question ${index + 1}';
                          final status = _answerStatus[index]; // null, true, false
                          final userAnswer = _userAnswers[index];

                          // Card colors based on answer status
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
                                // Question number header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Palette.sky,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      topRight: Radius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(statusIcon,
                                          color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Question ${index + 1}',
                                        style: AppTextStyles.heading(16, color: Colors.white),
                                      ),
                                      const Spacer(),
                                      // Hint button
                                      GestureDetector(
                                        onTap: () => _showAnswerHint(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.lightbulb_outline,
                                            color: Colors.amber,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Question text
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    question,
                                    style: AppTextStyles.body(15, color: Colors.black87),
                                  ),
                                ),
                                // User answer display (if answered)
                                if (userAnswer != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        14, 0, 14, 8),
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
                                          Icon(statusIcon,
                                              color: statusIconColor, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Your answer: $userAnswer',
                                              style: AppTextStyles.label(13, color: statusIconColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // Answer button
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 0, 14, 14),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showAnswerDialog(index),
                                      icon: Icon(
                                        status == null
                                            ? Icons.edit
                                            : Icons.refresh,
                                        size: 18,
                                      ),
                                      label: Text(
                                        status == null
                                            ? 'ANSWER'
                                            : 'ANSWER AGAIN',
                                        style: AppTextStyles.heading(14),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            status == null ? Palette.sky : Colors.grey.shade400,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 30),

                        // Evidence section
                        Text(
                          'EVIDENCE',
                          style: AppTextStyles.heading(20, color: Palette.error),
                        ),

                        const SizedBox(height: 15),

                        // Diary
                        Text(
                          'DIARY / NOTES',
                          style: AppTextStyles.heading(18, color: Colors.black54),
                        ),
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

                        // Image
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IMAGE',
                                    style: AppTextStyles.heading(18, color: Colors.black54),
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
                                                      icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16),
                                                      onPressed: () => setState(
                                                          () => _imagePath =
                                                              null),
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
                                                const Icon(
                                                    Icons.add_photo_alternate,
                                                    size: 40,
                                                    color: Colors.grey),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Add Image',
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
                                    'VIDEO',
                                    style: AppTextStyles.heading(18, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 5),
                                  GestureDetector(
                                    onTap: () =>
                                        _handleMediaSelection(isVideo: true),
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
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.videocam,
                                                          size: 50,
                                                          color: Palette.success),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Video Added',
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
                                                      icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16),
                                                      onPressed: () => setState(
                                                          () => _videoPath =
                                                              null),
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
                                                const Icon(
                                                    Icons.add_circle_outline,
                                                    size: 40,
                                                    color: Colors.grey),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Add Video',
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

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Sticky FINISH button
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
}
