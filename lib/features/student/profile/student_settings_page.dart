import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/settings/providers/user_settings_provider.dart';
import '../../../models/user_settings_model.dart';
import '../../../widgets/auth/logout_flow.dart';

class StudentSettingsPage extends ConsumerStatefulWidget {
  const StudentSettingsPage({super.key});

  @override
  ConsumerState<StudentSettingsPage> createState() =>
      _StudentSettingsPageState();
}

class _StudentSettingsPageState extends ConsumerState<StudentSettingsPage> {
  bool _didPopulate = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _assignmentReminders = true;
  bool _quizReminders = true;
  bool _announcementAlerts = true;
  bool _deadlineReminder24h = true;
  bool _deadlineReminder1h = false;
  bool _studyRemindersEnabled = true;
  bool _studyReminders = true;
  bool _weeklyStudySummary = true;
  bool _showOverdueFirst = true;
  String _deadlineReminderTime = '09:00';
  bool _saving = false;

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
        if (settings is! StudentSettings) {
          return const _SettingsMessage(
            message: 'Student settings are not available for this account.',
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
                    Expanded(child: _notificationSection()),
                    const SizedBox(width: 20),
                    Expanded(child: _calendarReminderSection()),
                  ],
                )
              else ...[
                _notificationSection(),
                const SizedBox(height: 20),
                _calendarReminderSection(),
              ],
              const SizedBox(height: 20),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: _accountSection())],
                )
              else ...[
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

  void _apply(StudentSettings settings) {
    _didPopulate = true;
    _emailNotifications = settings.emailNotifications;
    _pushNotifications = settings.pushNotifications;
    _assignmentReminders = settings.assignmentAlerts;
    _quizReminders = settings.quizAlerts;
    _announcementAlerts = settings.announcementAlerts;
    _deadlineReminder24h = settings.deadlineReminder24h;
    _deadlineReminder1h = settings.deadlineReminder1h;
    _studyRemindersEnabled = settings.studyReminders;
    _studyReminders = settings.dailyStudyReminder;
    _weeklyStudySummary = settings.weeklyStudySummary;
    _showOverdueFirst = settings.showOverdueFirst;
    _deadlineReminderTime = settings.defaultDeadlineReminderTime;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref
        .read(userSettingsProvider.notifier)
        .save(
          StudentSettings(
            emailNotifications: _emailNotifications,
            pushNotifications: _pushNotifications,
            assignmentAlerts: _assignmentReminders,
            quizAlerts: _quizReminders,
            announcementAlerts: _announcementAlerts,
            deadlineReminder24h: _deadlineReminder24h,
            deadlineReminder1h: _deadlineReminder1h,
            studyReminders: _studyRemindersEnabled,
            dailyStudyReminder: _studyReminders,
            weeklyStudySummary: _weeklyStudySummary,
            showOverdueFirst: _showOverdueFirst,
            defaultDeadlineReminderTime: _deadlineReminderTime,
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

  Widget _notificationSection() => _SettingsSection(
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
        'Assignment Alerts',
        _assignmentReminders,
        (value) => setState(() => _assignmentReminders = value),
      ),
      _toggle(
        'Quiz Alerts',
        _quizReminders,
        (value) => setState(() => _quizReminders = value),
      ),
      _toggle(
        'Announcement Alerts',
        _announcementAlerts,
        (value) => setState(() => _announcementAlerts = value),
      ),
    ],
  );

  Widget _calendarReminderSection() => _SettingsSection(
    title: 'Calendar / Reminder Preferences',
    children: [
      _toggle(
        '24-hour Deadline Reminder',
        _deadlineReminder24h,
        (value) => setState(() => _deadlineReminder24h = value),
      ),
      _toggle(
        '1-hour Deadline Reminder',
        _deadlineReminder1h,
        (value) => setState(() => _deadlineReminder1h = value),
      ),
      _timeTile(),
      _toggle(
        'Study Reminders',
        _studyRemindersEnabled,
        (value) => setState(() => _studyRemindersEnabled = value),
      ),
      _toggle(
        'Daily Study Reminder',
        _studyReminders,
        (value) => setState(() => _studyReminders = value),
      ),
      _toggle(
        'Weekly Study Summary',
        _weeklyStudySummary,
        (value) => setState(() => _weeklyStudySummary = value),
      ),
      _toggle(
        'Show Overdue Items First',
        _showOverdueFirst,
        (value) => setState(() => _showOverdueFirst = value),
      ),
    ],
  );

  Widget _timeTile() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Default Deadline Reminder Time', style: AppTextStyles.label),
      subtitle: Text(_deadlineReminderTime, style: AppTextStyles.bodySmall),
      trailing: const Icon(Icons.schedule_rounded),
      onTap: _saving ? null : _pickReminderTime,
    );
  }

  Future<void> _pickReminderTime() async {
    final parts = _deadlineReminderTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      _deadlineReminderTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Widget _accountSection() => _SettingsSection(
    title: 'Account',
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.logout_rounded, color: AppColors.error),
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
            const Icon(Icons.cloud_off_rounded, size: 40),
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
