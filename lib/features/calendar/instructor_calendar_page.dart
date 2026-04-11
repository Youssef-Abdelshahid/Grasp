import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class InstructorCalendarPage extends StatefulWidget {
  const InstructorCalendarPage({super.key});

  @override
  State<InstructorCalendarPage> createState() => _InstructorCalendarPageState();
}

class _InstructorCalendarPageState extends State<InstructorCalendarPage> {
  int _selectedDay = 8;

  static const _month = 'April 2025';

  static const _events = [
    (day: 8, title: 'Quiz 1 Closes', course: 'Mobile Dev · CS401', type: 'Quiz', color: AppColors.violet),
    (day: 10, title: 'Assignment 2 Deadline', course: 'Machine Learning · CS310', type: 'Assignment', color: AppColors.emerald),
    (day: 12, title: 'Office Hours', course: 'Database Systems · CS302', type: 'Event', color: AppColors.cyan),
    (day: 15, title: 'Midterm Exam', course: 'Software Engineering · CS411', type: 'Exam', color: AppColors.rose),
    (day: 18, title: 'Lab Sheet 3 Due', course: 'Computer Networks · CS315', type: 'Assignment', color: AppColors.emerald),
    (day: 20, title: 'AI Content Review', course: 'All Courses', type: 'Reminder', color: AppColors.amber),
    (day: 22, title: 'Quiz 2 Opens', course: 'Mobile Dev · CS401', type: 'Quiz', color: AppColors.violet),
    (day: 25, title: 'Grade Submission', course: 'Database Systems · CS302', type: 'Reminder', color: AppColors.amber),
    (day: 28, title: 'End of Month Report', course: 'Admin', type: 'Event', color: AppColors.cyan),
  ];

  static const _reminders = [
    (title: 'Quiz 1 closes today', desc: 'Grading opens after midnight for CS401.', color: AppColors.violet, icon: Icons.quiz_rounded),
    (title: 'Assignment 2 due Apr 10', desc: '14 of 32 students have submitted so far.', color: AppColors.emerald, icon: Icons.assignment_rounded),
    (title: 'AI content pending review', desc: '3 generated items are waiting for approval.', color: AppColors.amber, icon: Icons.auto_awesome_rounded),
  ];

  List<int> get _daysWithEvents => _events.map((e) => e.day).toSet().toList();

  List<dynamic> get _selectedDayEvents =>
      _events.where((e) => e.day == _selectedDay).toList();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppConstants.mobileBreakpoint;
    final padding = EdgeInsets.all(isWide ? 28 : 16);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildCalendar()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildReminders()),
              ],
            )
          else ...[
            _buildCalendar(),
            const SizedBox(height: 20),
            _buildReminders(),
          ],
          const SizedBox(height: 24),
          _buildUpcomingList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Calendar', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text('Track assignment deadlines, quiz closings and course events',
            style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildCalendar() {
    const daysInMonth = 30;
    const firstWeekday = 2;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(_month, style: AppTextStyles.h3),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: AppTextStyles.caption
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              mainAxisExtent: 42,
            ),
            itemCount: daysInMonth + firstWeekday - 1,
            itemBuilder: (_, i) {
              if (i < firstWeekday - 1) return const SizedBox();
              final day = i - firstWeekday + 2;
              final isToday = day == 8;
              final isSelected = day == _selectedDay;
              final hasEvent = _daysWithEvents.contains(day);
              final eventColor = _events.where((e) => e.day == day).isEmpty
                  ? AppColors.border
                  : _events.firstWhere((e) => e.day == day).color;

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primaryLight
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: AppTextStyles.label.copyWith(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.7)
                                : eventColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_selectedDayEvents.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Text('Apr $_selectedDay Events', style: AppTextStyles.label),
            const SizedBox(height: 8),
            ..._selectedDayEvents.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (e as dynamic).color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: (e as dynamic).color.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: (e as dynamic).color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((e as dynamic).title,
                                style: AppTextStyles.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text((e as dynamic).course,
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (e as dynamic).color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          (e as dynamic).type,
                          style: AppTextStyles.caption.copyWith(
                            color: (e as dynamic).color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reminders', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        ..._reminders.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: r.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: r.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: r.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(r.icon, color: r.color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: AppTextStyles.label),
                        const SizedBox(height: 3),
                        Text(r.desc, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildUpcomingList() {
    final sorted = [..._events]..sort((a, b) => a.day.compareTo(b.day));
    final upcoming = sorted.where((e) => e.day >= 8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Upcoming Events', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcoming.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final e = upcoming[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${e.day}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: e.color),
                      ),
                      Text('Apr',
                          style: AppTextStyles.caption
                              .copyWith(color: e.color)),
                    ],
                  ),
                ),
                title: Text(e.title,
                    style: AppTextStyles.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(e.course,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    e.type,
                    style: AppTextStyles.caption.copyWith(
                        color: e.color, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
