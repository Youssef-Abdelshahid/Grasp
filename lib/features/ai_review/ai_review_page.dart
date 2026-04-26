import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AiReviewPage extends StatefulWidget {
  const AiReviewPage({super.key});

  @override
  State<AiReviewPage> createState() => _AiReviewPageState();
}

class _AiReviewPageState extends State<AiReviewPage> {
  int _selectedFilter = 0;

  static const _filters = [
    'All',
    'Summaries',
    'Flashcards',
    'Quizzes',
    'Assignments',
  ];

  static final _items = [
    _AiItem(
      type: 'Summary',
      title: 'Chapter 5 Summary',
      material: 'Lecture 5 - Mobile Development',
      course: 'CS401',
      time: '2h ago',
      status: 'Pending',
      icon: Icons.summarize_rounded,
      color: AppColors.cyan,
      bg: AppColors.cyanLight,
    ),
    _AiItem(
      type: 'Quiz',
      title: 'OOP Concepts Quiz · 10 questions',
      material: 'Lecture 3 - Core Concepts',
      course: 'CS310',
      time: '4h ago',
      status: 'Pending',
      icon: Icons.quiz_rounded,
      color: AppColors.violet,
      bg: AppColors.violetLight,
    ),
    _AiItem(
      type: 'Flashcards',
      title: 'Database Terms · 24 Cards',
      material: 'Lecture 2 - DB Fundamentals',
      course: 'CS302',
      time: 'Yesterday',
      status: 'Pending',
      icon: Icons.style_rounded,
      color: AppColors.amber,
      bg: AppColors.amberLight,
    ),
    _AiItem(
      type: 'Assignment',
      title: 'Implementation Exercise',
      material: 'Lecture 4 - Advanced Topics',
      course: 'CS401',
      time: '2 days ago',
      status: 'Accepted',
      icon: Icons.assignment_rounded,
      color: AppColors.emerald,
      bg: AppColors.emeraldLight,
    ),
    _AiItem(
      type: 'Summary',
      title: 'Week 3 Lecture Notes',
      material: 'Lecture 3 - Networks',
      course: 'CS315',
      time: '3 days ago',
      status: 'Published',
      icon: Icons.summarize_rounded,
      color: AppColors.cyan,
      bg: AppColors.cyanLight,
    ),
    _AiItem(
      type: 'Quiz',
      title: 'Chapter Review Quiz · 15 questions',
      material: 'Lecture 6 - Advanced Topics',
      course: 'CS411',
      time: '3 days ago',
      status: 'Rejected',
      icon: Icons.quiz_rounded,
      color: AppColors.violet,
      bg: AppColors.violetLight,
    ),
    _AiItem(
      type: 'Flashcards',
      title: 'Mobile Patterns · 18 Cards',
      material: 'Lecture 1 - Introduction',
      course: 'CS401',
      time: '4 days ago',
      status: 'Published',
      icon: Icons.style_rounded,
      color: AppColors.amber,
      bg: AppColors.amberLight,
    ),
  ];

  List<_AiItem> get _filtered {
    if (_selectedFilter == 0) return _items;
    final filterType = _filters[_selectedFilter];
    return _items.where((item) => item.type == filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 16),
          if (_filtered.isEmpty)
            _buildEmptyState()
          else
            ..._filtered.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AiItemCard(item: item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Review', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(
                'Review and publish AI-generated content before it goes live',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.auto_awesome_rounded, size: 14),
          label: const Text('Generate New'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final pending = _items.where((i) => i.status == 'Pending').length;
    final published = _items.where((i) => i.status == 'Published').length;
    final total = _items.length;

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Pending Review',
            value: '$pending',
            color: AppColors.amber,
            bg: AppColors.amberLight,
            icon: Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Published',
            value: '$published',
            color: AppColors.emerald,
            bg: AppColors.emeraldLight,
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Total Generated',
            value: '$total',
            color: AppColors.primary,
            bg: AppColors.primaryLight,
            icon: Icons.auto_awesome_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (i) {
          final isSelected = _selectedFilter == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  _filters[i],
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text('No generated content', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Upload course materials and use AI Generate to create content',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiItem {
  final String type;
  final String title;
  final String material;
  final String course;
  final String time;
  final String status;
  final IconData icon;
  final Color color;
  final Color bg;

  const _AiItem({
    required this.type,
    required this.title,
    required this.material,
    required this.course,
    required this.time,
    required this.status,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _AiItemCard extends StatefulWidget {
  final _AiItem item;

  const _AiItemCard({required this.item});

  @override
  State<_AiItemCard> createState() => _AiItemCardState();
}

class _AiItemCardState extends State<_AiItemCard> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status;
  }

  Color get _statusColor {
    switch (_status) {
      case 'Published':
        return AppColors.emerald;
      case 'Accepted':
        return AppColors.primary;
      case 'Rejected':
        return AppColors.error;
      default:
        return AppColors.amber;
    }
  }

  Color get _statusBg {
    switch (_status) {
      case 'Published':
        return AppColors.emeraldLight;
      case 'Accepted':
        return AppColors.primaryLight;
      case 'Rejected':
        return AppColors.errorLight;
      default:
        return AppColors.amberLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.material,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Badge(
                          label: item.type,
                          color: item.color,
                          bg: item.bg,
                        ),
                        _Badge(
                          label: item.course,
                          color: AppColors.textSecondary,
                          bg: AppColors.background,
                        ),
                        _Badge(
                          label: _status,
                          color: _statusColor,
                          bg: _statusBg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.time, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 500;

        final utilRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionBtn(
              icon: Icons.preview_rounded,
              label: 'Preview',
              color: AppColors.primary,
              bg: AppColors.primaryLight,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.edit_rounded,
              label: 'Edit',
              color: AppColors.textSecondary,
              bg: AppColors.background,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _ActionBtn(
              icon: Icons.refresh_rounded,
              label: 'Regenerate',
              color: AppColors.violet,
              bg: AppColors.violetLight,
              onTap: () {},
            ),
          ],
        );

        final decisionRow = Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.check_rounded,
                label: 'Accept',
                color: AppColors.emerald,
                bg: AppColors.emeraldLight,
                onTap: () => setState(() => _status = 'Accepted'),
                fill: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                icon: Icons.close_rounded,
                label: 'Reject',
                color: AppColors.error,
                bg: AppColors.errorLight,
                onTap: () => setState(() => _status = 'Rejected'),
                fill: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                icon: Icons.publish_rounded,
                label: 'Publish',
                color: Colors.white,
                bg: AppColors.primary,
                onTap: () => setState(() => _status = 'Published'),
                fill: true,
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [utilRow, const SizedBox(height: 8), decisionRow],
          );
        }

        return Row(
          children: [
            utilRow,
            const Spacer(),
            Expanded(child: decisionRow),
          ],
        );
      },
    );
  }
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final bool fill;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: fill ? 8 : 10, vertical: 7),
          child: Row(
            mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.buttonSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
