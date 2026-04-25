import 'package:flutter/material.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/user_utils.dart';
import '../../../models/admin_models.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  late Future<AdminUserDetail> _detailFuture;
  AdminUserDetail? _detail;
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    _detailFuture = AdminService.instance.getUserDetail(widget.userId);
  }

  Future<void> _refresh() async {
    setState(_loadDetail);
  }

  Future<void> _updateUser({
    String? fullName,
    AppRole? role,
    AdminAccountStatus? status,
    String? department,
    String? phone,
  }) async {
    setState(() => _saving = true);
    try {
      final updated = await AdminService.instance.updateUser(
        userId: widget.userId,
        fullName: fullName,
        role: role,
        status: status,
        department: department,
        phone: phone,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = updated;
        _detailFuture = Future.value(updated);
        _saving = false;
        _changed = true;
      });
      _showSnackBar('User updated');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _removeUser() async {
    final user = _detail?.user;
    if (user == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text(
          'Remove ${user.name}? This marks the account as removed and keeps admin history intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await AdminService.instance.removeUser(user.id);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      _showSnackBar(error.toString(), isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool get _isSelf => widget.userId == AuthService.instance.currentUser?.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context, _changed),
        ),
        title: Text('User Details', style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: _detail == null || _saving ? null : _showEditUserSheet,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: FutureBuilder<AdminUserDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              _detail == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _detail == null) {
            return _ErrorState(onRetry: _refresh);
          }

          _detail = snapshot.data ?? _detail;
          final detail = _detail!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(detail.user),
                const SizedBox(height: 20),
                _buildInfoSection(detail.user),
                const SizedBox(height: 20),
                _buildActivityStats(detail.user),
                const SizedBox(height: 20),
                _buildCourseActivity(detail),
                const SizedBox(height: 20),
                _buildActivityHistory(detail),
                const SizedBox(height: 20),
                _buildActions(detail.user),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(AdminUser user) {
    final roleColor = _roleColor(user.role);
    final statusColor = _statusColor(user.status);
    final statusBg = _statusBg(user.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [roleColor.withValues(alpha: 0.9), roleColor],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              UserUtils.initials(user.name),
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: user.roleLabel, color: Colors.white),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        user.statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(AdminUser user) {
    return _Card(
      title: 'Account Information',
      icon: Icons.info_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      child: Column(
        children: [
          _InfoRow(label: 'Full Name', value: user.name),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Email Address', value: user.email),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Role', value: user.roleLabel),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Account Status', value: user.statusLabel),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Joined', value: user.joinedLabel),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Last Active', value: user.lastActiveLabel),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(
            label: 'Department',
            value: user.department.isEmpty ? 'Not set' : user.department,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStats(AdminUser user) {
    final courseLabel = user.role == AppRole.instructor
        ? 'Teaching'
        : 'Courses';

    final stats = [
      (
        label: courseLabel,
        value: '${user.coursesCount}',
        color: AppColors.primary,
        bg: AppColors.primaryLight,
        icon: Icons.menu_book_rounded,
      ),
      (
        label: 'Submissions',
        value: '${user.submissionsCount}',
        color: AppColors.emerald,
        bg: AppColors.emeraldLight,
        icon: Icons.assignment_turned_in_rounded,
      ),
      (
        label: 'Admin Actions',
        value: '${user.adminActionsCount}',
        color: AppColors.violet,
        bg: AppColors.violetLight,
        icon: Icons.history_rounded,
      ),
    ];

    return _Card(
      title: 'Activity Summary',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.violet,
      iconBg: AppColors.violetLight,
      child: Row(
        children: stats
            .map(
              (s) => Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: s.bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.value,
                      style: AppTextStyles.h2.copyWith(
                        color: s.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(s.label, style: AppTextStyles.caption),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCourseActivity(AdminUserDetail detail) {
    final user = detail.user;
    final title = user.role == AppRole.instructor
        ? 'Teaching'
        : 'Enrolled Courses';

    return _Card(
      title: title,
      icon: Icons.menu_book_rounded,
      iconColor: AppColors.emerald,
      iconBg: AppColors.emeraldLight,
      child: detail.courses.isEmpty
          ? Text('No related courses yet.', style: AppTextStyles.bodySmall)
          : Column(
              children: detail.courses.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.subtitle,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildActivityHistory(AdminUserDetail detail) {
    return _Card(
      title: 'Activity History',
      icon: Icons.history_rounded,
      iconColor: AppColors.amber,
      iconBg: AppColors.amberLight,
      child: detail.activity.isEmpty
          ? Text('No activity recorded yet.', style: AppTextStyles.bodySmall)
          : Column(
              children: detail.activity.asMap().entries.map((entry) {
                final i = entry.key;
                final activity = entry.value;
                final isLast = i == detail.activity.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.circle_rounded,
                            size: 8,
                            color: AppColors.amber,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 1.5,
                            height: 28,
                            color: AppColors.border,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.title,
                                    style: AppTextStyles.label,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    activity.subtitle,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              activity.timestampLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildActions(AdminUser user) {
    final isActive = user.status == AdminAccountStatus.active;

    return _Card(
      title: 'Account Actions',
      icon: Icons.admin_panel_settings_rounded,
      iconColor: AppColors.rose,
      iconBg: AppColors.roseLight,
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.edit_rounded,
            label: 'Edit User',
            subtitle: 'Update name, phone, department, role, or status',
            color: AppColors.primary,
            onTap: _saving ? null : _showEditUserSheet,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: isActive ? Icons.block_rounded : Icons.check_circle_rounded,
            label: isActive ? 'Suspend Account' : 'Activate Account',
            subtitle: isActive ? 'Prevent app access' : 'Restore app access',
            color: isActive ? AppColors.amber : AppColors.success,
            onTap: _isSelf || _saving
                ? null
                : () => _updateUser(
                    status: isActive
                        ? AdminAccountStatus.suspended
                        : AdminAccountStatus.active,
                  ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Change Role',
            subtitle: 'Switch between student, instructor, and admin',
            color: AppColors.violet,
            onTap: _saving ? null : _showChangeRoleDialog,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: Icons.delete_rounded,
            label: 'Remove Account',
            subtitle: _isSelf
                ? 'You cannot remove yourself'
                : 'Soft-remove this user',
            color: AppColors.error,
            onTap: _isSelf || _saving ? null : _removeUser,
          ),
        ],
      ),
    );
  }

  void _showEditUserSheet() {
    final user = _detail!.user;
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final departmentCtrl = TextEditingController(text: user.department);
    var selectedRole = user.role;
    var selectedStatus = user.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit User', style: AppTextStyles.h2),
                const SizedBox(height: 18),
                _SheetTextField(label: 'Full Name', controller: nameCtrl),
                const SizedBox(height: 14),
                _SheetTextField(
                  label: 'Phone',
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _SheetTextField(
                  label: 'Department',
                  controller: departmentCtrl,
                ),
                const SizedBox(height: 14),
                Text('Role', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppRole.values.map((role) {
                    return ChoiceChip(
                      label: Text(role.label),
                      selected: selectedRole == role,
                      onSelected: (_) => setSheet(() => selectedRole = role),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('Status', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        AdminAccountStatus.active,
                        AdminAccountStatus.inactive,
                        AdminAccountStatus.suspended,
                      ].map((status) {
                        return ChoiceChip(
                          label: Text(status.label),
                          selected: selectedStatus == status,
                          onSelected: (_) =>
                              setSheet(() => selectedStatus = status),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _updateUser(
                            fullName: nameCtrl.text,
                            phone: phoneCtrl.text,
                            department: departmentCtrl.text,
                            role: selectedRole,
                            status: selectedStatus,
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeRoleDialog() {
    var selected = _detail!.user.role;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppRole.values.map((role) {
              final isSelected = selected == role;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                title: Text(role.label),
                onTap: () => setDlg(() => selected = role),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateUser(role: selected);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
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

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

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
          decoration: InputDecoration(hintText: label),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      enabled: onTap != null,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppColors.textMuted : color,
          size: 16,
        ),
      ),
      title: Text(label, style: AppTextStyles.label),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 16,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 36),
          const SizedBox(height: 12),
          Text('Failed to load user details', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

Color _roleColor(AppRole role) {
  switch (role) {
    case AppRole.instructor:
      return AppColors.violet;
    case AppRole.admin:
      return AppColors.rose;
    case AppRole.student:
      return AppColors.cyan;
  }
}

Color _statusColor(AdminAccountStatus status) {
  switch (status) {
    case AdminAccountStatus.active:
      return AppColors.success;
    case AdminAccountStatus.suspended:
      return AppColors.error;
    case AdminAccountStatus.inactive:
      return AppColors.textMuted;
    case AdminAccountStatus.removed:
      return AppColors.error;
  }
}

Color _statusBg(AdminAccountStatus status) {
  switch (status) {
    case AdminAccountStatus.active:
      return AppColors.successLight;
    case AdminAccountStatus.suspended:
      return AppColors.errorLight;
    case AdminAccountStatus.inactive:
      return AppColors.background;
    case AdminAccountStatus.removed:
      return AppColors.errorLight;
  }
}
