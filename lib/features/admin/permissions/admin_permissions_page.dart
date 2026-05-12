import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/permissions/providers/permissions_provider.dart';
import '../../../models/permissions_model.dart';
import '../../../services/permissions_service.dart';

class AdminPermissionsPage extends ConsumerStatefulWidget {
  const AdminPermissionsPage({super.key});

  @override
  ConsumerState<AdminPermissionsPage> createState() =>
      _AdminPermissionsPageState();
}

class _AdminPermissionsPageState
    extends ConsumerState<AdminPermissionsPage> {
  AppPermissions? _draft;
  bool _hasLocalChanges = false;
  bool _isSaving = false;

  AppPermissions get _permissions => _draft ?? AppPermissions.defaults();

  @override
  Widget build(BuildContext context) {
    final permissionsAsync = ref.watch(adminPermissionsProvider);
    final loaded = permissionsAsync.valueOrNull;
    if (loaded != null && !_hasLocalChanges && _draft != loaded) {
      _draft = loaded;
    }

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    if (permissionsAsync.isLoading && _draft == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (permissionsAsync.hasError && _draft == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.error,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text('Permissions unavailable', style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                _friendlyError(permissionsAsync.error),
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminPermissionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        children: [
          if (permissionsAsync.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ErrorBanner(message: _friendlyError(permissionsAsync.error)),
            ),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildStudentPermissions(),
                          const SizedBox(height: 20),
                          _buildInstructorPermissions(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _buildGlobalControls(),
                          const SizedBox(height: 20),
                          _buildRoleSummary(),
                          const SizedBox(height: 20),
                          _buildActions(),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildStudentPermissions(),
                    const SizedBox(height: 20),
                    _buildInstructorPermissions(),
                    const SizedBox(height: 20),
                    _buildGlobalControls(),
                    const SizedBox(height: 20),
                    _buildRoleSummary(),
                    const SizedBox(height: 20),
                    _buildActions(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _hasLocalChanges
                  ? 'You have unsaved permission changes.'
                  : 'Permissions are up to date.',
              style: AppTextStyles.bodySmall,
            ),
          ),
          TextButton(
            onPressed: _isSaving ? null : _reset,
            child: const Text('Reset'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: !_hasLocalChanges || _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.save_rounded, size: 16),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final saved = await ref
          .read(adminPermissionsProvider.notifier)
          .save(_permissions);
      setState(() {
        _draft = saved;
        _hasLocalChanges = false;
      });
      _showMessage('Permissions saved.');
    } on PermissionsException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Unable to save permissions right now.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _reset() async {
    setState(() => _isSaving = true);
    try {
      final saved = await ref.read(adminPermissionsProvider.notifier).reset();
      setState(() {
        _draft = saved;
        _hasLocalChanges = false;
      });
      _showMessage('Permissions reset to defaults.');
    } on PermissionsException catch (error) {
      _showMessage(error.message, isError: true);
    } catch (_) {
      _showMessage('Unable to reset permissions right now.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _setPermission(String key, bool value) {
    setState(() {
      _draft = _permissions.copyWithKey(key, value);
      _hasLocalChanges = true;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  String _friendlyError(Object? error) {
    if (error is PermissionsException) {
      return error.message;
    }
    return 'Unable to load permissions right now. Please try again.';
  }

  Widget _buildStudentPermissions() {
    return _Section(
      title: 'Student Permissions',
      icon: Icons.school_rounded,
      iconColor: AppColors.cyan,
      iconBg: AppColors.cyanLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Download Materials',
            subtitle: 'Allow students to download/open course material files',
            value: _permissions.downloadMaterials,
            onChanged: (v) =>
                _setPermission(PermissionKeys.downloadMaterials, v),
          ),
          _ToggleTile(
            label: 'Take Quizzes',
            subtitle: 'Allow students to start published quizzes',
            value: _permissions.takeQuizzes,
            onChanged: (v) => _setPermission(PermissionKeys.takeQuizzes, v),
          ),
          _ToggleTile(
            label: 'Submit Assignments',
            subtitle: 'Allow students to submit assignment work',
            value: _permissions.submitAssignments,
            onChanged: (v) =>
                _setPermission(PermissionKeys.submitAssignments, v),
          ),
          _ToggleTile(
            label: 'View Course Student List',
            subtitle:
                'Allow students to see the read-only list of classmates in a course',
            value: _permissions.viewCourseStudentList,
            onChanged: (v) =>
                _setPermission(PermissionKeys.viewCourseStudentList, v),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorPermissions() {
    return _Section(
      title: 'Instructor Permissions',
      icon: Icons.menu_book_rounded,
      iconColor: AppColors.violet,
      iconBg: AppColors.violetLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Manage Courses',
            subtitle: 'Allow instructors to create, edit, and delete courses',
            value: _permissions.manageCourses,
            onChanged: (v) => _setPermission(PermissionKeys.manageCourses, v),
          ),
          _ToggleTile(
            label: 'Manage Course Students',
            subtitle:
                'Allow instructors to add and remove students from their assigned courses',
            value: _permissions.manageCourseStudents,
            onChanged: (v) =>
                _setPermission(PermissionKeys.manageCourseStudents, v),
          ),
          _ToggleTile(
            label: 'Upload Materials',
            subtitle: 'Allow instructors to upload course materials',
            value: _permissions.uploadMaterials,
            onChanged: (v) => _setPermission(PermissionKeys.uploadMaterials, v),
          ),
          _ToggleTile(
            label: 'Manage Quizzes',
            subtitle:
                'Allow instructors to create, edit, delete, and publish quizzes',
            value: _permissions.manageQuizzes,
            onChanged: (v) => _setPermission(PermissionKeys.manageQuizzes, v),
          ),
          _ToggleTile(
            label: 'Manage Assignments',
            subtitle:
                'Allow instructors to create, edit, delete, and publish assignments',
            value: _permissions.manageAssignments,
            onChanged: (v) =>
                _setPermission(PermissionKeys.manageAssignments, v),
          ),
          _ToggleTile(
            label: 'Post Announcements',
            subtitle:
                'Allow instructors to create and manage course announcements',
            value: _permissions.postAnnouncements,
            onChanged: (v) =>
                _setPermission(PermissionKeys.postAnnouncements, v),
          ),
          _ToggleTile(
            label: 'Use AI Quiz Generation',
            subtitle: 'Allow instructors to generate quizzes using AI',
            value: _permissions.useAiQuizGeneration,
            onChanged: (v) =>
                _setPermission(PermissionKeys.useAiQuizGeneration, v),
          ),
          _ToggleTile(
            label: 'Use AI Assignment Generation',
            subtitle: 'Allow instructors to generate assignments using AI',
            value: _permissions.useAiAssignmentGeneration,
            onChanged: (v) =>
                _setPermission(PermissionKeys.useAiAssignmentGeneration, v),
          ),
          _ToggleTile(
            label: 'Grade Student Work',
            subtitle:
                'Allow instructors to grade quiz attempts and assignment submissions',
            value: _permissions.gradeStudentWork,
            onChanged: (v) =>
                _setPermission(PermissionKeys.gradeStudentWork, v),
          ),
          _ToggleTile(
            label: 'View Student Activity',
            subtitle:
                'Allow instructors to view student activity, submissions, and attempts in their courses',
            value: _permissions.viewStudentActivity,
            onChanged: (v) =>
                _setPermission(PermissionKeys.viewStudentActivity, v),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalControls() {
    return _Section(
      title: 'Global Role Controls',
      icon: Icons.shield_rounded,
      iconColor: AppColors.rose,
      iconBg: AppColors.roseLight,
      child: Column(
        children: [
          _ToggleTile(
            label: 'Allow Public Student Registration',
            subtitle:
                'Allow students to create their own accounts from registration',
            value: _permissions.allowPublicStudentRegistration,
            onChanged: (v) =>
                _setPermission(PermissionKeys.allowPublicStudentRegistration, v),
          ),
          _ToggleTile(
            label: 'Allow Public Instructor Registration',
            subtitle:
                'Allow instructors to create their own accounts from registration',
            value: _permissions.allowPublicInstructorRegistration,
            onChanged: (v) => _setPermission(
              PermissionKeys.allowPublicInstructorRegistration,
              v,
            ),
          ),
          _ToggleTile(
            label: 'Allow Instructors to Create Courses',
            subtitle: 'Globally allow instructors to create courses',
            value: _permissions.allowInstructorsToCreateCourses,
            onChanged: (v) => _setPermission(
              PermissionKeys.allowInstructorsToCreateCourses,
              v,
            ),
          ),
          _ToggleTile(
            label: 'Require Review Before AI Content Is Published',
            subtitle:
                'AI-generated quizzes and assignments must be reviewed before students can access them',
            value: _permissions.requireReviewBeforeAiContentPublished,
            onChanged: (v) => _setPermission(
              PermissionKeys.requireReviewBeforeAiContentPublished,
              v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSummary() {
    final studentOn = [
      _permissions.downloadMaterials,
      _permissions.takeQuizzes,
      _permissions.submitAssignments,
      _permissions.viewCourseStudentList,
    ].where((value) => value).length;
    final instructorOn = _permissions.enabledInstructorCount;

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
          Text('Permission Summary', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          _SummaryRow(
            icon: Icons.school_rounded,
            color: AppColors.cyan,
            bg: AppColors.cyanLight,
            role: 'Students',
            enabled: studentOn,
            total: 4,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.menu_book_rounded,
            color: AppColors.violet,
            bg: AppColors.violetLight,
            role: 'Instructors',
            enabled: instructorOn,
            total: _permissions.instructorValues.length,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final String role;
  final int enabled, total;

  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.bg,
    required this.role,
    required this.enabled,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(role, style: AppTextStyles.label),
                  const Spacer(),
                  Text('$enabled / $total',
                      style: AppTextStyles.caption
                          .copyWith(color: color, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: enabled / total,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
      ),
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
          Divider(color: AppColors.border, height: 1),
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

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
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
                  style: AppTextStyles.label,
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}
