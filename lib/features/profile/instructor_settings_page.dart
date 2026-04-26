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
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _quizAlerts = true;
  bool _assignmentAlerts = true;
  bool _studentActivity = true;
  bool _announcementAlerts = true;
  bool _deadlineReminders = true;
  bool _compactView = false;
  bool _saving = false;

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
          _studentActivity = prefs['student_activity'] as bool? ?? true;
          _announcementAlerts = prefs['announcement_alerts'] as bool? ?? true;
          _deadlineReminders = prefs['deadline_reminders'] as bool? ?? true;
          _compactView = prefs['compact_view'] as bool? ?? false;
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
                    Expanded(child: _appearanceSection()),
                    const SizedBox(width: 20),
                    Expanded(child: _accountSection()),
                  ],
                )
              else ...[
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

  Future<void> _save() async {
    setState(() => _saving = true);
    await ProfileService.instance.updatePreferences({
      'email_notifications': _emailNotifications,
      'push_notifications': _pushNotifications,
      'quiz_submission_alerts': _quizAlerts,
      'assignment_submission_alerts': _assignmentAlerts,
      'student_activity': _studentActivity,
      'announcement_alerts': _announcementAlerts,
      'deadline_reminders': _deadlineReminders,
      'compact_view': _compactView,
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
        'Student Activity',
        _studentActivity,
        (value) => setState(() => _studentActivity = value),
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
      _toggle(
        'Compact View',
        _compactView,
        (value) => setState(() => _compactView = value),
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
