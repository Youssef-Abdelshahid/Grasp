import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class InstructorSettingsPage extends StatefulWidget {
  const InstructorSettingsPage({super.key});

  @override
  State<InstructorSettingsPage> createState() => _InstructorSettingsPageState();
}

class _InstructorSettingsPageState extends State<InstructorSettingsPage> {
  late Future<UserModel> _future;
  bool _didPopulate = false;
  Map<String, dynamic> _preferences = const {};
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

  static const _difficulties = ['Easy', 'Medium', 'Hard'];
  static const _questionTypes = [
    'MCQ',
    'True/False',
    'Short Answer',
    'Matching',
  ];

  @override
  void initState() {
    super.initState();
    _future = ProfileService.instance.getCurrentProfile();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return FutureBuilder<UserModel>(
      future: _future,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done &&
            profile == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (profile != null && !_didPopulate) {
          _didPopulate = true;
          final prefs = profile.preferences;
          _emailNotifications = prefs['email_notifications'] as bool? ?? true;
          _pushNotifications = prefs['push_notifications'] as bool? ?? true;
          _quizAlerts = prefs['quiz_submission_alerts'] as bool? ?? true;
          _assignmentAlerts =
              prefs['assignment_submission_alerts'] as bool? ?? true;
          _announcementAlerts = prefs['announcement_alerts'] as bool? ?? true;
          _deadlineReminders = prefs['deadline_reminders'] as bool? ?? true;
          _preferences = Map<String, dynamic>.from(prefs);
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
                    Expanded(child: _accountSection()),
                  ],
                )
              else ...[
                _generationDefaultsSection(),
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

  Future<void> _save() async {
    setState(() => _saving = true);
    await ProfileService.instance.updatePreferences({
      ..._preferences,
      'email_notifications': _emailNotifications,
      'push_notifications': _pushNotifications,
      'quiz_submission_alerts': _quizAlerts,
      'assignment_submission_alerts': _assignmentAlerts,
      'announcement_alerts': _announcementAlerts,
      'deadline_reminders': _deadlineReminders,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved.')));
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
              (type) => FilterChip(
                label: Text(type),
                selected: _defaultQuestionTypes.contains(type),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _defaultQuestionTypes.add(type);
                    } else if (_defaultQuestionTypes.length > 1) {
                      _defaultQuestionTypes.remove(type);
                    }
                  });
                },
              ),
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
        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
        title: const Text('Sign Out'),
        onTap: () async => AuthService.instance.logout(),
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
            icon: const Icon(Icons.remove_rounded),
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
            onPressed: () => setState(() => _defaultQuestionCount++),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
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
