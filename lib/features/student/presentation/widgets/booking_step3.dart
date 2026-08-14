import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/features/student/data/models/booking_models.dart';
import 'package:tutora/features/student/presentation/widgets/booking_constants.dart';
import 'package:tutora/features/student/presentation/widgets/booking_form.dart';
import 'package:tutora/features/student/presentation/widgets/booking_month_preview.dart';
import 'package:tutora/features/student/presentation/widgets/booking_shared.dart';
import 'package:tutora/features/tutor_search/data/models/tutor_detail_models.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class BookingStep3 extends StatefulWidget {
  const BookingStep3({
    required this.form,
    required this.profile,
    required this.onChanged,
    required this.bookedSlots,
    super.key,
  });

  final BookingForm form;
  final TutorFullProfileDto profile;
  final ValueChanged<BookingForm> onChanged;

  /// Buổi gia sư đã nhận (giờ local) — dùng để chặn chọn trùng.
  final List<({DateTime start, DateTime end})> bookedSlots;

  @override
  State<BookingStep3> createState() => _BookingStep3State();
}

class _BookingStep3State extends State<BookingStep3> {
  late BookingForm _form;
  int? _selectedDay;

  // Days ordered Mon→Sun, index matches DayOfWeek (0=Sun,1=Mon,...6=Sat)
  static const List<int> _dayOrder = [1, 2, 3, 4, 5, 6, 0];

  @override
  void initState() {
    super.initState();
    _form = widget.form;
    // Auto-select the first day that has availability, else first day
    final avail = widget.profile.availabilities;
    if (avail != null && avail.isNotEmpty) {
      _selectedDay = _dayOrder.firstWhere(
        (d) => avail.any((a) => a.dayofweek == d),
        orElse: () => _dayOrder.first,
      );
    } else {
      _selectedDay = _dayOrder.first;
    }
  }

  void _update(BookingForm updated) {
    setState(() => _form = updated);
    widget.onChanged(updated);
  }

  /// Lịch rảnh của gia sư đã quy về giờ local (BE lưu UTC).
  late final List<({int dayOfWeek, String startTime, String endTime})>
  _localAvail = (widget.profile.availabilities ?? [])
      .where((a) => a.starttime.isNotEmpty && a.endtime.isNotEmpty)
      .map(
        (a) => availabilityToLocal(
          isoDayOfWeek: a.dayofweek,
          startUtc: a.starttime,
          endUtc: a.endtime,
        ),
      )
      .toList();

  List<({int dayOfWeek, String startTime, String endTime})> _availForDay(
    int day,
  ) => _localAvail.where((a) => a.dayOfWeek == day).toList();

  // Generate time chips from availability slots on a given day
  List<String> _timeSlotsForDay(int day) {
    final dayAvail = _availForDay(day);
    if (_localAvail.isEmpty) return kTimeSlots;
    if (dayAvail.isEmpty) return const [];

    final slots = <String>[];
    final durMins = (_form.slotDurationHours * 60).round();
    for (final a in dayAvail) {
      var cur = toMins(a.startTime);
      final end = toMins(a.endTime);
      while (cur + durMins <= end) {
        final h = cur ~/ 60;
        final m = cur % 60;
        slots.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
        cur += 30;
      }
    }
    return slots;
  }

  bool _isSelected(int day, String startTime) => _form.schedule.any(
    (s) => s.dayOfWeek == day && s.startTime == startTime,
  );

  /// Khung tuần này có đụng buổi gia sư đã nhận ở BẤT KỲ ngày nào trong cửa sổ
  /// đặt lịch không — booked slot là ngày cụ thể nên phải trải ra rồi so.
  bool _conflictsBooked(int day, String startTime) {
    if (widget.bookedSlots.isEmpty) return false;
    final startDate = DateTime.tryParse(_form.startDate);
    if (startDate == null) return false;

    final durMins = (_form.slotDurationHours * 60).round();
    final sMins = toMins(startTime);

    for (final d in sessionDatesInWindow(start: startDate, weekdays: [day])) {
      final s = d.add(Duration(minutes: sMins));
      final e = s.add(Duration(minutes: durMins));
      final hit = widget.bookedSlots.any(
        (b) => s.isBefore(b.end) && e.isAfter(b.start),
      );
      if (hit) return true;
    }
    return false;
  }

  // Returns true if this slot overlaps with any already-selected slot on the same day
  bool _overlapsSelected(int day, String startTime) {
    final sMins = toMins(startTime);
    final eMins = sMins + (_form.slotDurationHours * 60).round();
    return _form.schedule.any((s) {
      if (s.dayOfWeek != day) return false;
      if (s.startTime == startTime) {
        return false; // same slot = selected, not overlap
      }
      final sStart = toMins(s.startTime);
      final sEnd = toMins(s.endTime);
      return sMins < sEnd && eMins > sStart;
    });
  }

  void _toggle(int day, String startTime) {
    final endTime = addHours(startTime, _form.slotDurationHours);
    final existingIdx = _form.schedule.indexWhere(
      (s) => s.dayOfWeek == day && s.startTime == startTime,
    );

    if (existingIdx >= 0) {
      _update(
        _form.copyWith(
          schedule: List.from(_form.schedule)..removeAt(existingIdx),
        ),
      );
      return;
    }

    if (_overlapsSelected(day, startTime)) {
      AppToast.show(
        context,
        message: 'Slot $startTime–$endTime bị trùng với lịch đã chọn.',
        type: AppToastType.error,
      );
      return;
    }

    if (_conflictsBooked(day, startTime)) {
      AppToast.show(
        context,
        message: 'Gia sư đã có lịch dạy vào khung $startTime–$endTime.',
        type: AppToastType.error,
      );
      return;
    }

    if (_localAvail.isNotEmpty) {
      final sMins = toMins(startTime);
      final eMins = toMins(endTime);
      final ok = _availForDay(day).any(
        (a) => sMins >= toMins(a.startTime) && eMins <= toMins(a.endTime),
      );
      if (!ok) {
        AppToast.show(
          context,
          message:
              'Gia sư không rảnh $startTime–$endTime vào ${kDayNamesLong[day]}.',
          type: AppToastType.error,
        );
        return;
      }
    }

    _update(
      _form.copyWith(
        schedule: [
          ..._form.schedule,
          ScheduleSlotDto(
            dayOfWeek: day,
            startTime: startTime,
            endTime: endTime,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gói cố định đã khoá sẵn lịch: chỉ còn chọn ngày bắt đầu.
    if (_form.bookingMode == BookingMode.package) {
      return _PackageScheduleView(
        form: _form,
        onStartDateChanged: (d) => _update(_form.copyWith(startDate: d)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookingSectionTitle('Ngày bắt đầu'),
        const SizedBox(height: 6),
        _DatePicker(
          value: _form.startDate,
          onChanged: (d) => _update(_form.copyWith(startDate: d)),
        ),
        const SizedBox(height: 20),

        const BookingSectionTitle('Chọn lịch học hàng tuần'),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _dayOrder.map((day) {
              final tutorHasAvail =
                  widget.profile.availabilities == null ||
                  widget.profile.availabilities!.isEmpty ||
                  _availForDay(day).isNotEmpty;
              final selected = _selectedDay == day;
              final hasSchedule = _form.schedule.any((s) => s.dayOfWeek == day);

              return GestureDetector(
                onTap: tutorHasAvail
                    ? () => setState(() => _selectedDay = day)
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.ink
                        : tutorHasAvail
                        ? Colors.white
                        : AppColors.paper,
                    border: Border.all(
                      color: selected
                          ? AppColors.ink
                          : hasSchedule
                          ? AppColors.gold
                          : tutorHasAvail
                          ? AppColors.line
                          : AppColors.line,
                      width: hasSchedule && !selected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kDayNames[day],
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.gold
                              : tutorHasAvail
                              ? AppColors.ink
                              : AppColors.ink3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (hasSchedule)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                          ),
                        )
                      else if (!tutorHasAvail)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.ink3.withValues(alpha: 0.4),
                          ),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const _Legend(color: AppColors.gold, label: 'Đã chọn'),
            const SizedBox(width: 12),
            _Legend(
              color: AppColors.ink3.withValues(alpha: 0.4),
              label: 'Gia sư không rảnh',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Time slots for selected day ────────────────────────────────────────
        if (_selectedDay != null)
          _TimeSlotPanel(
            day: _selectedDay!,
            slots: _timeSlotsForDay(_selectedDay!),
            form: _form,
            isSelected: _isSelected,
            isOverlapping: _overlapsSelected,
            onToggle: _toggle,
            ranges: _availForDay(_selectedDay!),
            isBooked: _conflictsBooked,
            slotDurationHours: _form.slotDurationHours,
            hasAvailability: _availForDay(_selectedDay!).isNotEmpty,
          ),

        // ── Selected summary ──────────────────────────────────────────────────
        if (_form.schedule.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Đã chọn · ${_form.schedule.length} buổi/tuần',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _form.schedule.map((s) {
              return Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${kDayNames[s.dayOfWeek]}  ${s.startTime}–${s.endTime}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        size: 16,
                        color: AppColors.cream,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          BookingMonthPreview(
            startDate: _form.startDate,
            schedule: _form.schedule,
          ),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 14, color: AppColors.ink3),
      ),
    ],
  );
}

class _TimeSlotPanel extends StatelessWidget {
  const _TimeSlotPanel({
    required this.day,
    required this.slots,
    required this.form,
    required this.isSelected,
    required this.isOverlapping,
    required this.onToggle,
    required this.slotDurationHours,
    required this.hasAvailability,
    required this.ranges,
    required this.isBooked,
  });

  final int day;
  final List<String> slots;
  final BookingForm form;
  final bool Function(int, String) isSelected;
  final bool Function(int, String) isOverlapping;
  final bool Function(int, String) isBooked;
  final void Function(int, String) onToggle;
  final double slotDurationHours;
  final bool hasAvailability;

  /// Các khoảng rảnh thật của gia sư trong ngày (đã là giờ local).
  final List<({int dayOfWeek, String startTime, String endTime})> ranges;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Center(
          child: Text(
            'Gia sư không có lịch rảnh vào ${kDayNamesLong[day]}',
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink3),
          ),
        ),
      );
    }

    final durLabel = slotDurationHours == slotDurationHours.truncateToDouble()
        ? '${slotDurationHours.toInt()}h'
        : '${slotDurationHours}h';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Giờ học ${kDayNamesLong[day]}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                durLabel,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink3),
              ),
            ),
          ],
        ),
        if (ranges.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ranges
                .map(
                  (r) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cream2,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      'Rảnh ${r.startTime}–${r.endTime}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink3,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        // Chia sáng/chiều/tối để danh sách giờ dài không thành một khối khó quét.
        ...(() {
          final grouped = groupByDayPart(slots);
          final parts = DayPart.values.where(grouped.containsKey).toList();
          return [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              _DayPartSection(
                part: parts[i],
                starts: grouped[parts[i]]!,
                day: day,
                slotDurationHours: slotDurationHours,
                isSelected: isSelected,
                isOverlapping: isOverlapping,
                isBooked: isBooked,
                onToggle: onToggle,
              ),
            ],
          ];
        })(),
      ],
    );
  }
}

/// Một buổi trong ngày (Sáng/Chiều/Tối) kèm icon và lưới 2 cột giờ bắt đầu.
class _DayPartSection extends StatelessWidget {
  const _DayPartSection({
    required this.part,
    required this.starts,
    required this.day,
    required this.slotDurationHours,
    required this.isSelected,
    required this.isOverlapping,
    required this.isBooked,
    required this.onToggle,
  });

  final DayPart part;
  final List<String> starts;
  final int day;
  final double slotDurationHours;
  final bool Function(int, String) isSelected;
  final bool Function(int, String) isOverlapping;
  final bool Function(int, String) isBooked;
  final void Function(int, String) onToggle;

  // Placeholder — sẽ thay bằng icon ảnh màu do CEO cung cấp.
  IconData get _icon => switch (part) {
    DayPart.morning => Icons.wb_twilight_rounded,
    DayPart.afternoon => Icons.wb_sunny_rounded,
    DayPart.evening => Icons.nightlight_round,
  };

  Color get _iconColor => switch (part) {
    DayPart.morning => const Color(0xFFE9A23B),
    DayPart.afternoon => const Color(0xFFEFB700),
    DayPart.evening => const Color(0xFF5B6BA8),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_icon, size: 20, color: _iconColor),
            const SizedBox(width: 8),
            Text(
              part.label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              part.rangeLabel,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink4),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) {
            const gap = 8.0;
            final w = (c.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: starts.map((start) {
                final sel = isSelected(day, start);
                final booked = !sel && isBooked(day, start);
                final disabled = booked || (!sel && isOverlapping(day, start));
                final end = addHours(start, slotDurationHours);
                return GestureDetector(
                  onTap: disabled ? null : () => onToggle(day, start),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: w,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.ink
                          : booked
                          ? const Color(0xFFFBF1E3)
                          : disabled
                          ? AppColors.paper
                          : Colors.white,
                      border: Border.all(
                        color: sel
                            ? AppColors.ink
                            : booked
                            ? const Color(0xFFE6D2B5)
                            : AppColors.line,
                        width: sel ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (sel) ...[
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 6),
                        ] else if (booked) ...[
                          const Icon(
                            Icons.event_busy_rounded,
                            size: 15,
                            color: Color(0xFF9A6B22),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            booked ? 'Trùng lịch' : '$start – $end',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: sel || booked
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: sel
                                  ? AppColors.gold
                                  : booked
                                  ? const Color(0xFF9A6B22)
                                  : disabled
                                  ? AppColors.ink4
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Lịch của gói cố định — chỉ xem, kèm ô chọn ngày bắt đầu.
class _PackageScheduleView extends StatelessWidget {
  const _PackageScheduleView({
    required this.form,
    required this.onStartDateChanged,
  });

  final BookingForm form;
  final ValueChanged<String> onStartDateChanged;

  @override
  Widget build(BuildContext context) {
    final pkg = form.selectedPackage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookingSectionTitle('Ngày bắt đầu'),
        const SizedBox(height: 6),
        _DatePicker(value: form.startDate, onChanged: onStartDateChanged),
        const SizedBox(height: 24),

        const BookingSectionTitle('Lịch của gói'),
        const SizedBox(height: 4),
        Text(
          pkg?.name?.trim().isNotEmpty ?? false
              ? pkg!.name!.trim()
              : 'Gói cố định',
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.ink3),
        ),
        const SizedBox(height: 12),
        ...form.schedule.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.cream2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      kDayNames[s.dayOfWeek],
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kDayNamesLong[s.dayOfWeek],
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.startTime} – ${s.endTime}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  DayPartX.of(s.startTime) == DayPart.morning
                      ? Icons.wb_twilight_rounded
                      : DayPartX.of(s.startTime) == DayPart.afternoon
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
                  size: 20,
                  color: AppColors.ink4,
                ),
              ],
            ),
          ),
        ),
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
    final today = DateTime.now();
    final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
    final fmt = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: isPast ? today : date,
          firstDate: today,
          lastDate: today.add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String().substring(0, 10));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isPast ? Colors.red.shade50 : Colors.white,
          border: Border.all(
            color: isPast ? Colors.red.shade300 : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: isPast ? Colors.red.shade400 : AppColors.ink3,
            ),
            const SizedBox(width: 8),
            Text(
              fmt.format(date),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isPast ? Colors.red.shade600 : AppColors.ink,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isPast ? Colors.red.shade400 : AppColors.ink3,
            ),
            if (isPast) ...[
              const SizedBox(width: 8),
              Text(
                'Ngày không hợp lệ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.red.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
