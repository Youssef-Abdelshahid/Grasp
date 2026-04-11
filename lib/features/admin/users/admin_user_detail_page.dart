import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminUserDetailPage extends StatefulWidget {
  final String name;
  final String email;
  final String role;
  final String status;
  final String joined;
  final Color roleColor;
  final Color roleBg;

  const AdminUserDetailPage({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joined,
    required this.roleColor,
    required this.roleBg,
  });

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  late String _status;
  late String _role;
  late String _displayName;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _role = widget.role;
    _displayName = widget.name;
  }

  String get _initials =>
      _displayName.split(' ').map((w) => w[0]).take(2).join();

  Color get _roleColor =>
      _role == 'Instructor' ? AppColors.violet : AppColors.cyan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildInfoSection(),
            const SizedBox(height: 20),
            _buildActivityStats(),
            const SizedBox(height: 20),
            _buildCourseActivity(),
            const SizedBox(height: 20),
            _buildActivityHistory(),
            const SizedBox(height: 20),
            _buildActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: const BackButton(color: AppColors.textPrimary),
      title: Text('User Details', style: AppTextStyles.h2),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded,
              color: AppColors.textSecondary, size: 20),
          onPressed: _showEditUserSheet,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildProfileCard() {
    final isActive = _status == 'Active';
    final statusColor = isActive ? AppColors.success : AppColors.error;
    final statusBg = isActive ? AppColors.successLight : AppColors.errorLight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _roleColor.withValues(alpha: 0.9),
            _roleColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              _initials,
              style: AppTextStyles.h2.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName,
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(widget.email,
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(_role,
                          style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(_status,
                          style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600)),
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

  Widget _buildInfoSection() {
    final dept =
        _role == 'Instructor' ? 'Computer Science' : 'Engineering · CS';
    return _Card(
      title: 'Account Information',
      icon: Icons.info_rounded,
      iconColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      child: Column(
        children: [
          _InfoRow(label: 'Full Name', value: _displayName),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Email Address', value: widget.email),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Role', value: _role),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Account Status', value: _status),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Joined', value: widget.joined),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Last Active', value: '2 hours ago'),
          const Divider(height: 20, color: AppColors.border),
          _InfoRow(label: 'Department', value: dept),
        ],
      ),
    );
  }

  Widget _buildActivityStats() {
    final isInstructor = _role == 'Instructor';

    final stats = isInstructor
        ? [
            (
              label: 'Courses',
              value: '4',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              icon: Icons.menu_book_rounded
            ),
            (
              label: 'Students',
              value: '86',
              color: AppColors.cyan,
              bg: AppColors.cyanLight,
              icon: Icons.people_rounded
            ),
            (
              label: 'Avg Score',
              value: '81%',
              color: AppColors.emerald,
              bg: AppColors.emeraldLight,
              icon: Icons.insights_rounded
            ),
          ]
        : [
            (
              label: 'Enrolled',
              value: '5',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              icon: Icons.menu_book_rounded
            ),
            (
              label: 'Avg Score',
              value: '74%',
              color: AppColors.emerald,
              bg: AppColors.emeraldLight,
              icon: Icons.insights_rounded
            ),
            (
              label: 'Submitted',
              value: '12',
              color: AppColors.violet,
              bg: AppColors.violetLight,
              icon: Icons.assignment_turned_in_rounded
            ),
          ];

    return _Card(
      title: 'Activity Summary',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.violet,
      iconBg: AppColors.violetLight,
      child: Row(
        children: stats
            .map((s) => Expanded(
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
                      Text(s.value,
                          style: AppTextStyles.h2.copyWith(
                              color: s.color,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(s.label, style: AppTextStyles.caption),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCourseActivity() {
    final isInstructor = _role == 'Instructor';

    final items = isInstructor
        ? [
            (
              title: 'Mobile Development · CS401',
              sub: '32 students enrolled',
              color: AppColors.primary
            ),
            (
              title: 'Machine Learning · CS310',
              sub: '28 students enrolled',
              color: AppColors.cyan
            ),
            (
              title: 'Database Systems · CS302',
              sub: '26 students enrolled',
              color: AppColors.emerald
            ),
          ]
        : [
            (
              title: 'Mobile Development · CS401',
              sub: 'Score: 82% · 3 assignments',
              color: AppColors.primary
            ),
            (
              title: 'Machine Learning · CS310',
              sub: 'Score: 71% · 2 quizzes done',
              color: AppColors.cyan
            ),
            (
              title: 'Database Systems · CS302',
              sub: 'Score: 79% · In progress',
              color: AppColors.emerald
            ),
          ];

    return _Card(
      title: isInstructor ? 'Teaching' : 'Enrolled Courses',
      icon: Icons.menu_book_rounded,
      iconColor: AppColors.emerald,
      iconBg: AppColors.emeraldLight,
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: AppTextStyles.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(item.sub,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildActivityHistory() {
    final isInstructor = _role == 'Instructor';

    final activities = isInstructor
        ? [
            (
              icon: Icons.login_rounded,
              label: 'Logged in',
              sub: 'Web · Chrome on Windows',
              time: '2 hours ago',
              color: AppColors.primary
            ),
            (
              icon: Icons.auto_awesome_rounded,
              label: 'Generated AI Quiz',
              sub: 'Mobile Dev · CS401',
              time: '5 hours ago',
              color: AppColors.violet
            ),
            (
              icon: Icons.upload_file_rounded,
              label: 'Uploaded Lecture Material',
              sub: 'Machine Learning · Week 8',
              time: '1 day ago',
              color: AppColors.emerald
            ),
            (
              icon: Icons.quiz_rounded,
              label: 'Published Quiz 5',
              sub: 'Database Systems · CS302',
              time: '2 days ago',
              color: AppColors.cyan
            ),
            (
              icon: Icons.person_add_rounded,
              label: 'Account Created',
              sub: 'System registration',
              time: widget.joined,
              color: AppColors.amber
            ),
          ]
        : [
            (
              icon: Icons.login_rounded,
              label: 'Logged in',
              sub: 'Mobile · iOS App',
              time: '2 hours ago',
              color: AppColors.primary
            ),
            (
              icon: Icons.assignment_turned_in_rounded,
              label: 'Submitted Assignment 3',
              sub: 'Mobile Dev · CS401',
              time: '1 day ago',
              color: AppColors.violet
            ),
            (
              icon: Icons.quiz_rounded,
              label: 'Completed Quiz 2',
              sub: 'Machine Learning · Score: 85%',
              time: '2 days ago',
              color: AppColors.emerald
            ),
            (
              icon: Icons.menu_book_rounded,
              label: 'Viewed Lecture 7',
              sub: 'Database Systems · CS302',
              time: '3 days ago',
              color: AppColors.cyan
            ),
            (
              icon: Icons.person_add_rounded,
              label: 'Account Created',
              sub: 'System registration',
              time: widget.joined,
              color: AppColors.amber
            ),
          ];

    return _Card(
      title: 'Activity History',
      icon: Icons.history_rounded,
      iconColor: AppColors.amber,
      iconBg: AppColors.amberLight,
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          final isLast = i == activities.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, size: 13, color: a.color),
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
                            Text(a.label, style: AppTextStyles.label),
                            const SizedBox(height: 1),
                            Text(a.sub, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(a.time,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
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

  Widget _buildActions() {
    final isActive = _status == 'Active';

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
            subtitle: 'Update name, email or role',
            color: AppColors.primary,
            onTap: _showEditUserSheet,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon:
                isActive ? Icons.block_rounded : Icons.check_circle_rounded,
            label: isActive ? 'Suspend Account' : 'Activate Account',
            subtitle: isActive
                ? 'Prevent user from logging in'
                : 'Restore user access',
            color: isActive ? AppColors.amber : AppColors.success,
            onTap: () {
              final newStatus = isActive ? 'Suspended' : 'Active';
              setState(() => _status = newStatus);
              _showSnackBar(
                  isActive ? 'Account suspended' : 'Account activated');
            },
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Change Role',
            subtitle: 'Switch between Student and Instructor',
            color: AppColors.violet,
            onTap: _showChangeRoleDialog,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: Icons.lock_reset_rounded,
            label: 'Reset Password',
            subtitle: 'Send a password reset link to user',
            color: AppColors.cyan,
            onTap: _showResetPasswordDialog,
          ),
          const Divider(height: 1, color: AppColors.border),
          _ActionTile(
            icon: Icons.delete_rounded,
            label: 'Delete Account',
            subtitle: 'Permanently remove this user',
            color: AppColors.error,
            onTap: _showDeleteDialog,
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showEditUserSheet() {
    final nameCtrl = TextEditingController(text: _displayName);
    final emailCtrl = TextEditingController(text: widget.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Edit User', style: AppTextStyles.h2),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text('Update account details for ${widget.name}.',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 22),
            Text('Full Name', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Enter full name',
                prefixIcon: Icon(Icons.person_rounded,
                    size: 18, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            Text('Email Address', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Enter email address',
                prefixIcon: Icon(Icons.email_rounded,
                    size: 18, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final trimmed = nameCtrl.text.trim();
                      if (trimmed.isNotEmpty) {
                        setState(() => _displayName = trimmed);
                      }
                      Navigator.pop(ctx);
                      _showSnackBar('User updated successfully');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog() {
    String selected = _role;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select a new role for $_displayName.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 14),
              _RoleOption(
                label: 'Student',
                subtitle: 'Can enroll in courses and submit work',
                icon: Icons.school_rounded,
                color: AppColors.cyan,
                bg: AppColors.cyanLight,
                selected: selected == 'Student',
                onTap: () => setDlg(() => selected = 'Student'),
              ),
              const SizedBox(height: 8),
              _RoleOption(
                label: 'Instructor',
                subtitle: 'Can create courses and use AI tools',
                icon: Icons.menu_book_rounded,
                color: AppColors.violet,
                bg: AppColors.violetLight,
                selected: selected == 'Instructor',
                onTap: () => setDlg(() => selected = 'Instructor'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _role = selected);
                Navigator.pop(context);
                _showSnackBar('Role changed to $selected');
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.cyanLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppColors.cyan, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'A password reset link will be sent to:',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              style: AppTextStyles.label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Reset link sent to ${widget.email}');
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
            'Are you sure you want to permanently delete $_displayName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.label
                          .copyWith(color: selected ? color : AppColors.textPrimary)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;

  const _Card({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

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
                    color: iconBg, borderRadius: BorderRadius.circular(8)),
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
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: AppTextStyles.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      title: Text(label, style: AppTextStyles.label),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: const Icon(Icons.chevron_right_rounded,
          size: 16, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
