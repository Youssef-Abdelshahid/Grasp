import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/ai_controls/providers/ai_controls_provider.dart';
import '../../../models/ai_controls_model.dart';
import '../../../services/ai_controls_service.dart';

class AdminAiControlsPage extends ConsumerStatefulWidget {
  const AdminAiControlsPage({super.key});

  @override
  ConsumerState<AdminAiControlsPage> createState() =>
      _AdminAiControlsPageState();
}

class _AdminAiControlsPageState extends ConsumerState<AdminAiControlsPage> {
  bool _aiEnabled = true;
  bool _studentFlashcardGeneration = true;
  bool _studentStudyNotesGeneration = true;
  bool _instructorAiQuizGeneration = true;
  bool _instructorAiAssignmentGeneration = true;
  bool _adminAiQuizGeneration = true;
  bool _adminAiAssignmentGeneration = true;
  bool _singleQuestionGeneration = true;
  bool _aiUsageLimit = true;

  final _studentDailyRequestsController = TextEditingController(text: '20');
  final _instructorDailyRequestsController = TextEditingController(text: '40');
  final _adminDailyRequestsController = TextEditingController(text: '100');
  final _maxMaterialContextController = TextEditingController(text: '16000');
  final _maxQuestionsController = TextEditingController(text: '30');
  final _maxFlashcardsController = TextEditingController(text: '40');
  final _maxStudyNotesLengthController = TextEditingController(text: '4000');
  String _aiModel = 'Gemini 3 Flash';
  bool _hasHydrated = false;

  static const _models = [
    'Gemini 3 Flash',
    'Gemini 2.5 Flash',
    'Gemini 3.1 Flash Lite',
  ];

  @override
  void dispose() {
    _studentDailyRequestsController.dispose();
    _instructorDailyRequestsController.dispose();
    _adminDailyRequestsController.dispose();
    _maxMaterialContextController.dispose();
    _maxQuestionsController.dispose();
    _maxFlashcardsController.dispose();
    _maxStudyNotesLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(adminAiControlsProvider);
    final statsAsync = ref.watch(aiUsageStatsProvider);
    configAsync.whenData((config) {
      if (!_hasHydrated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _hasHydrated) return;
          _applyConfig(config);
        });
      }
    });

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    if (configAsync.isLoading && !_hasHydrated) {
      return const Center(child: CircularProgressIndicator());
    }

    if (configAsync.hasError && !_hasHydrated) {
      return _ErrorState(
        message: _friendlyError(configAsync.error),
        onRetry: () => ref.invalidate(adminAiControlsProvider),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        children: [
          _buildSaveBar(configAsync.isLoading),
          const SizedBox(height: 20),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildAiToggleSection(),
                        const SizedBox(height: 20),
                        _buildAiLimitsSection(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildModelConfig(),
                        const SizedBox(height: 20),
                        _buildUsageOverview(statsAsync),
                        const SizedBox(height: 20),
                        _buildFeatureSummary(),
                      ],
                    ),
                  ),
                ],
              )
          else
            Column(
                children: [
                  _buildAiToggleSection(),
                  const SizedBox(height: 20),
                  _buildModelConfig(),
                  const SizedBox(height: 20),
                  _buildAiLimitsSection(),
                  const SizedBox(height: 20),
                  _buildUsageOverview(statsAsync),
                  const SizedBox(height: 20),
                  _buildFeatureSummary(),
                ],
              ),
        ],
      ),
    );
  }

  void _applyConfig(AiControlsConfig config) {
    setState(() {
      _aiEnabled = config.enableAiFeatures;
      _studentFlashcardGeneration = config.studentFlashcardGeneration;
      _studentStudyNotesGeneration = config.studentStudyNotesGeneration;
      _instructorAiQuizGeneration = config.instructorAiQuizGeneration;
      _instructorAiAssignmentGeneration =
          config.instructorAiAssignmentGeneration;
      _adminAiQuizGeneration = config.adminAiQuizGeneration;
      _adminAiAssignmentGeneration = config.adminAiAssignmentGeneration;
      _singleQuestionGeneration = config.singleQuestionGeneration;
      _aiUsageLimit = config.enableDailyAiRequestLimit;
      _aiModel = config.defaultAiModel;
      _studentDailyRequestsController.text =
          config.studentDailyAiRequests.toString();
      _instructorDailyRequestsController.text =
          config.instructorDailyAiRequests.toString();
      _adminDailyRequestsController.text = config.adminDailyAiRequests.toString();
      _maxMaterialContextController.text =
          config.maxMaterialContextSize.toString();
      _maxQuestionsController.text =
          config.maxGeneratedQuestionsPerQuiz.toString();
      _maxFlashcardsController.text = config.maxGeneratedFlashcards.toString();
      _maxStudyNotesLengthController.text =
          config.maxGeneratedStudyNotesLength.toString();
      _hasHydrated = true;
    });
  }

  AiControlsConfig _configFromInputs() {
    int read(TextEditingController controller, int fallback) {
      return int.tryParse(controller.text.trim()) ?? fallback;
    }

    final defaults = AiControlsConfig.defaults();
    return AiControlsConfig(
      enableAiFeatures: _aiEnabled,
      studentFlashcardGeneration: _studentFlashcardGeneration,
      studentStudyNotesGeneration: _studentStudyNotesGeneration,
      instructorAiQuizGeneration: _instructorAiQuizGeneration,
      instructorAiAssignmentGeneration: _instructorAiAssignmentGeneration,
      adminAiQuizGeneration: _adminAiQuizGeneration,
      adminAiAssignmentGeneration: _adminAiAssignmentGeneration,
      singleQuestionGeneration: _singleQuestionGeneration,
      defaultAiModel: _aiModel,
      enableDailyAiRequestLimit: _aiUsageLimit,
      studentDailyAiRequests: read(
        _studentDailyRequestsController,
        defaults.studentDailyAiRequests,
      ),
      instructorDailyAiRequests: read(
        _instructorDailyRequestsController,
        defaults.instructorDailyAiRequests,
      ),
      adminDailyAiRequests: read(
        _adminDailyRequestsController,
        defaults.adminDailyAiRequests,
      ),
      maxMaterialContextSize: read(
        _maxMaterialContextController,
        defaults.maxMaterialContextSize,
      ),
      maxGeneratedQuestionsPerQuiz: read(
        _maxQuestionsController,
        defaults.maxGeneratedQuestionsPerQuiz,
      ),
      maxGeneratedFlashcards: read(
        _maxFlashcardsController,
        defaults.maxGeneratedFlashcards,
      ),
      maxGeneratedStudyNotesLength: read(
        _maxStudyNotesLengthController,
        defaults.maxGeneratedStudyNotesLength,
      ),
    );
  }

  Future<void> _save() async {
    try {
      final saved = await ref
          .read(adminAiControlsProvider.notifier)
          .save(_configFromInputs());
      _applyConfig(saved);
      _showSnackBar('AI controls saved successfully');
    } catch (error) {
      _showSnackBar(_friendlyError(error), isError: true);
    }
  }

  Future<void> _reset() async {
    try {
      final saved = await ref.read(adminAiControlsProvider.notifier).reset();
      _applyConfig(saved);
      _showSnackBar('AI controls reset to defaults');
    } catch (error) {
      _showSnackBar(_friendlyError(error), isError: true);
    }
  }

  Widget _buildSaveBar(bool isSaving) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'AI controls are saved platform-wide and enforced before Gemini is called.',
              style: AppTextStyles.caption,
            ),
          ),
          TextButton(
            onPressed: isSaving ? null : _reset,
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: isSaving ? null : _save,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyError(Object? error) {
    if (error is AiControlsException) return error.message;
    return 'Unable to update AI controls right now. Please try again.';
  }

  Widget _buildAiToggleSection() {
    return _Section(
      title: 'AI Feature Controls',
      icon: Icons.auto_awesome_rounded,
      iconColor: AppColors.violet,
      iconBg: AppColors.violetLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Enable AI Features',
            subtitle: 'Allow AI-powered features across the platform',
            value: _aiEnabled,
            onChanged: (v) => setState(() => _aiEnabled = v),
          ),
          _ToggleTile(
            label: 'Student Flashcard Generation',
            subtitle:
                'Allow students to generate private AI flashcards from course materials',
            value: _studentFlashcardGeneration,
            onChanged: (v) =>
                setState(() => _studentFlashcardGeneration = v),
          ),
          _ToggleTile(
            label: 'Student Study Notes Generation',
            subtitle:
                'Allow students to generate private AI revision sheets from course materials',
            value: _studentStudyNotesGeneration,
            onChanged: (v) =>
                setState(() => _studentStudyNotesGeneration = v),
          ),
          _ToggleTile(
            label: 'Instructor AI Quiz Generation',
            subtitle:
                'Allow instructors to generate quiz drafts from selected course materials',
            value: _instructorAiQuizGeneration,
            onChanged: (v) =>
                setState(() => _instructorAiQuizGeneration = v),
          ),
          _ToggleTile(
            label: 'Instructor AI Assignment Generation',
            subtitle:
                'Allow instructors to generate assignment drafts from selected course materials',
            value: _instructorAiAssignmentGeneration,
            onChanged: (v) =>
                setState(() => _instructorAiAssignmentGeneration = v),
          ),
          _ToggleTile(
            label: 'Admin AI Quiz Generation',
            subtitle: 'Allow admins to generate quiz drafts for any course',
            value: _adminAiQuizGeneration,
            onChanged: (v) => setState(() => _adminAiQuizGeneration = v),
          ),
          _ToggleTile(
            label: 'Admin AI Assignment Generation',
            subtitle:
                'Allow admins to generate assignment drafts for any course',
            value: _adminAiAssignmentGeneration,
            onChanged: (v) =>
                setState(() => _adminAiAssignmentGeneration = v),
          ),
          _ToggleTile(
            label: 'Single Question Generation',
            subtitle:
                'Allow AI generation of one quiz question inside the quiz editor',
            value: _singleQuestionGeneration,
            onChanged: (v) =>
                setState(() => _singleQuestionGeneration = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAiLimitsSection() {
    return _Section(
      title: 'Usage Limits',
      icon: Icons.speed_rounded,
      iconColor: AppColors.amber,
      iconBg: AppColors.amberLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Enable Daily AI Request Limit',
            subtitle:
                'Limit how many AI generation requests a user can make per day',
            value: _aiUsageLimit,
            onChanged: (v) => setState(() => _aiUsageLimit = v),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _aiUsageLimit
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Column(
                      children: [
                        _ResponsiveInputRow(
                          children: [
                            _InputTile(
                              label: 'Student Daily AI Requests',
                              description:
                                  'Maximum daily AI generations for each student',
                              controller: _studentDailyRequestsController,
                              suffix: 'requests',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              hint: '20',
                            ),
                            _InputTile(
                              label: 'Instructor Daily AI Requests',
                              description:
                                  'Maximum daily AI generations for each instructor',
                              controller: _instructorDailyRequestsController,
                              suffix: 'requests',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              hint: '40',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ResponsiveInputRow(
                          children: [
                            _InputTile(
                              label: 'Admin Daily AI Requests',
                              description:
                                  'Maximum daily AI generations for each admin',
                              controller: _adminDailyRequestsController,
                              suffix: 'requests',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              hint: '100',
                            ),
                            _InputTile(
                              label: 'Max Material Context Size',
                              description:
                                  'Limit how much extracted material content is sent to AI',
                              controller: _maxMaterialContextController,
                              suffix: 'chars',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              hint: '16000',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ResponsiveInputRow(
                          children: [
                            _InputTile(
                              label: 'Max Generated Questions Per Quiz',
                              description:
                                  'Maximum number of questions allowed in one AI-generated quiz',
                              controller: _maxQuestionsController,
                              suffix: 'questions',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              hint: '30',
                            ),
                            _InputTile(
                              label: 'Max Generated Flashcards',
                              description:
                                  'Maximum number of flashcards generated in one request',
                              controller: _maxFlashcardsController,
                              suffix: 'cards',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              hint: '40',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _InputTile(
                          label: 'Max Generated Study Notes Length',
                          description:
                              'Controls the maximum size of generated revision sheets',
                          controller: _maxStudyNotesLengthController,
                          suffix: 'chars',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          hint: '4000',
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelConfig() {
    return _Section(
      title: 'Model Configuration',
      icon: Icons.memory_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Default AI Model', style: AppTextStyles.label),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _aiModel,
                isExpanded: true,
                style: AppTextStyles.body,
                items: _models
                    .map((v) =>
                        DropdownMenuItem<String>(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _aiModel = v ?? _aiModel),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Primary model is tried first',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 4),
          Text(
            'Fallback models are used only when the primary model fails or hits a limit',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageOverview(AsyncValue<AiUsageStats> statsAsync) {
    final stats = statsAsync.valueOrNull ?? AiUsageStats.empty();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.violetLight,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppColors.violet, size: 16),
              ),
              const SizedBox(width: 10),
              Text('This Month', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          _UsageStat(
              label: 'Total AI Requests',
              value: stats.totalAiRequests.toString(),
              icon: Icons.auto_awesome_rounded,
              color: AppColors.violet),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Quiz Drafts Generated',
              value: stats.quizDraftsGenerated.toString(),
              icon: Icons.quiz_rounded,
              color: AppColors.primary),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Assignment Drafts Generated',
              value: stats.assignmentDraftsGenerated.toString(),
              icon: Icons.assignment_rounded,
              color: AppColors.amber),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Flashcard Sets Generated',
              value: stats.flashcardSetsGenerated.toString(),
              icon: Icons.style_rounded,
              color: AppColors.emerald),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Study Notes Generated',
              value: stats.studyNotesGenerated.toString(),
              icon: Icons.note_alt_rounded,
              color: AppColors.cyan),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Failed AI Requests',
              value: stats.failedAiRequests.toString(),
              icon: Icons.error_outline_rounded,
              color: AppColors.rose),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Gemini Fallbacks Used',
              value: stats.geminiFallbacksUsed.toString(),
              icon: Icons.sync_rounded,
              color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildFeatureSummary() {
    return _Section(
      title: 'AI Feature Summary',
      icon: Icons.insights_rounded,
      iconColor: AppColors.emerald,
      iconBg: AppColors.emeraldLight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _FeatureChip(
            label: 'Quizzes',
            enabled: _instructorAiQuizGeneration || _adminAiQuizGeneration,
          ),
          _FeatureChip(
            label: 'Assignments',
            enabled: _instructorAiAssignmentGeneration ||
                _adminAiAssignmentGeneration,
          ),
          _FeatureChip(
            label: 'Flashcards',
            enabled: _studentFlashcardGeneration,
          ),
          _FeatureChip(
            label: 'Study Notes',
            enabled: _studentStudyNotesGeneration,
          ),
          _FeatureChip(
            label: 'Single Questions',
            enabled: _singleQuestionGeneration,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.emerald : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: enabled ? AppColors.emeraldLight : AppColors.background,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: enabled
              ? AppColors.emerald.withValues(alpha: 0.28)
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UsageStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _UsageStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        Text(value,
            style: AppTextStyles.label.copyWith(color: color)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor, iconBg;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool dangerColor;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.dangerColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: dangerColor && value
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor:
                dangerColor ? AppColors.error : AppColors.primary,
            activeTrackColor:
                dangerColor ? AppColors.errorLight : AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  final String label, suffix, hint;
  final String? description;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InputTile({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.hint,
    this.description,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(description!, style: AppTextStyles.caption),
        ],
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: AppTextStyles.caption
                .copyWith(color: AppColors.textMuted),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveInputRow extends StatelessWidget {
  const _ResponsiveInputRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }
}
