import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';

/// Lịch tháng đánh dấu các buổi sẽ học, dựng từ lịch tuần đã chọn.
class BookingMonthPreview extends StatefulWidget {
  const BookingMonthPreview({
    required this.startDate,
    required this.schedule,
    super.key,
  });

  final String startDate;
  final List<ScheduleSlotDto> schedule;

  @override
  State<BookingMonthPreview> createState() => _BookingMonthPreviewState();
}

class _BookingMonthPreviewState extends State<BookingMonthPreview> {
  late DateTime _month;

  DateTime get _start => DateTime.tryParse(widget.startDate) ?? DateTime.now();

  DateTime get _end => bookingWindowEnd(_start);

  @override
  void initState() {
    super.initState();
    _month = DateTime(_start.year, _start.month);
  }

  @override
  void didUpdateWidget(BookingMonthPreview old) {
    super.didUpdateWidget(old);
    if (old.startDate != widget.startDate) {
      _month = DateTime(_start.year, _start.month);
    }
  }

  /// Ngày có buổi học + giờ bắt đầu sớm nhất của ngày đó.
  Map<int, String> _sessionsInMonth() {
    final out = <int, String>{};
    if (widget.schedule.isEmpty) return out;

    final last = DateTime(_month.year, _month.month + 1, 0).day;
    for (var d = 1; d <= last; d++) {
      final date = DateTime(_month.year, _month.month, d);
      if (date.isBefore(DateTime(_start.year, _start.month, _start.day))) {
        continue;
      }
      if (date.isAfter(_end)) continue;

      final dow = date.weekday == DateTime.sunday ? 0 : date.weekday;
      final slots = widget.schedule.where((s) => s.dayOfWeek == dow).toList()
        ..sort((a, b) => toMins(a.startTime).compareTo(toMins(b.startTime)));
      if (slots.isNotEmpty) out[d] = slots.first.startTime;
    }
    return out;
  }

  bool get _canPrev => _month.isAfter(DateTime(_start.year, _start.month));

  bool get _canNext => _month.isBefore(DateTime(_end.year, _end.month));

  @override
  Widget build(BuildContext context) {
    final sessions = _sessionsInMonth();
    final first = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Ô trống đầu tháng: cột 0 là CN.
    final lead = first.weekday == DateTime.sunday ? 0 : first.weekday;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat("'Tháng' M yyyy", 'vi_VN').format(_month),
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _NavButton(
                icon: Icons.chevron_left_rounded,
                enabled: _canPrev,
                onTap: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
              ),
              const SizedBox(width: 6),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                enabled: _canNext,
                onTap: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: kDayNames
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink4,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.82,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: lead + daysInMonth,
            itemBuilder: (context, i) {
              if (i < lead) return const SizedBox.shrink();
              final day = i - lead + 1;
              final time = sessions[day];
              return _DayCell(day: day, time: time);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Ngày có buổi học · ${sessions.length} buổi trong tháng này',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.time});

  final int day;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final has = time != null;
    return Container(
      decoration: BoxDecoration(
        color: has ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: has ? FontWeight.w700 : FontWeight.w400,
              color: has ? AppColors.cream : AppColors.ink2,
            ),
          ),
          if (has) ...[
            const SizedBox(height: 1),
            Text(
              time!,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Icon(
        icon,
        size: 20,
        color: enabled ? AppColors.ink : AppColors.line,
      ),
    ),
  );
}
