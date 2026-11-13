import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutora/core/constants/tutor_colors.dart';
import 'package:tutora/core/router/app_routes.dart';
import 'package:tutora/core/theme/tutor_design.dart';
import 'package:tutora/features/tutor/data/models/recorder_insights_models.dart';
import 'package:tutora/features/tutor/presentation/providers/recorder_insights_provider.dart';
import 'package:tutora/features/tutor/presentation/widgets/canvas_ui.dart';

/// Số liệu buổi học đo từ bản ghi (phase1-api mục A; board V56-AfterRec /
/// V56-Feedback): nghe rõ hai giọng, học sinh nói bao nhiêu, quãng học sinh ít
/// nói (kèm "Xem mẹo ›"), câu hỏi và thời gian chờ, số phút ghi được.
///
/// Chỉ gia sư thấy. Không vẽ gì khi đang tải, khi lỗi hoặc khi server chưa có
/// số liệu (`available` = false) — màn chứa nó trông y như trước.
class LessonInsightsCard extends ConsumerWidget {
  const LessonInsightsCard({
    required this.lessonId,
    this.kicker,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// lessonId của recorder (= recordingId của bản ghi trong app).
  final String lessonId;

  /// Nhãn nhỏ phía trên thẻ (tuỳ chọn).
  final String? kicker;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(lessonInsightsProvider(lessonId)).valueOrNull;
    if (data == null || !data.available) return const SizedBox.shrink();
    final view = LessonInsightsView(
      insights: data,
      kicker: kicker,
      onTips: () => unawaited(context.push(AppRoutes.tutorRecordingTips)),
    );
    return view.isEmpty
        ? const SizedBox.shrink()
        : Padding(padding: padding, child: view);
  }
}

/// Phần hiển thị (không gọi provider), tách riêng để test và xem trước.
class LessonInsightsView extends StatelessWidget {
  const LessonInsightsView({
    required this.insights,
    this.kicker,
    this.onTips,
    super.key,
  });

  final LessonInsightsDto insights;
  final String? kicker;

  /// Mở "Mẹo ghi âm" từ hàng học sinh ít nói. Null = không có link.
  final VoidCallback? onTips;

  /// 0.31 → "31".
  static String percent(double share) =>
      (share.clamp(0, 1) * 100).round().toString();

  /// 3.4 → "3,4"; 3.0 → "3".
  static String seconds(double s) {
    final r = (s * 10).round() / 10;
    return r == r.roundToDouble()
        ? r.round().toString()
        : r.toStringAsFixed(1).replaceAll('.', ',');
  }

  List<_Insight> get _rows {
    final i = insights;
    final share = i.studentTalkShare;
    final recorded = i.minutesRecorded;
    final planned = i.minutesPlanned;
    final questions = i.tutorQuestions;
    final wait = i.avgWaitAfterQuestionSec;
    return [
      if (i.bothVoices != null)
        _Insight(
          ok: i.bothVoices!,
          text: i.bothVoices!
              ? 'Nghe rõ cả hai giọng'
              : 'Chỉ nghe rõ một giọng',
        ),
      if (share != null)
        _Insight(
          ok: share >= 0.2,
          text: 'Học sinh nói ${percent(share)}% thời gian',
        ),
      for (final q in i.studentQuietStretches)
        _Insight(
          ok: false,
          text: 'Học sinh ít nói phút ${q.fromMin}–${q.toMin}',
          tips: true,
        ),
      if (questions != null)
        _Insight(
          ok: true,
          text: [
            '$questions câu hỏi',
            if (wait != null) 'chờ trung bình ${seconds(wait)} giây',
          ].join(' · '),
        ),
      if (recorded != null)
        _Insight(
          ok: planned == null || planned <= 0 || recorded >= planned * 0.8,
          text: planned != null && planned > 0
              ? 'Ghi được $recorded/$planned phút'
              : 'Ghi được $recorded phút',
        ),
    ];
  }

  bool get isEmpty => _rows.isEmpty;

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kicker != null) ...[
          CanvasKicker(kicker!, color: TutorColors.ink),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          decoration: TutorSurface.card(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var n = 0; n < rows.length; n++)
                  _InsightRow(
                    insight: rows[n],
                    first: n == 0,
                    onTips: onTips,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Đo tự động từ bản ghi âm', style: TutorType.caption()),
      ],
    );
  }
}

class _Insight {
  const _Insight({required this.ok, required this.text, this.tips = false});

  final bool ok;
  final String text;
  final bool tips;
}

/// Hàng có biểu tượng ✓ (ổn) hoặc ! (cần chú ý), như board V56-AfterRec.
class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.insight,
    required this.first,
    required this.onTips,
  });

  final _Insight insight;
  final bool first;
  final VoidCallback? onTips;

  @override
  Widget build(BuildContext context) {
    final showTips = insight.tips && onTips != null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: first ? BorderSide.none : TutorSurface.rule),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Semantics(
              label: insight.ok ? 'Ổn' : 'Cần chú ý',
              child: Icon(
                insight.ok
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                size: 17,
                color: insight.ok ? TutorColors.ink : TutorColors.ink3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.text, style: TutorType.body()),
                if (showTips)
                  InkWell(
                    onTap: onTips,
                    borderRadius: BorderRadius.circular(6),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 32),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1,
                        child: Text(
                          'Xem mẹo ›',
                          style: TutorType.rowSub(color: TutorColors.ink),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
