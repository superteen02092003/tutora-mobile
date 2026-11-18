import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/topi_models.dart';
import 'package:tutora/features/tutor/presentation/providers/topi_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

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

    // Canvas T13: nhãn nhỏ, mỗi gợi ý là một hàng kẻ có bóng đèn, trích dẫn
    // nằm trong ô chìm.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CanvasKicker('Dành cho bạn', color: TutorColors.ink),
        const SizedBox(height: 4),
        Text(
          'Chỉ bạn thấy phần này, phụ huynh không nhận.',
          style: TutorType.rowSub().copyWith(fontSize: 14),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < rows.length; i++)
          CanvasRow(
            lastRule: i == rows.length - 1,
            child: _TipRow(title: rows[i].$1, tip: rows[i].$2),
          ),
      ],
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
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(
          Icons.lightbulb_outline_rounded,
          size: 20,
          color: TutorColors.ink,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: TutorColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tip.text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: TutorColors.ink,
              ),
            ),
            if (tip.quote != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: TutorSurface.well(),
                child: Text(
                  '“${tip.quote}”',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: TutorColors.ink3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
