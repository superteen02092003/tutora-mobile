import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/tutor_booking_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_booking_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/booking_request_card.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

/// Yêu cầu đặt lịch — việc chờ quyết định (hạn 24h) xếp trên.
class TutorBookingRequestsScreen extends ConsumerWidget {
  const TutorBookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TutorChildHeader(title: 'Yêu cầu đặt lịch'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Text(
                'Phản hồi trong 24 giờ kể từ khi nhận yêu cầu',
                style: TutorType.rowSub(),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const _BookingListSkeleton(),
                error: (e, _) => TutorEmptyState(
                  icon: Icons.cloud_off_rounded,
                  message: 'Không tải được yêu cầu đặt lịch.\n$e',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(tutorBookingsProvider),
                ),
                data: (page) => _BookingList(page: page),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  const _BookingList({required this.page});

  final TutorBookingPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 40),
          TutorEmptyState(
            icon: Icons.inbox_outlined,
            message:
                'Chưa có yêu cầu đặt lịch nào.\n'
                'Yêu cầu mới từ phụ huynh sẽ hiện ở đây.',
          ),
        ],
      );
    }

    final pending = ref.watch(pendingBookingsProvider);
    final handled = page.items.where((b) => !b.status.needsDecision).toList();

    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: () async => ref.invalidate(tutorBookingsProvider),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (pending.isNotEmpty) ...[
            TutorSectionHeader(title: 'Chờ bạn phản hồi · ${pending.length}'),
            Padding(
              padding: TutorSurface.screenPadding,
              child: Column(
                children: [
                  for (var i = 0; i < pending.length; i++) ...[
                    if (i > 0) const SizedBox(height: TutorSurface.rowGap),
                    BookingRequestCard(booking: pending[i]),
                  ],
                ],
              ),
            ),
          ],
          if (handled.isNotEmpty) ...[
            if (pending.isNotEmpty)
              const SizedBox(height: TutorSurface.sectionGap),
            const TutorSectionHeader(title: 'Đã xử lý'),
            Padding(
              padding: TutorSurface.screenPadding,
              child: Column(
                children: [
                  for (var i = 0; i < handled.length; i++) ...[
                    if (i > 0) const SizedBox(height: TutorSurface.rowGap),
                    BookingRequestCard(booking: handled[i]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingListSkeleton extends StatelessWidget {
  const _BookingListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: TutorSurface.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TutorSkeleton(height: 15, width: 140),
          SizedBox(height: 12),
          TutorSkeleton(height: 190, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.rowGap),
          TutorSkeleton(height: 190, radius: TutorSurface.radius),
        ],
      ),
    );
  }
}
