import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';

/// Reusable month-grid calendar.
///
/// - [selectedDate]       : currently highlighted day (controlled from parent)
/// - [onSelectDate]       : fires when user taps a day cell
/// - [sessionCountForDay] : (year, month, day) → number of sessions; drives the dots
class AppCalendar extends StatefulWidget {
  const AppCalendar({
    required this.sessionCountForDay,
    required this.onSelectDate,
    super.key,
    this.selectedDate,
  });

  final DateTime? selectedDate;
  final int Function(int year, int month, int day) sessionCountForDay;
  final ValueChanged<DateTime> onSelectDate;

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  late int _year;
  late int _month;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _monthNames = [
    '',
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.selectedDate ?? DateTime.now();
    _year = init.year;
    _month = init.month;
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  // Monday-based offset: Mon=0 … Sun=6  (DateTime.weekday: Mon=1 … Sun=7)
  int get _firstDayOffset => DateTime(_year, _month).weekday - 1;

  void _prevMonth() => setState(() {
    if (_month == 1) {
      _year--;
      _month = 12;
    } else {
      _month--;
    }
  });

  void _nextMonth() => setState(() {
    if (_month == 12) {
      _year++;
      _month = 1;
    } else {
      _month++;
    }
  });

  @override
  Widget build(BuildContext context) {
    final sel = widget.selectedDate;
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          // Month header + navigation
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                Text(
                  '${_monthNames[_month]}, $_year',
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                _NavBtn(icon: Icons.chevron_left_rounded, onTap: _prevMonth),
                const SizedBox(width: 6),
                _NavBtn(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
              ],
            ),
          ),
          // Weekday labels
          Row(
            children: _weekdays
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink3,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          // Day grid
          _buildGrid(sel, today),
        ],
      ),
    );
  }

  Widget _buildGrid(DateTime? sel, DateTime today) {
    final totalCells = _firstDayOffset + _daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(
        rows,
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              if (index < _firstDayOffset ||
                  index - _firstDayOffset + 1 > _daysInMonth) {
                return const Expanded(child: SizedBox());
              }
              final day = index - _firstDayOffset + 1;
              final isSelected =
                  sel != null &&
                  sel.year == _year &&
                  sel.month == _month &&
                  sel.day == day;
              final isToday =
                  today.year == _year &&
                  today.month == _month &&
                  today.day == day;
              final sessionCount = widget.sessionCountForDay(
                _year,
                _month,
                day,
              );

              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      widget.onSelectDate(DateTime(_year, _month, day)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: (isToday || isSelected)
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.cream
                                  : isToday
                                  ? AppColors.oxblood
                                  : AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (sessionCount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                math.min(sessionCount, 3),
                                (_) => Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.gold
                                        : AppColors.oxblood,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 14, color: AppColors.ink),
      ),
    );
  }
}
