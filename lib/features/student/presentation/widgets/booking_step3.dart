import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class BookingStep3 extends StatefulWidget {
  const BookingStep3({
    required this.form,
    required this.profile,
    required this.onChanged,
    super.key,
  });

  final BookingForm form;
  final TutorFullProfileDto profile;
  final ValueChanged<BookingForm> onChanged;

  @override
  State<BookingStep3> createState() => _BookingStep3State();
}

class _BookingStep3State extends State<BookingStep3> {
  late BookingForm _form;

  @override
  void initState() {
    super.initState();
    _form = widget.form;
  }

  void _update(BookingForm updated) {
    setState(() => _form = updated);
    widget.onChanged(updated);
  }

  bool _isAvailable(int day, String time) {
    final avail = widget.profile.availabilities;
    if (avail == null || avail.isEmpty) return true;
    final startMins = toMins(time);
    final endMins = startMins + 30;
    return avail.any((a) {
      if (a.dayofweek != day) return false;
      if (a.starttime.isEmpty || a.endtime.isEmpty) return false;
      return startMins >= toMins(a.starttime) && endMins <= toMins(a.endtime);
    });
  }

  bool _isCovered(int day, String time) => _form.schedule.any(
    (s) => s.dayOfWeek == day && timeWithinSlot(time, s.startTime, s.endTime),
  );

  void _toggle(int day, String time) {
    final endTime = addHours(time, _form.slotDurationHours);
    final existingIdx = _form.schedule.indexWhere(
      (s) => s.dayOfWeek == day && timeWithinSlot(time, s.startTime, s.endTime),
    );
    if (existingIdx >= 0) {
      _update(
        _form.copyWith(
          schedule: List.from(_form.schedule)..removeAt(existingIdx),
        ),
      );
      return;
    }
    final avail = widget.profile.availabilities ?? [];
    if (avail.isNotEmpty) {
      final sMins = toMins(time);
      final eMins = toMins(endTime);
      final ok = avail.any((a) {
        if (a.dayofweek != day) return false;
        if (a.starttime.isEmpty || a.endtime.isEmpty) return false;
        return sMins >= toMins(a.starttime) && eMins <= toMins(a.endtime);
      });
      if (!ok) {
        AppToast.show(
          context,
          message:
              'Gia sư không rảnh $time–$endTime vào ${kDayNamesLong[day]}.',
          type: AppToastType.error,
        );
        return;
      }
    }
    _update(
      _form.copyWith(
        schedule: [
          ..._form.schedule,
          ScheduleSlotDto(dayOfWeek: day, startTime: time, endTime: endTime),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookingSectionTitle('Thời lượng mỗi slot'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: kSlotDurationOptions.map((d) {
              final sel = _form.slotDurationHours == d;
              final label = d == d.truncateToDouble()
                  ? '${d.toInt()}h'
                  : '${d}h';
              return GestureDetector(
                onTap: () =>
                    _update(_form.copyWith(slotDurationHours: d, schedule: [])),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.ink : AppColors.paper,
                    border: Border.all(
                      color: sel ? AppColors.ink : AppColors.line,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sel ? AppColors.gold : AppColors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        const BookingSectionTitle('Ngày bắt đầu'),
        const SizedBox(height: 6),
        _DatePicker(
          value: _form.startDate,
          onChanged: (d) => _update(_form.copyWith(startDate: d)),
        ),
        const SizedBox(height: 14),
        const BookingSectionTitle('Chọn lịch tuần'),
        const SizedBox(height: 8),
        _ScheduleGrid(
          schedule: _form.schedule,
          onToggle: _toggle,
          isAvailable: _isAvailable,
          isCovered: _isCovered,
        ),
        if (_form.schedule.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Đã chọn:', style: AppTextStyles.eyebrow()),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _form.schedule
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${kDayNames[s.dayOfWeek]} ${s.startTime}–${s.endTime}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.cream,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _update(
                            _form.copyWith(
                              schedule: _form.schedule
                                  .where(
                                    (x) =>
                                        !(x.dayOfWeek == s.dayOfWeek &&
                                            x.startTime == s.startTime),
                                  )
                                  .toList(),
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: AppColors.cream,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(value) ?? DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy');
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().substring(0, 10));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: AppColors.ink3,
            ),
            const SizedBox(width: 8),
            Text(
              fmt.format(date),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({
    required this.schedule,
    required this.onToggle,
    required this.isAvailable,
    required this.isCovered,
  });

  final List<ScheduleSlotDto> schedule;
  final void Function(int day, String time) onToggle;
  final bool Function(int day, String time) isAvailable;
  final bool Function(int day, String time) isCovered;

  static const List<int> _days = <int>[1, 2, 3, 4, 5, 6, 0];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 44),
              ..._days.map(
                (d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      kDayNames[d],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.line),
          SizedBox(
            height: 260,
            child: SingleChildScrollView(
              child: Column(
                children: kTimeSlots
                    .map(
                      (time) => Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              child: Text(
                                time,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: AppColors.ink3,
                                ),
                              ),
                            ),
                          ),
                          ..._days.map((day) {
                            final avail = isAvailable(day, time);
                            final covered = isCovered(day, time);
                            return Expanded(
                              child: GestureDetector(
                                onTap: avail ? () => onToggle(day, time) : null,
                                child: Container(
                                  height: 28,
                                  margin: const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    color: covered
                                        ? AppColors.ink
                                        : avail
                                        ? AppColors.cream
                                        : AppColors.line.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
