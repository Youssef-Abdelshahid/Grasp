import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminPermissionsPage extends StatefulWidget {
  const AdminPermissionsPage({super.key});

  @override
  State<AdminPermissionsPage> createState() => _AdminPermissionsPageState();
}

class _AdminPermissionsPageState extends State<AdminPermissionsPage> {
  bool _studentCanDownload = true;
  bool _studentCanMessage = false;
  bool _studentCanRateCourse = true;
  bool _studentCanViewPeers = false;
  bool _studentCanShareContent = false;

  bool _instructorCanPublish = false;
  bool _instructorCanViewAllStudents = false;
  bool _instructorCanUseAi = true;
  bool _instructorCanCreateCourses = true;
  bool _instructorCanExportData = false;

  bool _adminApprovalRequired = true;
  bool _rolesLocked = false;

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
              ],
            ),
    );
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
            subtitle: 'Students can download lecture files and resources',
            value: _studentCanDownload,
            onChanged: (v) => setState(() => _studentCanDownload = v),
          ),
          _ToggleTile(
            label: 'Message Instructors',
            subtitle: 'Direct messaging between students and instructors',
            value: _studentCanMessage,
            onChanged: (v) => setState(() => _studentCanMessage = v),
          ),
          _ToggleTile(
            label: 'Rate Courses',
            subtitle: 'Students can leave ratings and written feedback',
            value: _studentCanRateCourse,
            onChanged: (v) => setState(() => _studentCanRateCourse = v),
          ),
          _ToggleTile(
            label: 'View Peer Profiles',
            subtitle: 'Browse other enrolled students in the same course',
            value: _studentCanViewPeers,
            onChanged: (v) => setState(() => _studentCanViewPeers = v),
          ),
          _ToggleTile(
            label: 'Share Content',
            subtitle: 'Students can share resources with classmates',
            value: _studentCanShareContent,
            onChanged: (v) => setState(() => _studentCanShareContent = v),
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
            label: 'Create Courses',
            subtitle: 'Instructors can create and structure new courses',
            value: _instructorCanCreateCourses,
            onChanged: (v) =>
                setState(() => _instructorCanCreateCourses = v),
          ),
          _ToggleTile(
            label: 'Publish Without Review',
            subtitle: 'Bypass admin approval for course content publishing',
            value: _instructorCanPublish,
            onChanged: (v) => setState(() => _instructorCanPublish = v),
            dangerColor: true,
          ),
          _ToggleTile(
            label: 'Use AI Generation Tools',
            subtitle: 'Quizzes, assignments, and content generation',
            value: _instructorCanUseAi,
            onChanged: (v) => setState(() => _instructorCanUseAi = v),
          ),
          _ToggleTile(
            label: 'View All Student Data',
            subtitle:
                'Access analytics beyond personally enrolled students',
            value: _instructorCanViewAllStudents,
            onChanged: (v) =>
                setState(() => _instructorCanViewAllStudents = v),
          ),
          _ToggleTile(
            label: 'Export Data',
            subtitle: 'Download course rosters and analytics reports',
            value: _instructorCanExportData,
            onChanged: (v) =>
                setState(() => _instructorCanExportData = v),
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
            label: 'Admin Approval for Role Changes',
            subtitle:
                'Require admin sign-off when users request role upgrades',
            value: _adminApprovalRequired,
            onChanged: (v) => setState(() => _adminApprovalRequired = v),
          ),
          _ToggleTile(
            label: 'Lock Role Assignments',
            subtitle:
                'Prevent automated or self-service role changes',
            value: _rolesLocked,
            onChanged: (v) => setState(() => _rolesLocked = v),
            dangerColor: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSummary() {
    final studentOn = [
      _studentCanDownload,
      _studentCanMessage,
      _studentCanRateCourse,
      _studentCanViewPeers,
      _studentCanShareContent
    ].where((v) => v).length;
    final instructorOn = [
      _instructorCanPublish,
      _instructorCanViewAllStudents,
      _instructorCanUseAi,
      _instructorCanCreateCourses,
      _instructorCanExportData
    ].where((v) => v).length;

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
            total: 5,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.menu_book_rounded,
            color: AppColors.violet,
            bg: AppColors.violetLight,
            role: 'Instructors',
            enabled: instructorOn,
            total: 5,
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
