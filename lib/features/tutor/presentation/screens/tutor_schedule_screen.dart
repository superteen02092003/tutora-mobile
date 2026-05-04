import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_booking_detail_screen.dart';
import 'package:tutora/mock/tutor_schedule_mock.dart';
import 'package:tutora/shared/widgets/app_calendar.dart';
import 'package:tutora/shared/widgets/status_chip.dart';

class TutorScheduleScreen extends StatefulWidget {
  const TutorScheduleScreen({super.key});

  @override
  State<TutorScheduleScreen> createState() => _TutorScheduleScreenState();
}

enum _ViewMode { calendar, list }

class _TutorScheduleScreenState extends State<TutorScheduleScreen> {
  _ViewMode _viewMode = _ViewMode.calendar;
  DateTime? _selectedDate;
  TutorBookingStatus? _filterStatus; // null = all

  List<TutorBookingMock> get _dayBookings {
    final d = _selectedDate;
    if (d == null) return [];
    return kTutorBookings
        .where((b) => b.day == d.day && b.month == d.month && b.year == d.year)
        .toList();
  }

  List<TutorBookingMock> get _filteredBookings {
    final f = _filterStatus;
    if (f == null) return kTutorBookings;
    return kTutorBookings.where((b) => b.status == f).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              viewMode: _viewMode,
              onViewChange: (v) => setState(() {
                _viewMode = v;
                _selectedDate = null;
              }),
            ),
            Expanded(
              child: _viewMode == _ViewMode.calendar
                  ? _CalendarView(
                      selectedDate: _selectedDate,
                      onSelectDate: (d) => setState(() => _selectedDate = d),
                      dayBookings: _dayBookings,
                      bottomPad: bottomPad,
                    )
                  : _ListView(
                      filterStatus: _filterStatus,
                      onFilterChange: (s) => setState(() => _filterStatus = s),
                      bookings: _filteredBookings,
                      bottomPad: bottomPad,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Header

class _Header extends StatelessWidget {
  const _Header({required this.viewMode, required this.onViewChange});
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onViewChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Lịch dạy', style: AppTextStyles.h2()),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.cream2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconToggleBtn(
                  active: viewMode == _ViewMode.calendar,
                  onTap: () => onViewChange(_ViewMode.calendar),
                  icon: Icons.calendar_month_outlined,
                ),
                _IconToggleBtn(
                  active: viewMode == _ViewMode.list,
                  onTap: () => onViewChange(_ViewMode.list),
                  icon: Icons.format_list_bulleted_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconToggleBtn extends StatelessWidget {
  const _IconToggleBtn({
    required this.active,
    required this.onTap,
    required this.icon,
  });
  final bool active;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 15,
          color: active ? AppColors.cream : AppColors.ink4,
        ),
      ),
    );
  }
}

// Calendar View

class _CalendarView extends StatelessWidget {
  const _CalendarView({
    required this.selectedDate,
    required this.onSelectDate,
    required this.dayBookings,
    required this.bottomPad,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final List<TutorBookingMock> dayBookings;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(bottom: bottomPad + AppSpacing.xxl),
      children: [
        const SizedBox(height: 12),
        AppCalendar(
          selectedDate: selectedDate,
          sessionCountForDay: (y, m, d) {
            if (y == 2026 && m == 5) {
              return kTutorBookings
                  .where((b) => b.year == y && b.month == m && b.day == d)
                  .length;
            }
            return 0;
          },
          onSelectDate: onSelectDate,
        ),
        if (selectedDate != null && dayBookings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DayStrip(date: selectedDate!, bookings: dayBookings),
        ],
        if (selectedDate != null && dayBookings.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Text(
              'Không có buổi dạy ngày ${selectedDate!.day}/${selectedDate!.month}',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink4),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('BUỔI DẠY THÁNG 5', style: AppTextStyles.eyebrow()),
        ),
        ...kTutorBookings.map(
          (b) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _TeachingCard(
              booking: b,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TutorBookingDetailScreen(booking: b),
                ),
              ),
            ),
          ),
        ),
        const _MonthlySummary(),
      ],
    );
  }
}

// List View

const _kFilters = <(String, TutorBookingStatus?)>[
  ('Tất cả', null),
  ('Chờ', TutorBookingStatus.pending),
  ('Chấp nhận', TutorBookingStatus.accepted),
  ('Đã trả', TutorBookingStatus.paid),
  ('Đã huỷ', TutorBookingStatus.cancelled),
];

class _ListView extends StatelessWidget {
  const _ListView({
    required this.filterStatus,
    required this.onFilterChange,
    required this.bookings,
    required this.bottomPad,
  });

  final TutorBookingStatus? filterStatus;
  final ValueChanged<TutorBookingStatus?> onFilterChange;
  final List<TutorBookingMock> bookings;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: _kFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final (label, status) = _kFilters[i];
              final active = filterStatus == status;
              return GestureDetector(
                onTap: () => onFilterChange(status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ink : AppColors.cream2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? AppColors.cream : AppColors.ink3,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: bookings.isEmpty
              ? Center(
                  child: Text(
                    'Không có buổi dạy nào',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink4,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    bottomPad + AppSpacing.xxl,
                  ),
                  children: [
                    ...bookings.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TeachingCard(
                          booking: b,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  TutorBookingDetailScreen(booking: b),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const _MonthlySummary(),
                  ],
                ),
        ),
      ],
    );
  }
}

// Shared widgets

(String, ChipTone) _bookingChip(TutorBookingStatus s) => switch (s) {
  TutorBookingStatus.pending => ('Chờ xác nhận', ChipTone.gold),
  TutorBookingStatus.accepted => ('Đã chấp nhận', ChipTone.moss),
  TutorBookingStatus.paid => ('Đã thanh toán', ChipTone.ink),
  TutorBookingStatus.cancelled => ('Đã huỷ', ChipTone.ox),
};

Color _bookingBarColor(TutorBookingStatus s) => switch (s) {
  TutorBookingStatus.pending => const Color(0xFF7A5900),
  TutorBookingStatus.accepted => AppColors.moss,
  TutorBookingStatus.paid => const Color(0xFF0D3F6B),
  TutorBookingStatus.cancelled => AppColors.oxblood,
};

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.date, required this.bookings});
  final DateTime date;
  final List<TutorBookingMock> bookings;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            '${date.day} THÁNG ${date.month}',
            style: AppTextStyles.eyebrow(),
          ),
          const SizedBox(height: 10),
          ...bookings.map((b) {
            final (label, tone) = _bookingChip(b.status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _bookingBarColor(b.status),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.subject,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${b.timeStart}–${b.timeEnd} · ${b.studentName}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.ink4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(label: label, tone: tone),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TeachingCard extends StatelessWidget {
  const _TeachingCard({required this.booking, this.onTap});
  final TutorBookingMock booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = _bookingChip(booking.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${booking.day}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Thg${booking.month}',
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      color: AppColors.ink4,
                      letterSpacing: 0.04,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.studentName,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${booking.subject} · ${booking.timeStart}–${booking.timeEnd}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.ink4,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(label: label, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: RadialGradient(
                  center: const Alignment(1.1, -1.1),
                  radius: 1.2,
                  colors: [
                    AppColors.gold.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TỔNG KẾT THÁNG 5',
                style: AppTextStyles.eyebrow(color: AppColors.gold),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _StatItem(value: '5', label: 'Số buổi'),
                  ),
                  Expanded(
                    child: _StatItem(value: '10h', label: 'Tổng giờ'),
                  ),
                ],
              ),
              const Row(
                children: [
                  Expanded(
                    child: _StatItem(value: '1.2M ₫', label: 'Doanh thu'),
                  ),
                  Expanded(
                    child: _StatItem(value: '4', label: 'Học sinh'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.gold,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.cream.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
