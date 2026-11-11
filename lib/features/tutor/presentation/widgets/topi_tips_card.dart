import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';

/// T13 "Dành cho bạn": điều gia sư làm tốt, một điều thử lần tới, để học sinh
/// nói nhiều hơn. Chỉ gia sư thấy — không bao giờ vào tin gửi phụ huynh.
///
/// Không vẽ gì khi cờ `tips` tắt, khi đang tải, khi lỗi hoặc khi chưa có gợi
/// ý — màn chứa nó trông y như trước.
class TopiTipsCard extends ConsumerWidget {
  const TopiTipsCard({
    required this.lessonId,
    this.padding = const EdgeInsets.only(top: 20),
    super.key,
  });

  final String lessonId;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(topiFlagsNowProvider).tips) return const SizedBox.shrink();
    final tips = ref.watch(lessonTopiProvider(lessonId)).valueOrNull?.tips;
    if (tips == null || tips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: TopiTipsView(tips: tips),
    );
  }
}

/// Phần hiển thị, tách riêng để dùng lại và xem trước.
class TopiTipsView extends StatelessWidget {
  const TopiTipsView({required this.tips, super.key});

  final TopiTips tips;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, TopiTip)>[
      if (tips.didWell != null) ('Bạn đã làm tốt', tips.didWell!),
      if (tips.tryNext != null) ('Thử ở buổi sau', tips.tryNext!),
      if (tips.talkMore != null) ('Để học sinh nói nhiều hơn', tips.talkMore!),
    ];

    return Container(
      width: double.infinity,
      padding: TutorSurface.cardPadding,
      decoration: TutorSurface.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dành cho bạn', style: TutorType.sectionTitle()),
          const SizedBox(height: 2),
          Text(
            'Chỉ bạn thấy phần này, phụ huynh không nhận.',
            style: TutorType.caption(),
          ),
          for (final (title, tip) in rows) ...[
            const SizedBox(height: 14),
            _TipRow(title: title, tip: tip),
          ],
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.title, required this.tip});

  final String title;
  final TopiTip tip;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: TutorColors.accentBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lightbulb_outline_rounded,
          size: 17,
          color: TutorColors.warning,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TutorType.rowTitle().copyWith(fontSize: 14)),
            const SizedBox(height: 3),
            Text(tip.text, style: TutorType.rowSub(color: TutorColors.ink2)),
            if (tip.quote != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                decoration: TutorSurface.well(),
                child: Text(
                  '“${tip.quote}”',
                  style: TutorType.caption(color: TutorColors.ink3),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
