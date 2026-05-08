import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/data/models/tutor_lesson_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_lesson_provider.dart';
import 'package:tutora/shared/widgets/app_toast.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const _kDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

// dayOfWeek: 1=Mon … 7=Sun (matches backend)
const _kDayLabels = {
  1: 'Thứ 2',
  2: 'Thứ 3',
  3: 'Thứ 4',
  4: 'Thứ 5',
  5: 'Thứ 6',
  6: 'Thứ 7',
  7: 'Chủ nhật',
};

const _kSlots = [
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

String _nextHour(String t) {
  final h = int.parse(t.split(':')[0]);
  return '${(h + 1).toString().padLeft(2, '0')}:00';
}

// ── State helpers ─────────────────────────────────────────────────────────────

/// Returns set of active slot times for a given weekday (1–7) from backend data.
Set<String> _slotsForDay(List<TutorAvailabilityDto> slots, int dayOfWeek) {
  return slots
      .where((s) => s.dayOfWeek == dayOfWeek)
      .map((s) => s.startTime)
      .toSet();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TutorAvailabilityScreen extends ConsumerStatefulWidget {
  const TutorAvailabilityScreen({super.key});

  @override
  ConsumerState<TutorAvailabilityScreen> createState() =>
      _TutorAvailabilityScreenState();
}

class _TutorAvailabilityScreenState
    extends ConsumerState<TutorAvailabilityScreen> {
  // Selected weekday tab (1=Mon … 7=Sun)
  int _selDay = DateTime.now().weekday;

  // Local draft: pending changes per weekday before saving
  // Map<dayOfWeek, Set<slotTime>>  — null means "not yet overridden"
  final Map<int, Set<String>> _draft = {};

  bool _saving = false;

  // Whether any unsaved changes exist
  bool get _isDirty => _draft.isNotEmpty;

  Set<String> _activeSlots(List<TutorAvailabilityDto> serverSlots) {
    return _draft.containsKey(_selDay)
        ? _draft[_selDay]!
        : _slotsForDay(serverSlots, _selDay);
  }

  void _toggleSlot(String slot, List<TutorAvailabilityDto> serverSlots) {
    setState(() {
      final current = _draft[_selDay] ?? _slotsForDay(serverSlots, _selDay);
      final updated = Set<String>.from(current);
      if (updated.contains(slot)) {
        updated.remove(slot);
      } else {
        updated.add(slot);
      }
      _draft[_selDay] = updated;
    });
  }

  Future<void> _save(List<TutorAvailabilityDto> serverSlots) async {
    if (_saving) return;
    setState(() => _saving = true);

    final notifier = ref.read(tutorAvailabilityProvider.notifier);
    var anyError = false;

    for (final entry in _draft.entries) {
      final dayOfWeek = entry.key;
      final newSlots = entry.value;
      final oldSlots = _slotsForDay(serverSlots, dayOfWeek);

      // Remove slots that were deactivated
      final toRemove = oldSlots.difference(newSlots);
      for (final slot in toRemove) {
        final match = serverSlots.firstWhere(
          (s) => s.dayOfWeek == dayOfWeek && s.startTime == slot,
          orElse: () => const TutorAvailabilityDto(
            availabilityId: -1,
            dayOfWeek: 0,
            startTime: '',
            endTime: '',
          ),
        );
        if (match.availabilityId != -1) {
          final ok = await notifier.removeSlot(match.availabilityId);
          if (!ok) anyError = true;
        }
      }

      // Add slots that were activated
      final toAdd = newSlots.difference(oldSlots);
      for (final slot in toAdd) {
        final ok = await notifier.addSlot(
          CreateAvailabilityRequest(
            dayOfWeek: dayOfWeek,
            startTime: slot,
            endTime: _nextHour(slot),
          ),
        );
        if (!ok) anyError = true;
      }
    }

    if (mounted) {
      setState(() {
        _saving = false;
        _draft.clear();
      });
      AppToast.show(
        context,
        message: anyError
            ? 'Lưu một phần thất bại, thử lại'
            : 'Đã lưu lịch rảnh',
        type: anyError ? AppToastType.error : AppToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avState = ref.watch(tutorAvailabilityProvider);
    final slots = avState.slots;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final activeSlots = _activeSlots(slots);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.line, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                  ),
                  Expanded(
                    child: Text('Khung giờ rảnh', style: AppTextStyles.h3()),
                  ),
                  if (_isDirty)
                    _SaveBtn(
                      saving: _saving,
                      onTap: () => unawaited(_save(slots)),
                    ),
                ],
              ),
            ),

            if (avState.isLoading && slots.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad + 24),
                  children: [
                    const SizedBox(height: 16),

                    // Intro
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Chọn thứ và tick các khung giờ bạn sẵn sàng dạy. Lịch này lặp lại mỗi tuần.',
                        style: AppTextStyles.bodySmall(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Day-of-week selector
                    _DaySelector(
                      selected: _selDay,
                      busyDays: _busyDays(slots),
                      draftDays: _draft.keys.toSet(),
                      onSelect: (d) => setState(() => _selDay = d),
                    ),
                    const SizedBox(height: 20),

                    // Slot grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _SlotGrid(
                        dayLabel: _kDayLabels[_selDay] ?? '',
                        slots: _kSlots,
                        active: activeSlots,
                        isDirty: _draft.containsKey(_selDay),
                        saving: _saving,
                        onToggle: (slot) => _toggleSlot(slot, slots),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Summary strip
                    _WeeklySummary(
                      serverSlots: slots,
                      draft: _draft,
                    ),
                    const SizedBox(height: 20),

                    // Save button (bottom)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _BottomSaveBtn(
                        isDirty: _isDirty,
                        saving: _saving,
                        onTap: () => unawaited(_save(slots)),
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

  Set<int> _busyDays(List<TutorAvailabilityDto> slots) {
    return slots.map((s) => s.dayOfWeek).toSet();
  }
}

// ── Day selector ─────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selected,
    required this.busyDays,
    required this.draftDays,
    required this.onSelect,
  });

  final int selected;
  final Set<int> busyDays;
  final Set<int> draftDays;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = i + 1; // 1=Mon
          final isSel = day == selected;
          final hasSlots = busyDays.contains(day);
          final hasDraft = draftDays.contains(day);
          return GestureDetector(
            onTap: () => onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              decoration: BoxDecoration(
                color: isSel ? AppColors.ink : AppColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasDraft
                      ? AppColors.oxblood
                      : isSel
                      ? Colors.transparent
                      : AppColors.line,
                  width: hasDraft ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _kDays[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSel ? AppColors.cream : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasDraft
                          ? AppColors.oxblood
                          : hasSlots
                          ? AppColors.moss
                          : isSel
                          ? AppColors.cream.withValues(alpha: 0.3)
                          : AppColors.line,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Slot grid ─────────────────────────────────────────────────────────────────

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.dayLabel,
    required this.slots,
    required this.active,
    required this.isDirty,
    required this.saving,
    required this.onToggle,
  });

  final String dayLabel;
  final List<String> slots;
  final Set<String> active;
  final bool isDirty;
  final bool saving;
  final void Function(String slot) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDirty
              ? AppColors.oxblood.withValues(alpha: 0.3)
              : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel.toUpperCase(),
                  style: AppTextStyles.eyebrow(),
                ),
              ),
              if (isDirty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.oxblood.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Chưa lưu',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.oxblood,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            active.isEmpty
                ? 'Chưa có khung giờ nào — bấm để thêm'
                : '${active.length} khung giờ đã chọn',
            style: AppTextStyles.bodySmall(color: AppColors.ink4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((s) {
              final on = active.contains(s);
              return GestureDetector(
                onTap: saving ? null : () => onToggle(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: on ? AppColors.ink : AppColors.cream2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: on ? Colors.transparent : AppColors.line,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (on) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: AppColors.cream,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        s,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: on ? AppColors.cream : AppColors.ink3,
                        ),
                      ),
                    ],
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

// ── Weekly summary ────────────────────────────────────────────────────────────

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({required this.serverSlots, required this.draft});

  final List<TutorAvailabilityDto> serverSlots;
  final Map<int, Set<String>> draft;

  @override
  Widget build(BuildContext context) {
    final hasSomething = List.generate(7, (i) {
      final day = i + 1;
      final slots = draft.containsKey(day)
          ? draft[day]!
          : _slotsForDay(serverSlots, day);
      return slots.isNotEmpty;
    }).any((v) => v);

    if (!hasSomething) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cream2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.ink4,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bạn chưa có khung giờ nào. Chọn thứ và thêm giờ rảnh để phụ huynh có thể đặt lịch.',
                  style: AppTextStyles.bodySmall(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LỊCH RẢNH MỖI TUẦN', style: AppTextStyles.eyebrow()),
            const SizedBox(height: 12),
            ...List.generate(7, (i) {
              final day = i + 1;
              final slots = draft.containsKey(day)
                  ? draft[day]!
                  : _slotsForDay(serverSlots, day);
              if (slots.isEmpty) return const SizedBox.shrink();
              final sorted = slots.toList()..sort();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        _kDayLabels[day] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: draft.containsKey(day)
                              ? AppColors.oxblood
                              : AppColors.ink,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: sorted.map((s) => _SlotTag(time: s)).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SlotTag extends StatelessWidget {
  const _SlotTag({required this.time});
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time,
        style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppColors.ink3),
      ),
    );
  }
}

// ── Save buttons ──────────────────────────────────────────────────────────────

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({required this.saving, required this.onTap});
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: saving ? AppColors.ink3 : AppColors.oxblood,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          saving ? 'Đang lưu…' : 'Lưu',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.cream,
          ),
        ),
      ),
    );
  }
}

class _BottomSaveBtn extends StatelessWidget {
  const _BottomSaveBtn({
    required this.isDirty,
    required this.saving,
    required this.onTap,
  });
  final bool isDirty;
  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDirty ? 1 : 0.35,
      child: GestureDetector(
        onTap: isDirty && !saving ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: saving ? AppColors.ink3 : AppColors.ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            saving
                ? 'Đang lưu…'
                : isDirty
                ? 'Lưu thay đổi'
                : 'Chưa có thay đổi',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
        ),
      ),
    );
  }
}
