import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/tutor/data/models/tutor_dispute_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dispute_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_disputes/tutor_dispute_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

/// Danh sách khiếu nại liên quan tới buổi dạy của gia sư.
///
/// Vào từ Hồ sơ. Việc chưa khép lại xếp lên trên vì có hạn 48h phản hồi;
/// việc đã xong gom xuống dưới.
class TutorDisputesScreen extends ConsumerWidget {
  const TutorDisputesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorDisputesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TutorScreenHeader(
              title: 'Khiếu nại',
              subtitle: 'Phản hồi trong 48 giờ kể từ khi nhận',
              actions: [
                TutorHeaderButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                  tooltip: 'Quay lại',
                ),
              ],
            ),
            Expanded(
              child: async.when(
                loading: () => const _DisputeListSkeleton(),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(tutorDisputesProvider),
                ),
                data: (disputes) => _DisputeList(disputes: disputes, ref: ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputeList extends StatelessWidget {
  const _DisputeList({required this.disputes, required this.ref});

  final List<TutorDisputeDto> disputes;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (disputes.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 40),
          TutorEmptyState(
            icon: Icons.verified_outlined,
            message:
                'Chưa có khiếu nại nào.\nCác buổi dạy của bạn đang suôn sẻ.',
          ),
        ],
      );
    }

    final open = disputes.where((d) => d.status.isOpen).toList();
    final closed = disputes.where((d) => !d.status.isOpen).toList();

    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: () async => ref.invalidate(tutorDisputesProvider),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (open.isNotEmpty) ...[
            TutorSectionHeader(title: 'Cần theo dõi · ${open.length}'),
            Padding(
              padding: TutorSurface.screenPadding,
              child: Column(
                children: [
                  for (var i = 0; i < open.length; i++) ...[
                    if (i > 0) const SizedBox(height: TutorSurface.rowGap),
                    _DisputeCard(dispute: open[i]),
                  ],
                ],
              ),
            ),
          ],
          if (closed.isNotEmpty) ...[
            if (open.isNotEmpty)
              const SizedBox(height: TutorSurface.sectionGap),
            const TutorSectionHeader(title: 'Đã khép lại'),
            Padding(
              padding: TutorSurface.screenPadding,
              child: Column(
                children: [
                  for (var i = 0; i < closed.length; i++) ...[
                    if (i > 0) const SizedBox(height: TutorSurface.rowGap),
                    _DisputeCard(dispute: closed[i]),
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

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({required this.dispute});

  final TutorDisputeDto dispute;

  TutorStatusChip get _statusChip => switch (dispute.status) {
    DisputeStatus.pending => TutorStatusChip.attention(
      dispute.status.label,
      icon: Icons.schedule_rounded,
    ),
    DisputeStatus.investigating => TutorStatusChip.pending(
      dispute.status.label,
    ),
    DisputeStatus.resolved ||
    DisputeStatus.confirmedNoShow => TutorStatusChip.done(dispute.status.label),
    _ => TutorStatusChip.neutral(dispute.status.label),
  };

  @override
  Widget build(BuildContext context) {
    final sessionId = dispute.classSessionId;

    return TutorCard(
      onTap: sessionId == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    TutorDisputeDetailScreen(classSessionId: sessionId),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusChip,
              const SizedBox(width: 6),
              TutorStatusChip.neutral(dispute.type.label),
              const Spacer(),
              if (dispute.createdAt != null)
                Text(
                  _relativeTime(dispute.createdAt!),
                  style: TutorType.caption(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dispute.reason.isEmpty ? 'Không có mô tả' : dispute.reason,
            style: TutorType.rowTitle(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Từ ${dispute.createdByName}',
                  style: TutorType.rowSub(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (dispute.sessionPrice != null)
                Text(
                  fmtVnd(dispute.sessionPrice!.round()),
                  style: TutorType.rowSub(color: AppColors.ink2).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays >= 1) return '${diff.inDays} ngày trước';
    if (diff.inHours >= 1) return '${diff.inHours} giờ trước';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }
}

class _DisputeListSkeleton extends StatelessWidget {
  const _DisputeListSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: TutorSurface.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TutorSkeleton(height: 15, width: 120),
          SizedBox(height: 12),
          TutorSkeleton(height: 108, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.rowGap),
          TutorSkeleton(height: 108, radius: TutorSurface.radius),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return TutorEmptyState(
      icon: Icons.cloud_off_rounded,
      message: 'Không tải được danh sách khiếu nại.\n$message',
      actionLabel: 'Thử lại',
      onAction: onRetry,
    );
  }
}
