import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/core/utils/format_utils.dart';
import 'package:tutora/features/tutor/data/models/tutor_dispute_models.dart';
import 'package:tutora/features/tutor/presentation/providers/tutor_dispute_provider.dart';
import 'package:tutora/features/tutor/presentation/screens/tutor_disputes/tutor_dispute_detail_screen.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

/// Bộ lọc trạng thái trên đầu màn khiếu nại.
enum _DisputeTab {
  all(null, 'Tất cả'),
  pending(DisputeStatus.pending, 'Chờ xử lý'),
  investigating(DisputeStatus.investigating, 'Đang điều tra'),
  confirmedNoShow(DisputeStatus.confirmedNoShow, 'Xác nhận vắng'),
  resolved(DisputeStatus.resolved, 'Đã giải quyết'),
  closed(DisputeStatus.closed, 'Đã đóng')
  ;

  const _DisputeTab(this.status, this.label);

  /// null = không lọc (tab "Tất cả").
  final DisputeStatus? status;
  final String label;

  bool matches(TutorDisputeDto d) => status == null || d.status == status;
}

/// Khiếu nại của gia sư — lọc theo trạng thái như trang đơn hàng.
class TutorDisputesScreen extends ConsumerStatefulWidget {
  const TutorDisputesScreen({super.key});

  @override
  ConsumerState<TutorDisputesScreen> createState() =>
      _TutorDisputesScreenState();
}

class _TutorDisputesScreenState extends ConsumerState<TutorDisputesScreen> {
  _DisputeTab _tab = _DisputeTab.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tutorDisputesProvider);
    final all = async.valueOrNull ?? const <TutorDisputeDto>[];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TutorChildHeader(title: 'Khiếu nại'),
            if (all.isNotEmpty)
              _StatusTabs(
                current: _tab,
                counts: {
                  for (final t in _DisputeTab.values)
                    t: all.where(t.matches).length,
                },
                onChange: (t) => setState(() => _tab = t),
              ),
            Expanded(
              child: async.when(
                loading: () => const _DisputeListSkeleton(),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(tutorDisputesProvider),
                ),
                data: (disputes) => _DisputeList(
                  disputes: disputes.where(_tab.matches).toList(),
                  isFiltered: _tab != _DisputeTab.all,
                  ref: ref,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dải tab trạng thái cuộn ngang, mỗi tab kèm số lượng.
class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.current,
    required this.counts,
    required this.onChange,
  });

  final _DisputeTab current;
  final Map<_DisputeTab, int> counts;
  final ValueChanged<_DisputeTab> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            for (final tab in _DisputeTab.values)
              _TabItem(
                label: tab.label,
                count: counts[tab] ?? 0,
                selected: tab == current,
                onTap: () => onChange(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.oxblood : AppColors.ink3;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        // Gạch chân chạy theo tab đang chọn — cùng ngôn ngữ với trang đơn
        // hàng, rẻ hơn viên thuốc nền khi số tab nhiều và dài ngắn khác nhau.
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.oxblood : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TutorType.action(color: color),
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TutorType.caption(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisputeList extends StatelessWidget {
  const _DisputeList({
    required this.disputes,
    required this.isFiltered,
    required this.ref,
  });

  final List<TutorDisputeDto> disputes;

  /// Đang xem một tab trạng thái cụ thể — quyết định câu chữ khi rỗng.
  final bool isFiltered;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (disputes.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 40),
          TutorEmptyState(
            imageAsset: 'assets/icons/no-dispute.png',
            icon: isFiltered
                ? Icons.filter_alt_off_outlined
                : Icons.verified_outlined,
            // Rỗng vì lọc khác hẳn rỗng vì chưa có khiếu nại nào: câu "các
            // buổi dạy đang suôn sẻ" đặt trong tab "Đã đóng" là sai sự thật.
            message: isFiltered
                ? 'Không có khiếu nại nào ở trạng thái này.'
                : 'Chưa có khiếu nại nào.\nCác buổi dạy của bạn đang suôn sẻ.',
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: () async => ref.invalidate(tutorDisputesProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          TutorSurface.gutter,
          14,
          TutorSurface.gutter,
          32,
        ),
        itemCount: disputes.length,
        separatorBuilder: (_, _) => const SizedBox(height: TutorSurface.rowGap),
        itemBuilder: (_, i) => _DisputeCard(dispute: disputes[i]),
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
          // Hạn 48h chỉ có nghĩa với đơn còn chờ gia sư phản hồi
          if (dispute.status == DisputeStatus.pending) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: AppColors.oxblood,
                ),
                const SizedBox(width: 5),
                Text(
                  _deadlineLabel(dispute.createdAt),
                  style: TutorType.caption(color: AppColors.oxblood),
                ),
              ],
            ),
          ],
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

  /// Còn bao lâu trong hạn 48h kể từ lúc nhận khiếu nại.
  static String _deadlineLabel(DateTime? createdAt) {
    if (createdAt == null) return 'Cần phản hồi trong 48 giờ';

    final left = createdAt
        .toLocal()
        .add(const Duration(hours: 48))
        .difference(DateTime.now());
    if (left.isNegative) return 'Đã quá hạn phản hồi';
    if (left.inHours >= 1) return 'Còn ${left.inHours} giờ để phản hồi';
    return 'Còn ${left.inMinutes} phút để phản hồi';
  }

  static String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t.toLocal());
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
