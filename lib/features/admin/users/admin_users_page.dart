import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/app_role.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/user_utils.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../features/platform_settings/providers/platform_settings_provider.dart';
import '../../../models/admin_models.dart';
import '../../../models/platform_settings_model.dart';
import '../../../services/admin_service.dart';
import '../../../services/auth_service.dart';
import 'admin_user_detail_page.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  AppRole? _roleFilter;
  AdminAccountStatus? _statusFilter;
  Future<List<AdminUser>>? _usersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    setState(() {
      _usersFuture = AdminService.instance.listUsers(
        search: _searchController.text,
        role: _roleFilter,
        status: _statusFilter,
      );
    });
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadUsers);
  }

  Future<void> _openDetail(AdminUser user) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminUserDetailPage(userId: user.id)),
    );
    if (changed == true && mounted) {
      _loadUsers();
    }
  }

  Future<void> _openCreateUser() async {
    final settings = ref.read(platformSettingsProvider).valueOrDefaults;
    if (!settings.adminUserCreationEnabled) {
      _showSnackBar('Admin user creation is currently disabled.', isError: true);
      return;
    }
    final message = await _showCreateUserSheet();
    if (message == null || !mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }
    _loadUsers();
    _showSnackBar(message);
  }

  Future<void> _toggleStatus(AdminUser user) async {
    final newStatus = user.status == AdminAccountStatus.active
        ? AdminAccountStatus.suspended
        : AdminAccountStatus.active;

    try {
      await AdminService.instance.updateUser(
        userId: user.id,
        status: newStatus,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('${user.name} is now ${newStatus.label.toLowerCase()}');
      _loadUsers();
    } catch (error) {
      _showSnackBar(error.toString(), isError: true);
    }
  }

  Future<void> _removeUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove User'),
        content: Text(
          'Remove ${user.name} from the admin user list? This keeps audit history and marks the account as removed.',
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
      _showSnackBar('${user.name} removed');
      _loadUsers();
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return FutureBuilder<List<AdminUser>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        final users = snapshot.data ?? const <AdminUser>[];
        final isLoading = snapshot.connectionState != ConnectionState.done;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(users.length, isLoading),
              const SizedBox(height: 20),
              _buildSearchAndFilter(),
              const SizedBox(height: 16),
              if (snapshot.hasError)
                _ErrorState(onRetry: _loadUsers)
              else if (isLoading && users.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (users.isEmpty)
                _buildEmptyState()
              else if (isWide)
                _buildTable(users)
              else
                _buildCardList(users),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(int count, bool isLoading) {
    final platformSettings = ref.watch(platformSettingsProvider).valueOrDefaults;
    final canCreate = platformSettings.adminUserCreationEnabled;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Users', style: AppTextStyles.h1),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Manage real platform users, roles, and access',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: isLoading ? null : _loadUsers,
          icon: Icon(Icons.refresh_rounded, size: 18),
          tooltip: 'Refresh users',
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: isLoading || !canCreate ? null : _openCreateUser,
          icon: Icon(Icons.person_add_rounded, size: 16),
          label: const Text('Create User'),
        ),
      ],
    );
  }

  Future<String?> _showCreateUserSheet() {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final phone = TextEditingController();
    final department = TextEditingController();
    var role = AppRole.student;
    var status = AdminAccountStatus.active;
    var obscurePassword = true;
    var isSubmitting = false;
    String? formError;

    return showModalBottomSheet<String>(
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
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create User', style: AppTextStyles.h2),
                  if (formError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        formError!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _CreateUserField(
                    label: 'Full Name',
                    child: TextFormField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      validator: (value) => _required(value, 'Full name'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CreateUserField(
                    label: 'Email',
                    child: TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _emailError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CreateUserField(
                    label: 'Temporary Password',
                    child: TextFormField(
                      controller: password,
                      obscureText: obscurePassword,
                      validator: (value) => _passwordError(
                        value,
                        ref.read(platformSettingsProvider).valueOrDefaults,
                      ),
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () => setSheet(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final narrow = constraints.maxWidth < 440;
                      final roleField = _CreateUserField(
                        label: 'Role',
                        child: DropdownButtonFormField<AppRole>(
                          initialValue: role,
                          items: AppRole.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setSheet(() => role = value ?? role),
                        ),
                      );
                      final statusField = _CreateUserField(
                        label: 'Status',
                        child: DropdownButtonFormField<AdminAccountStatus>(
                          initialValue: status,
                          items:
                              const [
                                    AdminAccountStatus.active,
                                    AdminAccountStatus.inactive,
                                    AdminAccountStatus.suspended,
                                  ]
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item.label),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) =>
                              setSheet(() => status = value ?? status),
                        ),
                      );
                      if (narrow) {
                        return Column(
                          children: [
                            roleField,
                            const SizedBox(height: 12),
                            statusField,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: roleField),
                          const SizedBox(width: 12),
                          Expanded(child: statusField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _CreateUserField(
                    label: 'Phone',
                    child: TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CreateUserField(
                    label: 'Department',
                    child: TextFormField(controller: department),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  var closed = false;
                                  setSheet(() {
                                    formError = null;
                                    isSubmitting = true;
                                  });
                                  try {
                                    final created = await AdminService.instance
                                        .createUser(
                                          fullName: name.text,
                                          email: email.text,
                                          temporaryPassword: password.text,
                                          role: role,
                                          status: status,
                                          phone: phone.text,
                                          department: department.text,
                                        );
                                    if (!ctx.mounted) return;
                                    closed = true;
                                    Navigator.pop(
                                      ctx,
                                      '${created.name} created as ${created.roleLabel.toLowerCase()}',
                                    );
                                  } catch (error) {
                                    if (ctx.mounted) {
                                      setSheet(
                                        () => formError =
                                            _friendlyCreateUserError(error),
                                      );
                                    }
                                  } finally {
                                    if (!closed && ctx.mounted) {
                                      setSheet(() => isSubmitting = false);
                                    }
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        name.dispose();
        email.dispose();
        password.dispose();
        phone.dispose();
        department.dispose();
      });
    });
  }

  Widget _buildSearchAndFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _loadUsers();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'All Roles',
              selected: _roleFilter == null,
              onTap: () {
                _roleFilter = null;
                _loadUsers();
              },
            ),
            ...AppRole.values.map(
              (role) => _FilterChip(
                label: role.label,
                selected: _roleFilter == role,
                onTap: () {
                  _roleFilter = role;
                  _loadUsers();
                },
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'All Statuses',
              selected: _statusFilter == null,
              onTap: () {
                _statusFilter = null;
                _loadUsers();
              },
            ),
            ...[
              AdminAccountStatus.active,
              AdminAccountStatus.inactive,
              AdminAccountStatus.suspended,
            ].map(
              (status) => _FilterChip(
                label: status.label,
                selected: _statusFilter == status,
                onTap: () {
                  _statusFilter = status;
                  _loadUsers();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable(List<AdminUser> users) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Divider(height: 1, color: AppColors.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) => _buildTableRow(users[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _HeaderCell('User', flex: 3),
          _HeaderCell('Role', flex: 2),
          _HeaderCell('Status'),
          _HeaderCell('Joined', flex: 2),
          SizedBox(width: 120, child: _headerText('Actions')),
        ],
      ),
    );
  }

  Widget _buildTableRow(AdminUser user) {
    final roleColor = _roleColor(user.role);
    final roleBg = _roleBg(user.role);
    final statusColor = _statusColor(user.status);
    final statusBg = _statusBg(user.status);
    final isSelf = user.id == AuthService.instance.currentUser?.id;

    return InkWell(
      onTap: () => _openDetail(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  AppAvatar(
                    radius: 16,
                    avatarUrl: user.avatarUrl,
                    initials: UserUtils.initials(user.name),
                    backgroundColor: roleBg,
                    textColor: roleColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTextStyles.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _Badge(
                label: user.roleLabel,
                color: roleColor,
                bg: roleBg,
              ),
            ),
            Expanded(
              child: _Badge(
                label: user.statusLabel,
                color: statusColor,
                bg: statusBg,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                user.joinedLabel,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 120,
              child: _RowActions(
                user: user,
                disableDangerousActions: isSelf,
                onView: () => _openDetail(user),
                onStatusToggle: () => _toggleStatus(user),
                onDelete: () => _removeUser(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(List<AdminUser> users) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildUserCard(users[i]),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final roleColor = _roleColor(user.role);
    final roleBg = _roleBg(user.role);
    final statusColor = _statusColor(user.status);
    final statusBg = _statusBg(user.status);
    final isSelf = user.id == AuthService.instance.currentUser?.id;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openDetail(user),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AppAvatar(
                    radius: 22,
                    avatarUrl: user.avatarUrl,
                    initials: UserUtils.initials(user.name),
                    backgroundColor: roleBg,
                    textColor: roleColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTextStyles.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Badge(
                        label: user.roleLabel,
                        color: roleColor,
                        bg: roleBg,
                      ),
                      const SizedBox(height: 4),
                      _Badge(
                        label: user.statusLabel,
                        color: statusColor,
                        bg: statusBg,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Joined ${user.joinedLabel}',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  _RowActions(
                    user: user,
                    disableDangerousActions: isSelf,
                    onView: () => _openDetail(user),
                    onStatusToggle: () => _toggleStatus(user),
                    onDelete: () => _removeUser(user),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text('No users found', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  String? _emailError(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
    if (!valid) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _passwordError(String? value, PlatformSettingsConfig settings) {
    if (value == null || value.isEmpty) {
      return 'Temporary password is required.';
    }
    if (settings.requireStrongPasswords) {
      if (value.length < 8 ||
          !RegExp('[A-Z]').hasMatch(value) ||
          !RegExp('[a-z]').hasMatch(value) ||
          !RegExp('[0-9]').hasMatch(value) ||
          !RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
        return 'Use uppercase, lowercase, number, and special character.';
      }
    } else if (value.length < 6) {
      return 'Temporary password must be at least 6 characters.';
    }
    return null;
  }

  String _friendlyCreateUserError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('AdminServiceException')) {
      return message.replaceFirst('AdminServiceException: ', '');
    }
    if (message.toLowerCase().contains('already')) {
      return 'A user with this email already exists.';
    }
    if (message.toLowerCase().contains('password')) {
      return 'Temporary password does not meet the required rules.';
    }
    return message.isEmpty ? 'User account could not be created.' : message;
  }
}

class _CreateUserField extends StatelessWidget {
  const _CreateUserField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: _headerText(label));
  }
}

Widget _headerText(String label) {
  return Text(
    label,
    style: AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    ),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
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

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.user,
    required this.disableDangerousActions,
    required this.onView,
    required this.onStatusToggle,
    required this.onDelete,
  });

  final AdminUser user;
  final bool disableDangerousActions;
  final VoidCallback onView;
  final VoidCallback onStatusToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = user.status == AdminAccountStatus.active;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBtn(
          icon: Icons.visibility_rounded,
          color: AppColors.primary,
          tooltip: 'View',
          onTap: onView,
        ),
        _IconBtn(
          icon: isActive ? Icons.block_rounded : Icons.check_circle_rounded,
          color: isActive ? AppColors.amber : AppColors.success,
          tooltip: isActive ? 'Suspend' : 'Activate',
          onTap: disableDangerousActions ? null : onStatusToggle,
        ),
        _IconBtn(
          icon: Icons.delete_rounded,
          color: AppColors.error,
          tooltip: disableDangerousActions
              ? 'Cannot remove yourself'
              : 'Remove',
          onTap: disableDangerousActions ? null : onDelete,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 36,
        height: 36,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: onTap == null ? AppColors.textMuted : color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text('Failed to load users', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
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

Color _roleBg(AppRole role) {
  switch (role) {
    case AppRole.instructor:
      return AppColors.violetLight;
    case AppRole.admin:
      return AppColors.roseLight;
    case AppRole.student:
      return AppColors.cyanLight;
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
