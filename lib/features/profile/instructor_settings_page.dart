import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/auth/app_role.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/settings/providers/user_settings_provider.dart';
import '../../features/theme/providers/theme_mode_provider.dart';
import '../../models/user_settings_model.dart';
import '../../widgets/auth/logout_flow.dart';

class InstructorSettingsPage extends ConsumerStatefulWidget {
  const InstructorSettingsPage({super.key});

  @override
  ConsumerState<InstructorSettingsPage> createState() =>
      _InstructorSettingsPageState();
}

class _InstructorSettingsPageState
    extends ConsumerState<InstructorSettingsPage> {
  bool _didPopulate = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _quizAlerts = true;
  bool _assignmentAlerts = true;
  bool _announcementAlerts = true;
  bool _deadlineReminders = true;
  bool _saving = false;
  String _defaultQuizDifficulty = 'Medium';
  int _defaultQuestionCount = 10;
  final Set<String> _defaultQuestionTypes = {'MCQ', 'True/False'};
  String _defaultAssignmentDifficulty = 'Medium';
  String _themeMode = themeModeLight;

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _questionTypes = [
    'MCQ',
    'True/False',
    'Short Answer',
    'Matching',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;
    final settingsValue = ref.watch(userSettingsProvider);

    return settingsValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _SettingsLoadError(
        onRetry: () => ref.invalidate(userSettingsProvider),
      ),
      data: (envelope) {
        final settings = envelope.settings;
        if (settings is! InstructorSettings) {
          final currentRole = ref.watch(currentRoleProvider);
          if (currentRole == AppRole.instructor) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.invalidate(userSettingsProvider);
              }
            });
            return const Center(child: CircularProgressIndicator());
          }
          return const _SettingsMessage(
            message: 'Instructor settings are not available for this account.',
          );
        }
        if (!_didPopulate) {
          _apply(settings);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            children: [
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _notificationsSection()),
                    const SizedBox(width: 20),
                    Expanded(child: _workflowSection()),
                  ],
                )
              else ...[
                _notificationsSection(),
                const SizedBox(height: 20),
                _workflowSection(),
              ],
              const SizedBox(height: 20),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _generationDefaultsSection()),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _appearanceSection(),
                          const SizedBox(height: 20),
                          _accountSection(),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                _generationDefaultsSection(),
                const SizedBox(height: 20),
                _appearanceSection(),
                const SizedBox(height: 20),
                _accountSection(),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Settings'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _apply(InstructorSettings settings) {
    _didPopulate = true;
    _emailNotifications = settings.emailNotifications;
    _pushNotifications = settings.pushNotifications;
    _quizAlerts = settings.quizSubmissionAlerts;
    _assignmentAlerts = settings.assignmentSubmissionAlerts;
    _announcementAlerts = settings.announcementAlerts;
    _deadlineReminders = settings.deadlineReminders;
    _defaultQuizDifficulty = _displayDifficulty(settings.defaultQuizDifficulty);
    _defaultQuestionCount = settings.defaultQuestionCount;
    _defaultQuestionTypes
      ..clear()
      ..addAll(settings.defaultQuestionTypes);
    _defaultAssignmentDifficulty = _displayDifficulty(
      settings.defaultAssignmentDifficulty,
    );
    _themeMode = settings.themeMode;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(userSettingsProvider.notifier)
        .save(
          InstructorSettings(
            themeMode: _themeMode,
            emailNotifications: _emailNotifications,
            pushNotifications: _pushNotifications,
            quizSubmissionAlerts: _quizAlerts,
            assignmentSubmissionAlerts: _assignmentAlerts,
            announcementAlerts: _announcementAlerts,
            deadlineReminders: _deadlineReminders,
            defaultQuizDifficulty: _defaultQuizDifficulty.toLowerCase(),
            defaultQuestionCount: _defaultQuestionCount,
            defaultQuestionTypes: _defaultQuestionTypes.toList(),
            defaultAssignmentDifficulty: _defaultAssignmentDifficulty
                .toLowerCase(),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final savedState = ref.read(userSettingsProvider);
    final error = savedState.error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? 'Settings saved.' : _friendlyError(error),
        ),
      ),
    );
  }

  Widget _notificationsSection() => _SettingsSection(
    title: 'Notification Preferences',
    children: [
      _toggle(
        'Email Notifications',
        _emailNotifications,
        (value) => setState(() => _emailNotifications = value),
      ),
      _toggle(
        'Push Notifications',
        _pushNotifications,
        (value) => setState(() => _pushNotifications = value),
      ),
      _toggle(
        'Quiz Submission Alerts',
        _quizAlerts,
        (value) => setState(() => _quizAlerts = value),
      ),
      _toggle(
        'Assignment Submission Alerts',
        _assignmentAlerts,
        (value) => setState(() => _assignmentAlerts = value),
      ),
      _toggle(
        'Announcement Alerts',
        _announcementAlerts,
        (value) => setState(() => _announcementAlerts = value),
      ),
    ],
  );

  Widget _workflowSection() => _SettingsSection(
    title: 'Workflow Preferences',
    children: [
      _toggle(
        'Deadline Reminders',
        _deadlineReminders,
        (value) => setState(() => _deadlineReminders = value),
      ),
    ],
  );

  Widget _appearanceSection() => _SettingsSection(
    title: 'Appearance',
    children: [
      DropdownButtonFormField<String>(
        initialValue: _themeMode,
        decoration: const InputDecoration(labelText: 'Theme'),
        items: const [
          DropdownMenuItem(value: themeModeLight, child: Text('Light')),
          DropdownMenuItem(value: themeModeDark, child: Text('Dark')),
        ],
        onChanged: _saving
            ? null
            : (value) {
                if (value == null) return;
                setState(() => _themeMode = value);
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(
                      value == themeModeDark ? ThemeMode.dark : ThemeMode.light,
                    );
              },
      ),
      const SizedBox(height: 8),
      Text(
        'Applies immediately and is saved with your settings.',
        style: AppTextStyles.bodySmall,
      ),
    ],
  );

  Widget _generationDefaultsSection() => _SettingsSection(
    title: 'Default AI Generation Preferences',
    children: [
      _dropdown(
        label: 'Default quiz difficulty',
        value: _defaultQuizDifficulty,
        values: _difficulties,
        onChanged: (value) => setState(
          () => _defaultQuizDifficulty = value ?? _defaultQuizDifficulty,
        ),
      ),
      _questionCountControl(),
      const SizedBox(height: 8),
      Text('Default question types selected', style: AppTextStyles.label),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _questionTypes
            .map(
              (type) {
                final selected = _defaultQuestionTypes.contains(type);
                final canRemove = _defaultQuestionTypes.length > 1;
                return FilterChip(
                  label: Text(type),
                  selected: selected,
                  showCheckmark: true,
                  checkmarkColor: selected ? Colors.white : AppColors.primary,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  disabledColor: AppColors.primary.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: selected && !canRemove
                      ? null
                      : (isSelected) {
                          setState(() {
                            if (isSelected) {
                              _defaultQuestionTypes.add(type);
                            } else if (_defaultQuestionTypes.length > 1) {
                              _defaultQuestionTypes.remove(type);
                            }
                          });
                        },
                );
              },
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      _dropdown(
        label: 'Default assignment difficulty',
        value: _defaultAssignmentDifficulty,
        values: _difficulties,
        onChanged: (value) => setState(
          () => _defaultAssignmentDifficulty =
              value ?? _defaultAssignmentDifficulty,
        ),
      ),
    ],
  );

  Widget _accountSection() => _SettingsSection(
    title: 'Account',
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.logout_rounded, color: AppColors.error),
        title: const Text('Sign Out'),
        onTap: () => logoutAndReturnToAuthGate(context, ref),
      ),
    ],
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTextStyles.label),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _questionCountControl() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Default number of quiz questions',
              style: AppTextStyles.label,
            ),
          ),
          IconButton(
            tooltip: 'Decrease',
            onPressed: _defaultQuestionCount <= 1
                ? null
                : () => setState(() => _defaultQuestionCount--),
            icon: Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$_defaultQuestionCount',
              textAlign: TextAlign.center,
              style: AppTextStyles.label,
            ),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: _defaultQuestionCount >= 50
                ? null
                : () => setState(() => _defaultQuestionCount++),
            icon: Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

String _displayDifficulty(String value) {
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'easy':
      return 'Easy';
    case 'hard':
      return 'Hard';
    default:
      return 'Medium';
  }
}

String _friendlyError(Object error) {
  final message = error.toString();
  return message.replaceFirst('PostgrestException(message: ', '').split(',')[0];
}

class _SettingsLoadError extends StatelessWidget {
  const _SettingsLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40),
            const SizedBox(height: 12),
            Text(
              'Unable to load settings.',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _SettingsMessage extends StatelessWidget {
  const _SettingsMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, style: AppTextStyles.body),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
          Text(title, style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
