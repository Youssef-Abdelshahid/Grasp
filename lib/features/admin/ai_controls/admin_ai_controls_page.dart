import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminAiControlsPage extends StatefulWidget {
  const AdminAiControlsPage({super.key});

  @override
  State<AdminAiControlsPage> createState() => _AdminAiControlsPageState();
}

class _AdminAiControlsPageState extends State<AdminAiControlsPage> {
  bool _aiEnabled = true;
  bool _aiAutoPublish = false;
  bool _aiContentReview = true;
  bool _aiUsageLimit = true;
  bool _aiForStudents = false;
  bool _aiSafetyFilter = true;
  bool _aiLogUsage = true;

  final _aiLimitController = TextEditingController(text: '50');
  final _aiTokenLimitController = TextEditingController(text: '4096');
  String _aiModel = 'Claude 3.5 Sonnet';
  String _aiQuality = 'Balanced';

  static const _models = [
    'Claude 3.5 Sonnet',
    'Claude 3 Haiku',
    'GPT-4o',
    'Gemini 1.5 Pro'
  ];
  static const _qualities = ['Economy', 'Balanced', 'High Quality'];

  @override
  void dispose() {
    _aiLimitController.dispose();
    _aiTokenLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: isWide
          ? Row(
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
                      _buildUsageOverview(),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildAiToggleSection(),
                const SizedBox(height: 20),
                _buildModelConfig(),
                const SizedBox(height: 20),
                _buildAiLimitsSection(),
                const SizedBox(height: 20),
                _buildUsageOverview(),
              ],
            ),
    );
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
            subtitle: 'Allow AI-powered generation platform-wide',
            value: _aiEnabled,
            onChanged: (v) => setState(() => _aiEnabled = v),
          ),
          _ToggleTile(
            label: 'AI Access for Students',
            subtitle: 'Let students use AI tools for study assistance',
            value: _aiForStudents,
            onChanged: (v) => setState(() => _aiForStudents = v),
          ),
          _ToggleTile(
            label: 'Auto-publish AI Content',
            subtitle:
                'Skip review and publish generated content immediately',
            value: _aiAutoPublish,
            onChanged: (v) => setState(() => _aiAutoPublish = v),
            dangerColor: true,
          ),
          _ToggleTile(
            label: 'Instructor AI Review Required',
            subtitle: 'All AI content must be reviewed before publishing',
            value: _aiContentReview,
            onChanged: (v) => setState(() => _aiContentReview = v),
          ),
          _ToggleTile(
            label: 'Safety Content Filtering',
            subtitle:
                'Block harmful or inappropriate AI-generated content',
            value: _aiSafetyFilter,
            onChanged: (v) => setState(() => _aiSafetyFilter = v),
          ),
          _ToggleTile(
            label: 'Log AI Usage',
            subtitle: 'Track all AI requests for audit and billing',
            value: _aiLogUsage,
            onChanged: (v) => setState(() => _aiLogUsage = v),
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
            label: 'AI Daily Usage Limit',
            subtitle: 'Cap AI tasks per instructor per day',
            value: _aiUsageLimit,
            onChanged: (v) => setState(() => _aiUsageLimit = v),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _aiUsageLimit
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _InputTile(
                            label: 'Tasks per day limit',
                            controller: _aiLimitController,
                            suffix: 'tasks',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            hint: '50',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _InputTile(
                            label: 'Max tokens per request',
                            controller: _aiTokenLimitController,
                            suffix: 'tokens',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            hint: '4096',
                          ),
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
          Text('Response Quality', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text('Higher quality uses more tokens per request',
              style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Row(
            children: _qualities.map((q) {
              final isSelected = _aiQuality == q;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: q != _qualities.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _aiQuality = q),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        q,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageOverview() {
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
              value: '3,847',
              icon: Icons.auto_awesome_rounded,
              color: AppColors.violet),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Content Generated',
              value: '512 items',
              icon: Icons.article_rounded,
              color: AppColors.primary),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Tokens Used',
              value: '1.2M',
              icon: Icons.memory_rounded,
              color: AppColors.amber),
          const SizedBox(height: 12),
          _UsageStat(
              label: 'Flagged Content',
              value: '14',
              icon: Icons.flag_rounded,
              color: AppColors.rose),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Text('Token Usage', style: AppTextStyles.label),
          const SizedBox(height: 6),
          Text('1.2M / 5M tokens this month',
              style: AppTextStyles.caption),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: const LinearProgressIndicator(
              value: 0.24,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(AppColors.violet),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text('24% of monthly quota',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ],
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
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InputTile({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
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
