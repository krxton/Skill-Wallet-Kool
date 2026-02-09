import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_wallet_kool/l10n/app_localizations.dart';

import '../../providers/user_provider.dart';
import '../../services/activity_service.dart';
import '../../theme/palette.dart';
import '../../theme/app_text_styles.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final ActivityService _activityService = ActivityService();

  // null = not selected yet, show category picker
  String? _selectedCategory;

  // Common fields
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _difficulty = 'ง่าย';

  // Physical-specific
  final _maxScoreCtrl = TextEditingController(text: '10');
  final _videoUrlCtrl = TextEditingController();

  // Analysis-specific — dynamic question list
  final List<Map<String, TextEditingController>> _questions = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _maxScoreCtrl.dispose();
    _videoUrlCtrl.dispose();
    for (final q in _questions) {
      q.values.forEach((c) => c.dispose());
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'question': TextEditingController(),
        'answer': TextEditingController(),
        'solution': TextEditingController(),
        'score': TextEditingController(text: '1'),
      });
    });
  }

  void _removeQuestion(int index) {
    final removed = _questions.removeAt(index);
    removed.values.forEach((c) => c.dispose());
    setState(() {});
  }

  int get _analysisMaxScore {
    int total = 0;
    for (final q in _questions) {
      total += int.tryParse(q['score']!.text) ?? 0;
    }
    return total;
  }

  bool get _isPhysical => _selectedCategory == 'ด้านร่างกาย';

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;

    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack(l.createActivity_nameRequired);
      return;
    }
    if (_contentCtrl.text.trim().isEmpty) {
      _showSnack(l.createActivity_contentRequired);
      return;
    }
    if (!_isPhysical && _questions.isEmpty) {
      _showSnack(l.createActivity_needQuestions);
      return;
    }

    final parentId =
        Provider.of<UserProvider>(context, listen: false).currentParentId;
    if (parentId == null || parentId.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final int maxScore;
      List<Map<String, dynamic>>? segments;

      if (_isPhysical) {
        maxScore = int.tryParse(_maxScoreCtrl.text) ?? 10;
      } else {
        maxScore = _analysisMaxScore;
        segments = _questions.asMap().entries.map((e) {
          final idx = e.key;
          final q = e.value;
          return {
            'id': idx + 1,
            'question': q['question']!.text.trim(),
            'answer': q['answer']!.text.trim(),
            'solution': q['solution']!.text.trim(),
            'score': int.tryParse(q['score']!.text) ?? 1,
          };
        }).toList();
      }

      await _activityService.createActivity(
        parentId: parentId,
        name: _nameCtrl.text.trim(),
        category: _selectedCategory!,
        content: _contentCtrl.text.trim(),
        difficulty: _difficulty,
        isPublic: _isPhysical, // Physical = public, Analysis = private
        maxScore: maxScore,
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        videoUrl: _isPhysical && _videoUrlCtrl.text.trim().isNotEmpty
            ? _videoUrlCtrl.text.trim()
            : null,
        segments: segments,
      );

      if (!mounted) return;
      _showSnack(l.createActivity_success);
      Navigator.of(context).pop(true); // return true = created
    } catch (e) {
      if (!mounted) return;
      _showSnack('${l.createActivity_error}: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Palette.cream,
      appBar: AppBar(
        backgroundColor: Palette.sky,
        title: Text(l.createActivity_title,
            style: AppTextStyles.heading(20, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _selectedCategory == null
          ? _buildCategoryPicker(l)
          : _buildForm(l),
    );
  }

  // ── Category Picker ────────────────────────────────────

  Widget _buildCategoryPicker(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.createActivity_selectCategory,
                style: AppTextStyles.heading(22)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _categoryCard(
                    icon: Icons.directions_run,
                    label: l.createActivity_physical,
                    color: Palette.physicalPlaceholder,
                    onTap: () => setState(
                        () => _selectedCategory = 'ด้านร่างกาย'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _categoryCard(
                    icon: Icons.psychology,
                    label: l.createActivity_analysis,
                    color: Palette.blueChip,
                    onTap: () {
                      setState(() => _selectedCategory = 'ด้านวิเคราะห์');
                      if (_questions.isEmpty) _addQuestion();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(label, style: AppTextStyles.label(16, color: color)),
          ],
        ),
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────

  Widget _buildForm(AppLocalizations l) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back to category
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = null),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios,
                          size: 14, color: Palette.sky),
                      Text(l.createActivity_selectCategory,
                          style: AppTextStyles.label(13, color: Palette.sky)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Category badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPhysical
                        ? Palette.physicalPlaceholder
                        : Palette.blueChip,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isPhysical
                        ? l.createActivity_physical
                        : l.createActivity_analysis,
                    style: AppTextStyles.label(13, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                _label(l.createActivity_name),
                _textField(_nameCtrl),
                const SizedBox(height: 12),

                // Description
                _label(l.createActivity_description),
                _textField(_descCtrl, maxLines: 3),
                const SizedBox(height: 12),

                // Difficulty
                _label(l.createActivity_difficulty),
                _buildDifficultyChips(),
                const SizedBox(height: 12),

                if (_isPhysical) ...[
                  // Max Score
                  _label(l.createActivity_maxScore),
                  _textField(_maxScoreCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),

                  // Video URL
                  _label(l.createActivity_videoUrl),
                  _textField(_videoUrlCtrl),
                  const SizedBox(height: 12),
                ],

                // Content / Instructions
                _label(l.createActivity_content),
                _textField(_contentCtrl, maxLines: 4),
                const SizedBox(height: 16),

                if (!_isPhysical) ...[
                  // Questions section
                  _label('${l.createActivity_question}  '
                      '(${l.createActivity_maxScore}: $_analysisMaxScore)'),
                  const SizedBox(height: 8),
                  ..._buildQuestionCards(l),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(l.createActivity_addQuestion),
                  ),
                ],

                const SizedBox(height: 80), // space for bottom button
              ],
            ),
          ),
        ),

        // Submit button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isSubmitting
                      ? l.createActivity_creating
                      : l.createActivity_submit,
                  style: AppTextStyles.heading(18, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Difficulty Chips ───────────────────────────────────

  Widget _buildDifficultyChips() {
    final options = ['ง่าย', 'กลาง', 'ยาก'];
    final labels = [
      AppLocalizations.of(context)!.common_difficultyEasy,
      AppLocalizations.of(context)!.common_difficultyMedium,
      AppLocalizations.of(context)!.common_difficultyHard,
    ];
    return Row(
      children: List.generate(options.length, (i) {
        final selected = _difficulty == options[i];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(labels[i]),
            selected: selected,
            selectedColor: Palette.warningLight,
            onSelected: (_) => setState(() => _difficulty = options[i]),
          ),
        );
      }),
    );
  }

  // ── Question Cards (Analysis) ──────────────────────────

  List<Widget> _buildQuestionCards(AppLocalizations l) {
    return _questions.asMap().entries.map((entry) {
      final idx = entry.key;
      final q = entry.value;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.createActivity_questionNo(idx + 1),
                      style: AppTextStyles.label(14)),
                  if (_questions.length > 1)
                    TextButton.icon(
                      onPressed: () => _removeQuestion(idx),
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Palette.deleteRed),
                      label: Text(l.createActivity_removeQuestion,
                          style: const TextStyle(
                              color: Palette.deleteRed, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _label(l.createActivity_question),
              _textField(q['question']!, maxLines: 2),
              const SizedBox(height: 8),
              _label(l.createActivity_answer),
              _textField(q['answer']!),
              const SizedBox(height: 8),
              _label(l.createActivity_solution),
              _textField(q['solution']!, maxLines: 3),
              const SizedBox(height: 8),
              _label(l.createActivity_score),
              _textField(q['score']!, keyboardType: TextInputType.number),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Helpers ────────────────────────────────────────────

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: AppTextStyles.label(13)),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Palette.divider),
        ),
      ),
      style: AppTextStyles.body(14),
    );
  }
}
