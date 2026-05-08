import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

class TutorAvailabilityScreen extends ConsumerStatefulWidget {
  const TutorAvailabilityScreen({super.key});

  @override
  ConsumerState<TutorAvailabilityScreen> createState() =>
      _TutorAvailabilityScreenState();
}

class _TutorAvailabilityScreenState
    extends ConsumerState<TutorAvailabilityScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  // Selected day for slot override (null = default/recurring)
  int? _selDay;

  // Pending changes: slot label → on/off  (not yet saved)
  // We derive available days from the provider slots.
  // For toggling a day: tap → call addSlot / deleteSlot for all slots on that day.

  static const _wd = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _allSlots = [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];
  static const _mn = [
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

  int get _days => DateTime(_year, _month + 1, 0).day;
  int get _offset => DateTime(_year, _month).weekday - 1;

  // Derive available days from provider (recurring slots cover all days)
  Set<int> _availDaysFromSlots(List<TutorAvailabilityDto> slots) {
    // A day is "available" if it has a specific-date slot OR if there's a
    // recurring slot for that weekday.
    final result = <int>{};
    for (var d = 1; d <= _days; d++) {
      final date = DateTime(_year, _month, d);
      final wd = date.weekday; // 1=Mon … 7=Sun
      for (final s in slots) {
        if (s.isRecurring && s.dayOfWeek == wd) {
          result.add(d);
          break;
        }
        if (!s.isRecurring && s.specificDate != null) {
          final sd = DateTime.tryParse(s.specificDate!);
          if (sd != null &&
              sd.year == _year &&
              sd.month == _month &&
              sd.day == d) {
            result.add(d);
            break;
          }
        }
      }
    }
    return result;
  }

  // Active slots for selected day (or recurring defaults)
  Set<String> _activeSlotsFor(List<TutorAvailabilityDto> slots) {
    final day = _selDay;
    if (day == null) {
      // Show recurring slots (all)
      return slots.where((s) => s.isRecurring).map((s) => s.startTime).toSet();
    }
    final date = DateTime(_year, _month, day);
    final wd = date.weekday;
    // specific-date overrides, else fall back to recurring
    final specific = slots
        .where((s) {
          if (s.specificDate == null) return false;
          final sd = DateTime.tryParse(s.specificDate!);
          return sd != null &&
              sd.year == date.year &&
              sd.month == date.month &&
              sd.day == date.day;
        })
        .map((s) => s.startTime)
        .toSet();
    if (specific.isNotEmpty) return specific;
    return slots
        .where((s) => s.isRecurring && s.dayOfWeek == wd)
        .map((s) => s.startTime)
        .toSet();
  }

  Future<void> _toggleSlot(
    String slotTime, {
    required bool isActive,
    required List<TutorAvailabilityDto> slots,
    required bool isRecurring,
  }) async {
    final notifier = ref.read(tutorAvailabilityProvider.notifier);

    if (isActive) {
      // Remove matching slot
      final day = _selDay;
      for (final s in slots) {
        if (s.startTime != slotTime) continue;
        if (isRecurring && s.isRecurring) {
          await notifier.removeSlot(s.availabilityId);
          return;
        }
        if (!isRecurring && !s.isRecurring && day != null) {
          final sd = s.specificDate != null
              ? DateTime.tryParse(s.specificDate!)
              : null;
          if (sd != null &&
              sd.year == _year &&
              sd.month == _month &&
              sd.day == day) {
            await notifier.removeSlot(s.availabilityId);
            return;
          }
        }
      }
    } else {
      // Add slot
      final day = _selDay;
      if (isRecurring || day == null) {
        // recurring — use today's weekday or Mon as placeholder
        final wd = day != null
            ? DateTime(_year, _month, day).weekday
            : DateTime.now().weekday;
        await notifier.addSlot(
          CreateAvailabilityRequest(
            dayOfWeek: wd,
            startTime: slotTime,
            endTime: _nextHour(slotTime),
            isRecurring: true,
          ),
        );
      } else {
        final date = DateTime(_year, _month, day);
        await notifier.addSlot(
          CreateAvailabilityRequest(
            dayOfWeek: date.weekday,
            startTime: slotTime,
            endTime: _nextHour(slotTime),
            isRecurring: false,
            specificDate: date.toIso8601String().substring(0, 10),
          ),
        );
      }
    }
  }

  static String _nextHour(String time) {
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    return '${(h + 1).toString().padLeft(2, '0')}:00';
  }

  Future<void> _save(List<TutorAvailabilityDto> slots) async {
    // Nothing queued locally — all toggles are applied immediately.
    // This button just refreshes to confirm.
    await ref.read(tutorAvailabilityProvider.notifier).load();
    if (mounted) AppToast.show(context, message: 'Đã lưu lịch rảnh');
  }

  @override
  Widget build(BuildContext context) {
    final avState = ref.watch(tutorAvailabilityProvider);
    final slots = avState.slots;
    final availDays = _availDaysFromSlots(slots);
    final activeSlots = _activeSlotsFor(slots);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            if (avState.isLoading && slots.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(bottom: bottomPad + 24),
                  children: [
                    _MonthNav(
                      year: _year,
                      month: _month,
                      monthName: _mn[_month],
                      onPrev: () => setState(() {
                        if (_month == 1) {
                          _year--;
                          _month = 12;
                        } else {
                          _month--;
                        }
                        _selDay = null;
                      }),
                      onNext: () => setState(() {
                        if (_month == 12) {
                          _year++;
                          _month = 1;
                        } else {
                          _month++;
                        }
                        _selDay = null;
                      }),
                    ),
                    _CalendarGrid(
                      days: _days,
                      offset: _offset,
                      availDays: availDays,
                      selDay: _selDay,
                      weekdays: _wd,
                      onDayTap: (day, {required isAvail}) =>
                          setState(() => _selDay = day),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
                      child: Row(
                        children: [
                          _LegendDot(
                            color: Color(0xFF2F6B3D),
                            label: 'Ngày rảnh',
                          ),
                          SizedBox(width: 16),
                          _LegendDot(
                            color: AppColors.ink4,
                            label: 'Không rảnh',
                          ),
                        ],
                      ),
                    ),
                    _SlotPicker(
                      selDay: _selDay,
                      month: _month,
                      allSlots: _allSlots,
                      activeSlots: activeSlots,
                      isSaving: avState.isSaving,
                      onToggle: (slot, {required isActive}) async {
                        await _toggleSlot(
                          slot,
                          isActive: isActive,
                          slots: slots,
                          isRecurring: _selDay == null,
                        );
                      },
                    ),
                    _RepeatInfo(selDay: _selDay),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                      child: GestureDetector(
                        onTap: avState.isSaving ? null : () => _save(slots),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: avState.isSaving
                                ? AppColors.ink3
                                : AppColors.ink,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            avState.isSaving ? 'Đang lưu…' : 'Lưu lịch rảnh',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cream,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.ink,
          ),
          Expanded(
            child: Text(
              'Ngày rảnh',
              style: AppTextStyles.h3(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({
    required this.year,
    required this.month,
    required this.monthName,
    required this.onPrev,
    required this.onNext,
  });
  final int year;
  final int month;
  final String monthName;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
          Expanded(
            child: Text(
              '$monthName, $year',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
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

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.offset,
    required this.availDays,
    required this.selDay,
    required this.weekdays,
    required this.onDayTap,
  });
  final int days;
  final int offset;
  final Set<int> availDays;
  final int? selDay;
  final List<String> weekdays;
  final void Function(int day, {required bool isAvail}) onDayTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Row(
              children: weekdays
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
            ...List.generate(
              ((offset + days) / 7).ceil(),
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: List.generate(7, (col) {
                    final idx = row * 7 + col;
                    if (idx < offset || idx - offset + 1 > days) {
                      return const Expanded(child: SizedBox());
                    }
                    final day = idx - offset + 1;
                    final isAvail = availDays.contains(day);
                    final isSel = day == selDay;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onDayTap(day, isAvail: isAvail),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.ink
                                  : isAvail
                                  ? const Color(0xFFD5EDD9)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: isSel
                                        ? AppColors.cream
                                        : AppColors.ink,
                                  ),
                                ),
                                if (isAvail && !isSel)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(top: 1),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF2F6B3D),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 5),
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
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.ink4),
        ),
      ],
    );
  }
}

class _SlotPicker extends StatelessWidget {
  const _SlotPicker({
    required this.selDay,
    required this.month,
    required this.allSlots,
    required this.activeSlots,
    required this.isSaving,
    required this.onToggle,
  });
  final int? selDay;
  final int month;
  final List<String> allSlots;
  final Set<String> activeSlots;
  final bool isSaving;
  final Future<void> Function(String slot, {required bool isActive}) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selDay != null
                ? 'KHUNG GIỜ TRỐNG — NGÀY $selDay/$month'
                : 'KHUNG GIỜ TRỐNG — MẶC ĐỊNH (LẶP LẠI)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: AppColors.ink4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allSlots.map((s) {
              final on = activeSlots.contains(s);
              return GestureDetector(
                onTap: isSaving ? null : () => onToggle(s, isActive: on),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: on ? AppColors.ink : AppColors.cream2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: on ? AppColors.cream : AppColors.ink3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RepeatInfo extends StatelessWidget {
  const _RepeatInfo({required this.selDay});
  final int? selDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.ink3,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selDay == null
                  ? 'Các khung giờ mặc định lặp lại mỗi tuần theo thứ tương ứng.'
                  : 'Chọn khung giờ riêng cho ngày $selDay. Nếu để trống sẽ dùng lịch lặp lại.',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.ink3,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
