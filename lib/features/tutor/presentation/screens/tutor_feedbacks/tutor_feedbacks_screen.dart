import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/app_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/datasources/tutor_feedback_datasource.dart';
import 'package:tutora/features/tutor/data/models/tutor_feedback_models.dart';
import 'package:tutora/features/tutor/presentation/widgets/tutor_ui.dart';

/// Đánh giá phụ huynh dành cho gia sư.
///
/// Chỉ đọc: trả lời đánh giá hiện chỉ có trên web, nên ở đây không dựng ô nhập
/// để tránh hứa hẹn một hành động mobile chưa làm được.
class TutorFeedbacksScreen extends ConsumerWidget {
  const TutorFeedbacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tutorFeedbacksProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            TutorScreenHeader(
              title: 'Đánh giá',
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
                loading: () => const _FeedbackSkeleton(),
                error: (e, _) => TutorEmptyState(
                  icon: Icons.cloud_off_rounded,
                  message: 'Không tải được đánh giá.\n$e',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(tutorFeedbacksProvider),
                ),
                data: (items) => items.isEmpty
                    ? const TutorEmptyState(
                        icon: Icons.star_outline_rounded,
                        message:
                            'Chưa có đánh giá nào.\n'
                            'Phụ huynh sẽ đánh giá sau khi buổi học hoàn tất.',
                      )
                    : RefreshIndicator(
                        color: AppColors.ink,
                        onRefresh: () async =>
                            ref.invalidate(tutorFeedbacksProvider),
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 32),
                          children: [
                            Padding(
                              padding: TutorSurface.screenPadding,
                              child: _SummaryCard(
                                stats: TutorFeedbackStats.from(items),
                              ),
                            ),
                            const SizedBox(height: TutorSurface.sectionGap),
                            TutorSectionHeader(
                              title: 'Tất cả · ${items.length}',
                            ),
                            Padding(
                              padding: TutorSurface.screenPadding,
                              child: Column(
                                children: [
                                  for (var i = 0; i < items.length; i++) ...[
                                    if (i > 0)
                                      const SizedBox(
                                        height: TutorSurface.rowGap,
                                      ),
                                    _FeedbackCard(feedback: items[i]),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final TutorFeedbackStats stats;

  @override
  Widget build(BuildContext context) {
    return TutorCard(
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.average.toStringAsFixed(1),
                style: TutorType.numeralLarge(),
              ),
              const SizedBox(height: 2),
              _Stars(rating: stats.average.round()),
              const SizedBox(height: 4),
              Text('${stats.total} đánh giá', style: TutorType.caption()),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                for (final star in [5, 4, 3, 2, 1])
                  _RatingBar(
                    star: star,
                    ratio: stats.ratioOf(star),
                    count: stats.starCounts[star] ?? 0,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.star,
    required this.ratio,
    required this.count,
  });

  final int star;
  final double ratio;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            child: Text('$star', style: TutorType.caption()),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: AppColors.cream2,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              style: TutorType.caption(),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final TutorFeedbackDto feedback;

  @override
  Widget build(BuildContext context) {
    return TutorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TutorAvatar(
                name: feedback.parentName,
                imageUrl: feedback.parentAvatarUrl,
                size: 36,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.parentName,
                      style: TutorType.rowTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _Stars(rating: feedback.rating, size: 13),
                        if (feedback.subjectName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              feedback.subjectName,
                              style: TutorType.caption(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (feedback.createdAt != null)
                Text(
                  _relativeTime(feedback.createdAt!),
                  style: TutorType.caption(),
                ),
            ],
          ),

          if (feedback.comment.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              feedback.comment,
              style: TutorType.rowSub(color: AppColors.ink).copyWith(
                height: 1.5,
              ),
            ),
          ],

          if (feedback.hasReply) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cream2,
                borderRadius: BorderRadius.circular(TutorSurface.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn đã trả lời',
                    style: TutorType.caption(
                      color: AppColors.ink3,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feedback.reply!,
                    style: TutorType.rowSub(color: AppColors.ink2).copyWith(
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30} tháng';
    if (diff.inDays >= 1) return '${diff.inDays} ngày';
    if (diff.inHours >= 1) return '${diff.inHours} giờ';
    return 'Vừa xong';
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 15});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= rating ? AppColors.gold : AppColors.ink4,
          ),
      ],
    );
  }
}

class _FeedbackSkeleton extends StatelessWidget {
  const _FeedbackSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: TutorSurface.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TutorSkeleton(height: 110, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.sectionGap),
          TutorSkeleton(height: 15, width: 100),
          SizedBox(height: 12),
          TutorSkeleton(height: 96, radius: TutorSurface.radius),
          SizedBox(height: TutorSurface.rowGap),
          TutorSkeleton(height: 96, radius: TutorSurface.radius),
        ],
      ),
    );
  }
}
