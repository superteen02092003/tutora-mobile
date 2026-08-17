import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/constants/app_spacing.dart';
import 'package:tutora/core/constants/app_text_styles.dart';
import 'package:tutora/features/parent/data/models/parent_models.dart';
import 'package:tutora/features/parent/presentation/providers/parent_provider.dart';
import 'package:tutora/features/parent/presentation/widgets/parent_page_header.dart';

class ParentBookingsPage extends ConsumerStatefulWidget {
  const ParentBookingsPage({super.key});

  @override
  ConsumerState<ParentBookingsPage> createState() => _ParentBookingsPageState();
}

class _ParentBookingsPageState extends ConsumerState<ParentBookingsPage> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(
        () => ref
            .read(parentAllBookingsProvider(_selectedStatus).notifier)
            .load(),
      ),
    );
  }

  void _changeFilter(String? status) {
    setState(() => _selectedStatus = status);
    unawaited(
      ref.read(parentAllBookingsProvider(status).notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentAllBookingsProvider(_selectedStatus));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ParentPageHeader(title: 'Lịch đặt của tôi'),
            _StatusFilterBar(
              selected: _selectedStatus,
              onChanged: _changeFilter,
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.ink,
                backgroundColor: AppColors.paper,
                onRefresh: () => ref
                    .read(parentAllBookingsProvider(_selectedStatus).notifier)
                    .load(),
                child: _Body(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final ParentAllBookingsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.bookings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ink),
      );
    }
    if (state.bookings.isEmpty) {
      return const _EmptyState();
    }
    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
      ),
      itemCount: state.bookings.length,
      itemBuilder: (context, i) => _BookingCard(booking: state.bookings[i]),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  static const List<({String label, String? value})> _filters = [
    (label: 'Tất cả', value: null),
    (label: 'Chờ duyệt', value: 'pending_tutor'),
    (label: 'Đã duyệt', value: 'accepted'),
    (label: 'Đang học', value: 'active'),
    (label: 'Hoàn thành', value: 'completed'),
    (label: 'Đã huỷ', value: 'cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: _filters.map((f) {
          final active = selected == f.value;
          return GestureDetector(
            onTap: () => onChanged(f.value),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.paper,
                border: Border.all(
                  color: active ? AppColors.ink : AppColors.line,
                ),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                f.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.gold : AppColors.ink3,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final ParentBookingDto booking;

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}tr đ';
    }
    if (price >= 1000) {
      return '${(price / 1000).round()}.000 đ';
    }
    return '${price.toStringAsFixed(0)} đ';
  }

  @override
  Widget build(BuildContext context) {
    final schedule = booking.schedule ?? [];
    final scheduleStr = schedule.map((s) => s.dayLabel).toSet().join(', ');
    final timeStr = schedule.isNotEmpty
        ? '${schedule.first.startTime} – ${schedule.first.endTime}'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.subjectName ?? 'Môn học',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (booking.studentName != null)
                        Text(
                          'Học sinh: ${booking.studentName}',
                          style: AppTextStyles.bodySmall(),
                        ),
                    ],
                  ),
                ),
                _StatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 10),
            if (booking.tutorName != null)
              _InfoRow(
                icon: Icons.person_outline_rounded,
                text: 'Gia sư: ${booking.tutorName!}',
              ),
            if (scheduleStr.isNotEmpty)
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: '$scheduleStr  $timeStr',
              ),
            if (booking.finalPrice != null)
              _InfoRow(
                icon: Icons.payments_outlined,
                text: _formatPrice(booking.finalPrice!),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.ink4),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Đang học', AppColors.green),
      'accepted' => ('Đã duyệt', const Color(0xFF3D6EEA)),
      'pending_tutor' => ('Chờ duyệt', AppColors.gold),
      'completed' => ('Hoàn thành', AppColors.ink3),
      'cancelled' => ('Đã huỷ', AppColors.oxblood),
      _ => ('Không rõ', AppColors.ink4),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.ink4,
          ),
          const SizedBox(height: 12),
          Text('Chưa có lịch đặt nào.', style: AppTextStyles.bodySmall()),
        ],
      ),
    );
  }
}
