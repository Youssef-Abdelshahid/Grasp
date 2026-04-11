import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class StudentCalendarPage extends StatefulWidget {
  const StudentCalendarPage({super.key});

  @override
  State<StudentCalendarPage> createState() => _StudentCalendarPageState();
}

class _StudentCalendarPageState extends State<StudentCalendarPage> {
  int _selectedDay = 7;

  static const _month = 'April 2025';

  static const _events = [
    (day: 7, title: 'Office Hours (Moved)', course: 'Mobile Dev · CS401', type: 'Reminder', color: AppColors.amber),
    (day: 10, title: 'Quiz 2: Core Principles', course: 'Mobile Dev · CS401', type: 'Quiz', color: AppColors.violet),
    (day: 12, title: 'Assignment 2 Due', course: 'Machine Learning · CS310', type: 'Assignment', color: AppColors.emerald),
    (day: 15, title: 'Midterm Review Quiz', course: 'Database Systems · CS302', type: 'Quiz', color: AppColors.violet),
    (day: 18, title: 'Lab Sheet 3 Due', course: 'Computer Networks · CS315', type: 'Assignment', color: AppColors.emerald),
    (day: 22, title: 'Midterm Exam', course: 'Software Engineering · CS411', type: 'Exam', color: AppColors.rose),
    (day: 25, title: 'Assignment 3 Due', course: 'Mobile Dev · CS401', type: 'Assignment', color: AppColors.emerald),
    (day: 30, title: 'Quiz 3: Advanced Topics', course: 'Mobile Dev · CS401', type: 'Quiz', color: AppColors.violet),
  ];

  static const _reminders = [
    (title: 'Quiz 2 in 3 days', desc: 'Study Core Principles slides before the quiz.', color: AppColors.violet, icon: Icons.alarm_rounded),
    (title: 'Assignment 2 due soon', desc: 'Deadline: Apr 12. Upload your implementation.', color: AppColors.emerald, icon: Icons.assignment_rounded),
    (title: 'Office hours Thursday', desc: 'Moved from Wednesday to Thursday at 2PM.', color: AppColors.amber, icon: Icons.campaign_rounded),
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
        Text('Track deadlines, quizzes and exam dates', style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = 30;
    final firstWeekday = 2;

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
              IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => Expanded(
              child: Center(
                child: Text(d, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              ),
            )).toList(),
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
              final isToday = day == 7;
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
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
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
                          fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.7) : eventColor,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (e as dynamic).color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (e as dynamic).color.withValues(alpha: 0.25)),
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
                            Text((e as dynamic).title, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text((e as dynamic).course, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    final upcoming = sorted.where((e) => e.day >= 7).toList();

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
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final e = upcoming[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: e.color),
                      ),
                      Text('Apr', style: AppTextStyles.caption.copyWith(color: e.color)),
                    ],
                  ),
                ),
                title: Text(e.title, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(e.course, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: e.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    e.type,
                    style: AppTextStyles.caption.copyWith(color: e.color, fontWeight: FontWeight.w600),
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
