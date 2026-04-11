import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'admin_user_detail_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  int _filterIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _filters = ['All', 'Students', 'Instructors', 'Active', 'Suspended'];

  static final _allUsers = [
    _User(name: 'Ahmed Hassan', email: 'ahmed.hassan@student.edu', role: 'Student', status: 'Active', joined: 'Jan 15, 2025'),
    _User(name: 'Dr. Ahmed Ali', email: 'ahmed.ali@faculty.edu', role: 'Instructor', status: 'Active', joined: 'Sep 1, 2024'),
    _User(name: 'Nada Omar', email: 'nada.omar@student.edu', role: 'Student', status: 'Active', joined: 'Jan 20, 2025'),
    _User(name: 'Khaled Ibrahim', email: 'k.ibrahim@student.edu', role: 'Student', status: 'Active', joined: 'Feb 1, 2025'),
    _User(name: 'Prof. Sara Mansour', email: 's.mansour@faculty.edu', role: 'Instructor', status: 'Active', joined: 'Aug 15, 2024'),
    _User(name: 'Yousef Adel', email: 'yousef.adel@student.edu', role: 'Student', status: 'Active', joined: 'Jan 10, 2025'),
    _User(name: 'Mona Hassan', email: 'mona.hassan@student.edu', role: 'Student', status: 'Suspended', joined: 'Feb 5, 2025'),
    _User(name: 'Dr. Mohammed Farid', email: 'm.farid@faculty.edu', role: 'Instructor', status: 'Active', joined: 'Oct 1, 2024'),
    _User(name: 'Layla Ahmad', email: 'layla.ahmad@student.edu', role: 'Student', status: 'Active', joined: 'Jan 25, 2025'),
    _User(name: 'Tarek Ali', email: 'tarek.ali@student.edu', role: 'Student', status: 'Inactive', joined: 'Dec 20, 2024'),
    _User(name: 'Fatima Zahra', email: 'fatima.z@student.edu', role: 'Student', status: 'Active', joined: 'Jan 5, 2025'),
    _User(name: 'Dr. Omar Hassan', email: 'o.hassan@faculty.edu', role: 'Instructor', status: 'Active', joined: 'Sep 15, 2024'),
  ];

  List<_User> get _filtered {
    var users = List<_User>.from(_allUsers);
    switch (_filterIndex) {
      case 1:
        users = users.where((u) => u.role == 'Student').toList();
      case 2:
        users = users.where((u) => u.role == 'Instructor').toList();
      case 3:
        users = users.where((u) => u.status == 'Active').toList();
      case 4:
        users = users.where((u) => u.status == 'Suspended').toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      users = users.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q)).toList();
    }
    return users;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddUserSheet() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'Student';
    bool nameError = false;
    bool emailError = false;

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
                  Text('Add User', style: AppTextStyles.h2),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text('Create a new user account on the platform.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 22),
              Text('Full Name', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (nameError) setSheet(() => nameError = false);
                },
                decoration: InputDecoration(
                  hintText: 'Enter full name',
                  prefixIcon: const Icon(Icons.person_rounded,
                      size: 18, color: AppColors.textMuted),
                  errorText: nameError ? 'Name is required' : null,
                ),
              ),
              const SizedBox(height: 14),
              Text('Email Address', style: AppTextStyles.label),
              const SizedBox(height: 6),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (emailError) setSheet(() => emailError = false);
                },
                decoration: InputDecoration(
                  hintText: 'Enter email address',
                  prefixIcon: const Icon(Icons.email_rounded,
                      size: 18, color: AppColors.textMuted),
                  errorText: emailError ? 'Email is required' : null,
                ),
              ),
              const SizedBox(height: 14),
              Text('Role', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Row(
                children: ['Student', 'Instructor'].map((role) {
                  final isSelected = selectedRole == role;
                  final color =
                      role == 'Instructor' ? AppColors.violet : AppColors.cyan;
                  final bg = role == 'Instructor'
                      ? AppColors.violetLight
                      : AppColors.cyanLight;
                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: role == 'Student' ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setSheet(() => selectedRole = role),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.08)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  role == 'Instructor'
                                      ? Icons.menu_book_rounded
                                      : Icons.school_rounded,
                                  size: 13,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(role,
                                  style: AppTextStyles.label.copyWith(
                                    color: isSelected
                                        ? color
                                        : AppColors.textPrimary,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                        final name = nameCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        setSheet(() {
                          nameError = name.isEmpty;
                          emailError = email.isEmpty;
                        });
                        if (name.isEmpty || email.isEmpty) return;
                        setState(() {
                          _allUsers.add(_User(
                            name: name,
                            email: email,
                            role: selectedRole,
                            status: 'Active',
                            joined: 'Apr 9, 2026',
                          ));
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text('$name added successfully'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Add User'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;
    final filtered = _filtered;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(filtered.length),
          const SizedBox(height: 20),
          _buildSearchAndFilter(),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            _buildEmptyState()
          else if (isWide)
            _buildTable(filtered)
          else
            _buildCardList(filtered),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Manage all platform users, roles, and access',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddUserSheet,
          icon: const Icon(Icons.person_add_rounded, size: 14),
          label: const Text('Add User'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
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
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 16, color: AppColors.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_filters.length, (i) {
              final isSelected = _filterIndex == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      _filters[i],
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<_User> users) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: AppColors.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
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
          Expanded(
            flex: 3,
            child: Text('User',
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 2,
            child: Text('Role',
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text('Status',
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 2,
            child: Text('Joined',
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          SizedBox(
            width: 110,
            child: Text('Actions',
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(_User user) {
    final roleColor =
        user.role == 'Instructor' ? AppColors.violet : AppColors.cyan;
    final roleBg =
        user.role == 'Instructor' ? AppColors.violetLight : AppColors.cyanLight;
    final statusColor = _statusColor(user.status);
    final statusBg = _statusBg(user.status);
    final initials =
        user.name.split(' ').map((w) => w[0]).take(2).join();

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
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: roleBg,
                    child: Text(initials,
                        style: AppTextStyles.caption
                            .copyWith(color: roleColor, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: AppTextStyles.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(user.email,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _Badge(
                  label: user.role, color: roleColor, bg: roleBg),
            ),
            Expanded(
              child: _Badge(
                  label: user.status, color: statusColor, bg: statusBg),
            ),
            Expanded(
              flex: 2,
              child: Text(user.joined,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              width: 110,
              child: _RowActions(
                user: user,
                onView: () => _openDetail(user),
                onStatusToggle: () => setState(() {
                  user.status =
                      user.status == 'Active' ? 'Suspended' : 'Active';
                }),
                onDelete: () => _showDeleteDialog(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(List<_User> users) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildUserCard(users[i]),
    );
  }

  Widget _buildUserCard(_User user) {
    final roleColor =
        user.role == 'Instructor' ? AppColors.violet : AppColors.cyan;
    final roleBg =
        user.role == 'Instructor' ? AppColors.violetLight : AppColors.cyanLight;
    final statusColor = _statusColor(user.status);
    final statusBg = _statusBg(user.status);
    final initials =
        user.name.split(' ').map((w) => w[0]).take(2).join();

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: roleBg,
                    child: Text(initials,
                        style: AppTextStyles.label.copyWith(
                            color: roleColor, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: AppTextStyles.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(user.email,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Badge(label: user.role, color: roleColor, bg: roleBg),
                      const SizedBox(height: 4),
                      _Badge(label: user.status, color: statusColor, bg: statusBg),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('Joined ${user.joined}',
                            style: AppTextStyles.caption),
                      ],
                    ),
                    _CardActions(
                      user: user,
                      onView: () => _openDetail(user),
                      onStatusToggle: () => setState(() {
                        user.status =
                            user.status == 'Active' ? 'Suspended' : 'Active';
                      }),
                      onDelete: () => _showDeleteDialog(user),
                    ),
                  ],
                ),
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
              decoration: const BoxDecoration(
                  color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.people_outline_rounded,
                  size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text('No users found', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text('Try adjusting your search or filters.',
                style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Suspended':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Active':
        return AppColors.successLight;
      case 'Suspended':
        return AppColors.errorLight;
      default:
        return AppColors.background;
    }
  }

  void _openDetail(_User user) {
    final roleColor =
        user.role == 'Instructor' ? AppColors.violet : AppColors.cyan;
    final roleBg =
        user.role == 'Instructor' ? AppColors.violetLight : AppColors.cyanLight;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailPage(
          name: user.name,
          email: user.email,
          role: user.role,
          status: user.status,
          joined: user.joined,
          roleColor: roleColor,
          roleBg: roleBg,
        ),
      ),
    );
  }

  void _showDeleteDialog(_User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _allUsers.remove(user));
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

class _User {
  final String name;
  final String email;
  final String role;
  String status;
  final String joined;

  _User({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joined,
  });
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(
        label,
        style: AppTextStyles.caption
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  final _User user;
  final VoidCallback onView;
  final VoidCallback onStatusToggle;
  final VoidCallback onDelete;

  const _RowActions({
    required this.user,
    required this.onView,
    required this.onStatusToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBtn(
            icon: Icons.visibility_rounded,
            color: AppColors.primary,
            tooltip: 'View',
            onTap: onView),
        _IconBtn(
          icon: user.status == 'Active'
              ? Icons.block_rounded
              : Icons.check_circle_rounded,
          color: user.status == 'Active' ? AppColors.amber : AppColors.success,
          tooltip: user.status == 'Active' ? 'Suspend' : 'Activate',
          onTap: onStatusToggle,
        ),
        _IconBtn(
            icon: Icons.delete_rounded,
            color: AppColors.error,
            tooltip: 'Delete',
            onTap: onDelete),
      ],
    );
  }
}

class _CardActions extends StatelessWidget {
  final _User user;
  final VoidCallback onView;
  final VoidCallback onStatusToggle;
  final VoidCallback onDelete;

  const _CardActions({
    required this.user,
    required this.onView,
    required this.onStatusToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallBtn(
            icon: Icons.visibility_rounded,
            color: AppColors.primary,
            bg: AppColors.primaryLight,
            label: 'View',
            onTap: onView),
        const SizedBox(width: 6),
        _SmallBtn(
          icon: user.status == 'Active'
              ? Icons.block_rounded
              : Icons.check_circle_rounded,
          color: user.status == 'Active' ? AppColors.amber : AppColors.success,
          bg: user.status == 'Active'
              ? AppColors.amberLight
              : AppColors.successLight,
          label: user.status == 'Active' ? 'Suspend' : 'Activate',
          onTap: onStatusToggle,
        ),
        const SizedBox(width: 6),
        _SmallBtn(
            icon: Icons.delete_rounded,
            color: AppColors.error,
            bg: AppColors.errorLight,
            label: 'Delete',
            onTap: onDelete),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

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
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final VoidCallback onTap;

  const _SmallBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
